//! Plane-based electric-field tracing and vector SVG rendering.

use super::{
  heatmap::{self, Quantity},
  overlay::{distance, PreparedOverlay, SourceOverlay},
  ElectricField, FieldOptions, Source,
};
use crate::{
  geometry::{dot, norm},
  render::{
    color::{parse_color, ColorScale, PreparedScale},
    heatmap::Grid,
  },
  require, Error,
};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use std::{f64::consts::TAU, fmt::Write};

type Point = [f64; 2];

/// Seed generation in the observation plane's local coordinates.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "kebab-case", deny_unknown_fields)]
pub enum Seeds {
  /// Explicit local coordinates.
  Points {
    /// Observation-plane coordinates.
    points: Vec<Point>,
  },
  /// Equally spaced points on a local circle.
  Circle {
    /// Local center.
    center: Point,
    /// Positive radius in world-space length units.
    radius: f64,
    /// Number of seeds.
    count: u32,
    /// Initial angle in radians.
    phase: f64,
  },
  /// Equally spaced points including both endpoints.
  Segment {
    /// First local endpoint.
    start: Point,
    /// Last local endpoint.
    end: Point,
    /// Number of seeds, at least two.
    count: u32,
  },
}

/// Branches traced from each seed; rendered arrows always follow the electric field.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum Direction {
  /// Along the field from the seed.
  Forward,
  /// Against the field from the seed, then reverse the rendered path.
  Backward,
  /// Trace both branches and join them at the seed.
  Both,
}

/// Interpretation of the field in the observation plane.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum Mode {
  /// Require the field to remain tangent to the plane within tolerance.
  Planar,
  /// Trace the in-plane projection, which is not a three-dimensional field line.
  Projected,
}

/// Numerical tracing settings independent of raster resolution and line styling.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Tracing {
  /// Fixed RK4 arc-length step in world-space length units.
  pub step: f64,
  /// Maximum steps per branch.
  pub max_steps: u32,
  /// Stop when the in-plane field magnitude is at or below this value.
  pub min_field: f64,
  /// Stop within this distance of actual source geometry; zero disables this check.
  pub source_radius: f64,
  /// Forward, backward, or joined tracing.
  pub direction: Direction,
  /// True planar field lines or projected streamlines.
  pub mode: Mode,
  /// Maximum relative normal component allowed in planar mode.
  pub plane_tolerance: f64,
}

impl Default for Tracing {
  fn default() -> Self {
    Self {
      step: 0.02,
      max_steps: 2000,
      min_field: 1e-8,
      source_radius: 0.08,
      direction: Direction::Both,
      mode: Mode::Planar,
      plane_tolerance: 1e-6,
    }
  }
}

/// SVG stroke and arrow dimensions measured in output pixels.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct LineStyle {
  /// Stroke and arrow color.
  pub color: String,
  /// Positive stroke width in output pixels.
  pub width: f64,
  /// Arrow spacing in output pixels; None disables arrowheads.
  pub arrow_spacing: Option<f64>,
  /// Arrowhead length in output pixels.
  pub arrow_size: f64,
}

/// Background independent of the field-line stroke and source masks.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "kebab-case", deny_unknown_fields)]
pub enum Background {
  /// A solid or transparent fill.
  Solid {
    /// Fill color.
    color: String,
  },
  /// Field-magnitude heatmap using the existing scalar color configuration.
  Heatmap {
    /// Field-magnitude color scale.
    color: ColorScale,
  },
}

/// Electric-field-line request consumed by the native and WASM rendering APIs.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Request {
  /// Sources shared with the heatmap renderer.
  pub sources: Vec<Source>,
  /// Observation plane, bounds, and output dimensions.
  pub grid: Grid,
  /// Coulomb multiplier and regularization.
  pub field: FieldOptions,
  /// One or more seed generators.
  pub seeds: Vec<Seeds>,
  /// Integration and termination settings.
  pub tracing: Tracing,
  /// Vector stroke and arrow styling.
  pub style: LineStyle,
  /// Solid fill or field-magnitude heatmap.
  pub background: Background,
  /// Source masks drawn above field lines.
  pub source_overlay: Option<SourceOverlay>,
}

/// Traces normalized electric-field directions with fixed-step RK4.
///
/// # Parameters
/// * `request`: geometry, seed generators, and numerical tracing settings.
///
/// # Returns
/// Local-coordinate polylines ordered along the electric field, including backward branches.
/// Seed placement controls the displayed line density; it is not an automatic flux measure.
///
/// # Errors
/// Rejects invalid settings, incompatible observation planes, numerical failures,
/// or requests exceeding the source-evaluation and vertex limits.
pub fn trace(request: &Request) -> Result<Vec<Vec<Point>>, Error> {
  let field = ElectricField::new(&request.sources, request.field)?;
  trace_prepared(request, &field)
}

fn trace_prepared(request: &Request, field: &ElectricField) -> Result<Vec<Vec<Point>>, Error> {
  request.grid.validate()?;
  let options = request.tracing;
  require(
    options.step.is_finite() && options.step > 0.0,
    "tracing step must be positive and finite",
  )?;
  require(
    (1..=10_000).contains(&options.max_steps),
    "max-steps must be between 1 and 10000",
  )?;
  require(
    options.min_field.is_finite() && options.min_field >= 0.0,
    "min-field must be nonnegative and finite",
  )?;
  require(
    options.source_radius.is_finite() && options.source_radius >= 0.0,
    "source-radius must be nonnegative and finite",
  )?;
  require(
    options.source_radius == 0.0 || options.step <= options.source_radius,
    "tracing step must not exceed a nonzero source-radius",
  )?;
  require(
    options.plane_tolerance.is_finite() && (0.0..=1.0).contains(&options.plane_tolerance),
    "plane-tolerance must be between 0 and 1",
  )?;
  let seeds = generate_seeds(&request.seeds)?;
  require(
    !seeds.is_empty() && seeds.len() <= 1024,
    "provide between 1 and 1024 seeds",
  )?;
  let branches = if matches!(options.direction, Direction::Both) {
    2
  } else {
    1
  };
  require(
    seeds.len() as u64 * branches * (u64::from(options.max_steps) + 1) <= 4_194_304,
    "request exceeds 4194304 possible trace vertices",
  )?;
  let mut budget = 1_000_000_000_u64;
  let mut lines = Vec::with_capacity(seeds.len());
  for seed in seeds {
    require(
      inside(seed, request.grid.bounds),
      "seeds must be finite and inside observation bounds",
    )?;
    let mut backward = if !matches!(options.direction, Direction::Forward) {
      branch(seed, -1.0, request, field, &mut budget)?
    } else {
      vec![seed]
    };
    backward.reverse();
    if !matches!(options.direction, Direction::Backward) {
      let forward = branch(seed, 1.0, request, field, &mut budget)?;
      backward.extend(forward.into_iter().skip(1));
    }
    lines.push(backward);
  }
  Ok(lines)
}

fn generate_seeds(groups: &[Seeds]) -> Result<Vec<Point>, Error> {
  let mut result = Vec::new();
  require(groups.len() <= 1024, "too many seed groups")?;
  for group in groups {
    match group {
      Seeds::Points { points } => {
        require(result.len() + points.len() <= 1024, "too many explicit seeds")?;
        result.extend_from_slice(points);
      }
      Seeds::Circle {
        center,
        radius,
        count,
        phase,
      } => {
        require(
          (1..=1024).contains(count) && radius.is_finite() && *radius > 0.0 && phase.is_finite(),
          "seed circle requires a positive radius, finite phase, and 1 to 1024 points",
        )?;
        for i in 0..*count {
          let (sin, cos) = (phase + TAU * f64::from(i) / f64::from(*count)).sin_cos();
          result.push([center[0] + radius * cos, center[1] + radius * sin]);
        }
      }
      Seeds::Segment { start, end, count } => {
        require((2..=1024).contains(count), "seed segment requires 2 to 1024 points")?;
        for i in 0..*count {
          let t = f64::from(i) / f64::from(count - 1);
          result.push(std::array::from_fn(|axis| (1.0 - t) * start[axis] + t * end[axis]));
        }
      }
    }
    require(result.len() <= 1024, "total seeds must not exceed 1024")?;
  }
  Ok(result)
}

fn inside(p: Point, bounds: [f64; 4]) -> bool {
  p.iter().all(|v| v.is_finite()) && p[0] >= bounds[0] && p[0] <= bounds[1] && p[1] >= bounds[2] && p[1] <= bounds[3]
}

fn charge_budget(budget: &mut u64, count: usize) -> Result<(), Error> {
  *budget = budget
    .checked_sub(count as u64)
    .ok_or_else(|| Error::Invalid("field-line evaluation budget exceeded".into()))?;
  Ok(())
}

fn near_source(p: Point, request: &Request, budget: &mut u64) -> Result<bool, Error> {
  if request.tracing.source_radius == 0.0 {
    return Ok(false);
  }
  charge_budget(budget, request.sources.len())?;
  let world = request.grid.plane.position(p[0], p[1]);
  Ok(request.sources.iter().any(|source| {
    let charge = match source {
      Source::Point(source) => source.charge,
      Source::Segment(source) => source.density,
      Source::Annulus(source) => source.density,
      Source::PlaneWithHole(source) => source.density,
    };
    charge != 0.0 && distance(source, world) <= request.tracing.source_radius
  }))
}

fn tangent(
  p: Point,
  sign: f64,
  request: &Request,
  field: &ElectricField,
  budget: &mut u64,
) -> Result<Option<Point>, Error> {
  charge_budget(budget, field.evaluation_count())?;
  let plane = request.grid.plane;
  let Some(vector) = field.at(plane.position(p[0], p[1]))? else {
    return Ok(None);
  };
  let full = norm(vector);
  let local = [dot(vector, plane.horizontal), dot(vector, plane.vertical)];
  let length = local[0].hypot(local[1]);
  if !full.is_finite() || !length.is_finite() {
    return Err(Error::Numerical("field-line magnitude overflow"));
  }
  if full > request.tracing.min_field && matches!(request.tracing.mode, Mode::Planar) {
    require(
      dot(vector, plane.normal()).abs() / full <= request.tracing.plane_tolerance,
      "field leaves the observation plane; choose a symmetry plane or explicitly enable projected mode",
    )?;
  }
  if length <= request.tracing.min_field {
    return Ok(None);
  }
  Ok(Some(local.map(|v| sign * v / length)))
}

fn shifted(p: Point, d: Point, scale: f64) -> Point {
  std::array::from_fn(|i| p[i] + d[i] * scale)
}

fn branch(
  seed: Point,
  sign: f64,
  request: &Request,
  field: &ElectricField,
  budget: &mut u64,
) -> Result<Vec<Point>, Error> {
  let mut result = vec![seed];
  let mut p = seed;
  let h = request.tracing.step;
  for _ in 0..request.tracing.max_steps {
    if near_source(p, request, budget)? {
      break;
    }
    let Some(k1) = tangent(p, sign, request, field, budget)? else {
      break;
    };
    let Some(k2) = tangent(shifted(p, k1, h / 2.0), sign, request, field, budget)? else {
      break;
    };
    let Some(k3) = tangent(shifted(p, k2, h / 2.0), sign, request, field, budget)? else {
      break;
    };
    let Some(k4) = tangent(shifted(p, k3, h), sign, request, field, budget)? else {
      break;
    };
    let next = std::array::from_fn(|i| p[i] + h * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) / 6.0);
    require(
      next.iter().all(|v| v.is_finite()),
      "field-line coordinates must remain finite",
    )?;
    if (next[0] - p[0]).hypot(next[1] - p[1]) < h * 1e-6 {
      break;
    }
    if !inside(next, request.grid.bounds) {
      let bounds = request.grid.bounds;
      let mut t = 1.0_f64;
      for i in 0..2 {
        if next[i] < bounds[2 * i] {
          t = t.min((bounds[2 * i] - p[i]) / (next[i] - p[i]));
        }
        if next[i] > bounds[2 * i + 1] {
          t = t.min((bounds[2 * i + 1] - p[i]) / (next[i] - p[i]));
        }
      }
      result.push(std::array::from_fn(|i| p[i] + t * (next[i] - p[i])));
      break;
    }
    // Check the midpoint too, so a short crossing cannot skip a thin charged surface.
    let midpoint = std::array::from_fn(|i| (p[i] + next[i]) / 2.0);
    if near_source(midpoint, request, budget)? {
      result.push(midpoint);
      break;
    }
    result.push(next);
    p = next;
  }
  Ok(result)
}

/// Computes field lines and renders them as self-contained SVG bytes.
///
/// # Parameters
/// * `request`: sources, seed generators, tracing controls, background, and styling.
///
/// # Returns
/// Vector strokes and arrowheads, with optional embedded heatmap and source-mask PNGs.
/// All data is generated in memory; external resources are not referenced.
///
/// # Errors
/// Reports tracing, configuration, numerical, and image encoding errors.
pub fn render(request: &Request) -> Result<Vec<u8>, Error> {
  let count = request.grid.validate()?;
  let style = &request.style;
  require(
    style.width.is_finite() && style.width > 0.0 && style.width <= 64.0,
    "line width must be positive and at most 64 output pixels",
  )?;
  require(
    style.arrow_size.is_finite() && (0.0..=64.0).contains(&style.arrow_size),
    "arrow-size must be between 0 and 64 output pixels",
  )?;
  if let Some(spacing) = style.arrow_spacing {
    require(
      spacing.is_finite() && spacing >= (2.0 * style.arrow_size).max(1.0),
      "arrow-spacing must be finite and at least twice arrow-size or 1 pixel",
    )?;
  }
  let rgba = parse_color(&style.color)?;
  let field = ElectricField::new(&request.sources, request.field)?;
  let overlay = request
    .source_overlay
    .as_ref()
    .map(|o| PreparedOverlay::new(&request.sources, o))
    .transpose()?;
  require(
    overlay.is_none() || (count as u64) * (request.sources.len() as u64) <= 1_000_000_000,
    "source overlay evaluation budget exceeded",
  )?;
  let lines = trace_prepared(request, &field)?;
  let [width, height] = request.grid.resolution;
  let mut svg = format!(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{width}\" height=\"{height}\" viewBox=\"0 0 {width} {height}\">"
  );
  match &request.background {
    Background::Solid { color } => {
      let color = parse_color(color)?;
      write!(
        svg,
        "<rect width=\"100%\" height=\"100%\" fill=\"{}\" fill-opacity=\"{}\"/>",
        hex(color),
        f64::from(color[3]) / 255.0
      )
      .map_err(|_| Error::Numerical("SVG formatting failed"))?;
    }
    Background::Heatmap { color } => {
      let png = heatmap::render(&heatmap::Request {
        sources: request.sources.clone(),
        grid: request.grid.clone(),
        field: request.field,
        quantity: Quantity::Magnitude,
        color: color.clone(),
        singularity_color: "#00000000".into(),
        source_overlay: None,
      })?;
      embed_png(&mut svg, &png, width, height);
    }
  }
  let [xmin, xmax, ymin, ymax] = request.grid.bounds;
  let pixel = |p: Point| {
    [
      (p[0] - xmin) / (xmax - xmin) * f64::from(width),
      (ymax - p[1]) / (ymax - ymin) * f64::from(height),
    ]
  };
  for line in &lines {
    if line.len() < 2 {
      continue;
    }
    let pixels: Vec<_> = line.iter().copied().map(pixel).collect();
    svg.push_str("<path d=\"");
    for (i, p) in pixels.iter().enumerate() {
      write!(svg, "{} {:.5} {:.5} ", if i == 0 { "M" } else { "L" }, p[0], p[1])
        .map_err(|_| Error::Numerical("SVG formatting failed"))?;
    }
    write!(svg,"\" fill=\"none\" stroke=\"{}\" stroke-opacity=\"{}\" stroke-width=\"{}\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>",
      hex(rgba),f64::from(rgba[3])/255.0,style.width).map_err(|_| Error::Numerical("SVG formatting failed"))?;
    draw_arrows(&mut svg, &pixels, style, rgba)?;
  }
  if let Some(overlay) = overlay {
    let clear = PreparedScale::new(&ColorScale {
      stops: vec!["#00000000".into(); 2],
      ..ColorScale::default()
    })?;
    let png = crate::render::heatmap::render_with_overlay(
      &request.grid,
      &clear,
      [0; 4],
      |_| Ok(Some(0.0)),
      |p| overlay.pixel(p),
    )?;
    embed_png(&mut svg, &png, width, height);
  }
  svg.push_str("</svg>");
  Ok(svg.into_bytes())
}

fn hex(color: [u8; 4]) -> String {
  format!("#{:02x}{:02x}{:02x}", color[0], color[1], color[2])
}

fn embed_png(svg: &mut String, png: &[u8], width: u32, height: u32) {
  // Embedded PNG dimensions match the SVG viewport exactly.
  svg.push_str(&format!(
    "<image width=\"{width}\" height=\"{height}\" href=\"data:image/png;base64,{}\"/>",
    STANDARD.encode(png)
  ));
}

fn draw_arrows(svg: &mut String, points: &[Point], style: &LineStyle, color: [u8; 4]) -> Result<(), Error> {
  let Some(spacing) = style.arrow_spacing.filter(|_| style.arrow_size > 0.0) else {
    return Ok(());
  };
  let mut travelled = 0.0;
  let mut target = spacing / 2.0;
  for pair in points.windows(2) {
    let a = pair[0];
    let b = pair[1];
    let length = (b[0] - a[0]).hypot(b[1] - a[1]);
    if length == 0.0 {
      continue;
    }
    let unit = [(b[0] - a[0]) / length, (b[1] - a[1]) / length];
    while target <= travelled + length {
      let t = (target - travelled) / length;
      let tip = shifted(a, unit, t * length);
      let base = shifted(tip, unit, -style.arrow_size);
      let normal = [-unit[1], unit[0]];
      let left = shifted(base, normal, style.arrow_size * 0.45);
      let right = shifted(base, normal, -style.arrow_size * 0.45);
      write!(
        svg,
        "<polygon points=\"{:.5},{:.5} {:.5},{:.5} {:.5},{:.5}\" fill=\"{}\" fill-opacity=\"{}\"/>",
        tip[0],
        tip[1],
        left[0],
        left[1],
        right[0],
        right[1],
        hex(color),
        f64::from(color[3]) / 255.0
      )
      .map_err(|_| Error::Numerical("SVG formatting failed"))?;
      target += spacing;
    }
    travelled += length;
  }
  Ok(())
}
