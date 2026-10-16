//! Orthographic spatial context, slice heatmaps, and full-vector field lines as SVG.

mod curves;
mod drawing;
mod sources;
mod tracing;

pub use tracing::{SpatialLine, SpatialTracing};

use super::{field_lines::LineStyle, ElectricField, FieldOptions, Source};
use crate::{
  geometry::{dot, finite, norm, sub, Vector},
  render::{
    color::{parse_color, ColorScale},
    heatmap::Grid,
    pixel_count,
  },
  require, Error,
};
use serde::{Deserialize, Serialize};

/// Orthographic camera; angles are radians and span is the visible horizontal length.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Camera {
  /// World-space point at the viewport center.
  pub target: Vector,
  /// Rotation around the world z axis from the positive x direction.
  pub azimuth: f64,
  /// Angle above the xy plane, strictly between the poles.
  pub elevation: f64,
  /// Visible horizontal length in world-space units.
  pub span: f64,
}

/// Observation-plane appearance and optional field-magnitude samples.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Slice {
  /// None gives a pale blue plane; otherwise sample the full field magnitude.
  pub color: Option<ColorScale>,
  /// Alpha multiplier for the plane or color scale.
  pub opacity: f64,
  /// Independent horizontal and vertical tile counts.
  pub samples: [u32; 2],
}

/// World-space seeds and numerical settings independent of the camera.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Lines {
  /// Explicit three-dimensional seed positions inside the tracing box.
  pub seeds: Vec<Vector>,
  /// Full-vector normalized RK4 integration settings.
  pub tracing: SpatialTracing,
  /// Projected stroke and arrow sizes in output pixels.
  pub style: LineStyle,
}

/// Presentation and spatial limits, independent of source integration samples.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Scene {
  /// SVG viewport dimensions.
  pub resolution: [u32; 2],
  /// World-space minimum and maximum corners; clips geometry and tracing.
  pub bounds: [Vector; 2],
  /// Orthographic view, without altering the physical calculation.
  pub camera: Camera,
  /// Colors in source order, cycling when fewer colors than sources are supplied.
  pub source_colors: Vec<String>,
  /// Source edge thickness in output pixels; also used when curve radius is zero.
  pub source_thickness: f64,
  /// Display-only tube radius for line sources in world units; zero uses strokes.
  #[serde(default = "default_curve_radius")]
  pub curve_radius: f64,
  /// Point-charge radius in output pixels.
  pub point_size: f64,
  /// Optional plane or sampled heatmap at the request's observation grid.
  pub slice: Option<Slice>,
  /// Optional genuinely spatial field lines, not projected planar streamlines.
  pub lines: Option<Lines>,
  /// Draw a world-axis orientation key and the observation-plane normal.
  pub axes: bool,
}

/// Spatial SVG request using the same sources and field evaluator as planar diagrams.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Request {
  /// Built-in and custom charge distributions.
  pub sources: Vec<Source>,
  /// Shared observation plane and local rectangle; raster resolution is unused here.
  pub grid: Grid,
  /// Shared physical scaling and regularization.
  pub field: FieldOptions,
  /// Independent camera, geometry styles, slice, and spatial tracing controls.
  pub scene: Scene,
}

struct Projection {
  camera: Camera,
  right: Vector,
  up: Vector,
  toward: Vector,
  scale: f64,
  center: [f64; 2],
}

impl Projection {
  fn new(scene: &Scene) -> Result<Self, Error> {
    let camera = scene.camera;
    require(
      finite(camera.target)
        && camera.azimuth.is_finite()
        && camera.elevation.is_finite()
        && camera.elevation.abs() < std::f64::consts::FRAC_PI_2
        && camera.span.is_finite()
        && camera.span > 0.0,
      "camera requires finite coordinates, positive span, and elevation strictly between -pi/2 and pi/2",
    )?;
    let (sa, ca) = camera.azimuth.sin_cos();
    let (se, ce) = camera.elevation.sin_cos();
    let scale = f64::from(scene.resolution[0]) / camera.span;
    require(scale.is_finite(), "camera scale must remain finite")?;
    Ok(Self {
      camera,
      right: [-sa, ca, 0.0],
      up: [-se * ca, -se * sa, ce],
      toward: [ce * ca, ce * sa, se],
      scale,
      center: scene.resolution.map(|v| f64::from(v) / 2.0),
    })
  }

  fn point(&self, position: Vector) -> Result<Vector, Error> {
    let d = sub(position, self.camera.target);
    let projected = [
      self.center[0] + self.scale * dot(d, self.right),
      self.center[1] - self.scale * dot(d, self.up),
      dot(d, self.toward),
    ];
    require(finite(projected), "projected scene coordinates must remain finite")?;
    Ok(projected)
  }
}

impl Scene {
  fn validate(&self) -> Result<(), Error> {
    pixel_count(self.resolution)?;
    require(
      finite(self.bounds[0])
        && finite(self.bounds[1])
        && (0..3).all(|i| self.bounds[1][i] > self.bounds[0][i] && (self.bounds[1][i] - self.bounds[0][i]).is_finite()),
      "scene bounds must be finite increasing world-space corners",
    )?;
    require(
      !self.source_colors.is_empty() && self.source_colors.len() <= 65_536,
      "provide between 1 and 65536 scene source colors",
    )?;
    for color in &self.source_colors {
      parse_color(color)?;
    }
    require(
      self.source_thickness.is_finite() && self.source_thickness > 0.0 && self.source_thickness <= 32.0,
      "scene source-thickness must be positive and at most 32 output pixels",
    )?;
    let diagonal = norm(sub(self.bounds[1], self.bounds[0]));
    require(
      self.curve_radius.is_finite()
        && self.curve_radius >= 0.0
        && diagonal.is_finite()
        && self.curve_radius <= diagonal / 4.0,
      "scene curve-radius must be nonnegative and at most one quarter of the scene-box diagonal",
    )?;
    require(
      self.point_size.is_finite() && self.point_size > 0.0 && self.point_size <= 32.0,
      "scene point-size must be positive and at most 32 output pixels",
    )?;
    Ok(())
  }
}

fn default_curve_radius() -> f64 {
  0.02
}

/// Integrates field lines in three dimensions and retains each endpoint's stop reason.
///
/// # Parameters
/// * `request`: sources, world bounds, explicit spatial seeds, and tracing controls.
///
/// # Returns
/// World-coordinate paths ordered along the full electric field. A scene with no
/// line configuration returns an empty collection. Camera settings do not affect paths.
///
/// # Errors
/// Rejects invalid settings, out-of-bounds seeds, numerical overflow, and exceeded budgets.
pub fn trace(request: &Request) -> Result<Vec<SpatialLine>, Error> {
  request.scene.validate()?;
  let field = ElectricField::new(&request.sources, request.field)?;
  tracing::prepared(request, &field)
}

/// Renders full source geometry, an optional slice, and spatial field lines in memory.
///
/// # Parameters
/// * `request`: shared physical model and independent spatial presentation settings.
///
/// # Returns
/// Self-contained vector SVG bytes. Small primitives are sorted from back to front;
/// intersecting transparent surfaces use approximate ordering, not exact visibility.
///
/// # Errors
/// Reports invalid configuration, numerical failures, and sampling or primitive budgets.
pub fn render(request: &Request) -> Result<Vec<u8>, Error> {
  request.grid.validate()?;
  request.scene.validate()?;
  let projection = Projection::new(&request.scene)?;
  let field = ElectricField::new(&request.sources, request.field)?;
  let lines = tracing::prepared(request, &field)?;
  drawing::render(request, &field, &projection, &lines)
}

fn inside(position: Vector, bounds: [Vector; 2]) -> bool {
  finite(position) && (0..3).all(|i| position[i] >= bounds[0][i] && position[i] <= bounds[1][i])
}
