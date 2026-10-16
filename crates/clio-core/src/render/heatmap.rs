//! Model-independent sampling grids and in-memory PNG rendering.

use super::{
  color::{parse_color, ColorScale, PreparedScale},
  encode_png, pixel_count,
};
use crate::{geometry::Plane, require, Error};
use serde::{Deserialize, Serialize};

/// Placement of observation points within the coordinate rectangle.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum Sampling {
  /// Observe at the center of each pixel footprint.
  Centers,
  /// Include both bounds, as in a regular endpoint-inclusive sample grid.
  Endpoints,
}

/// Raster resolution and world-space observation region.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Grid {
  /// Pixel width and height; independent of continuous integration samples.
  pub resolution: [u32; 2],
  /// Local [xmin, xmax, ymin, ymax] coordinates; the top row has the largest y.
  pub bounds: [f64; 4],
  /// Observation plane in world space.
  pub plane: Plane,
  /// Observation-point placement.
  pub sampling: Sampling,
}

impl Default for Grid {
  fn default() -> Self {
    Self {
      resolution: [141, 109],
      bounds: [-2.0, 2.0, -1.5, 1.5],
      plane: Plane::default(),
      sampling: Sampling::Centers,
    }
  }
}

impl Grid {
  /// Validates resolution, finite bounds, and the observation frame.
  pub fn validate(&self) -> Result<usize, Error> {
    let count = pixel_count(self.resolution)?;
    let [xmin, xmax, ymin, ymax] = self.bounds;
    require(
      self.bounds.iter().all(|v| v.is_finite())
        && xmin < xmax
        && ymin < ymax
        && (xmax - xmin).is_finite()
        && (ymax - ymin).is_finite(),
      "bounds must be finite [xmin, xmax, ymin, ymax] with positive spans",
    )?;
    if matches!(self.sampling, Sampling::Endpoints) {
      require(
        self.resolution.iter().all(|&v| v >= 2),
        "endpoint sampling requires at least 2 pixels per axis",
      )?;
    }
    self.plane.validate()?;
    Ok(count)
  }

  /// Returns local coordinates for one pixel, from the top row downward.
  pub fn coordinates(&self, column: u32, row: u32) -> [f64; 2] {
    let t = |i: u32, count: u32| match self.sampling {
      Sampling::Centers => (f64::from(i) + 0.5) / f64::from(count),
      Sampling::Endpoints => f64::from(i) / f64::from(count - 1),
    };
    let [xmin, xmax, ymin, ymax] = self.bounds;
    [
      xmin + t(column, self.resolution[0]) * (xmax - xmin),
      ymax - t(row, self.resolution[1]) * (ymax - ymin),
    ]
  }
}

/// Renders a scalar callback on a validated observation grid.
///
/// # Parameters
/// * `grid`: observation resolution, bounds, and plane.
/// * `color`: reusable scalar-to-color mapping.
/// * `missing`: RGBA pixel used at undefined samples.
/// * `sample`: callback producing a finite scalar or `None` for a singularity.
///
/// # Returns
/// An sRGB RGBA PNG encoded entirely in memory.
///
/// # Errors
/// Rejects invalid grids, non-finite scalar results, callback failures, or encoding errors.
pub fn render(
  grid: &Grid,
  color: &PreparedScale,
  missing: [u8; 4],
  sample: impl FnMut([f64; 3]) -> Result<Option<f64>, Error>,
) -> Result<Vec<u8>, Error> {
  render_with_overlay(grid, color, missing, sample, |_| None)
}

/// Renders a scalar field with optional world-space overlay pixels.
///
/// # Parameters
/// * `grid`: observation resolution, bounds, and plane.
/// * `color`: scalar-to-color mapping.
/// * `missing`: color for undefined field samples.
/// * `sample`: callback evaluating the field outside opaque overlay pixels.
/// * `overlay`: optional straight-alpha RGBA foreground at each position.
///
/// # Returns
/// An in-memory PNG; opaque overlays avoid evaluating covered singularities.
///
/// # Errors
/// Reports invalid grids, non-finite scalar values, callback failures, and encoding errors.
pub fn render_with_overlay(
  grid: &Grid,
  color: &PreparedScale,
  missing: [u8; 4],
  mut sample: impl FnMut([f64; 3]) -> Result<Option<f64>, Error>,
  mut overlay: impl FnMut([f64; 3]) -> Option<[u8; 4]>,
) -> Result<Vec<u8>, Error> {
  let count = grid.validate()?;
  let mut pixels = Vec::with_capacity(count * 4);
  for row in 0..grid.resolution[1] {
    for column in 0..grid.resolution[0] {
      let [x, y] = grid.coordinates(column, row);
      let position = grid.plane.position(x, y);
      let foreground = overlay(position);
      if let Some(pixel) = foreground.filter(|pixel| pixel[3] == 255) {
        pixels.extend_from_slice(&pixel);
        continue;
      }
      let mut pixel = match sample(position)? {
        Some(value) => {
          require(value.is_finite(), "scalar field must remain finite")?;
          color.rgba(color.normalize(value))
        }
        None => missing,
      };
      if let Some(foreground) = foreground {
        pixel = composite(foreground, pixel);
      }
      pixels.extend_from_slice(&pixel);
    }
  }
  encode_png(grid.resolution, &pixels)
}

fn composite(foreground: [u8; 4], background: [u8; 4]) -> [u8; 4] {
  let alpha = f64::from(foreground[3]) / 255.0;
  let behind = f64::from(background[3]) / 255.0 * (1.0 - alpha);
  let combined = alpha + behind;
  if combined == 0.0 {
    return [0; 4];
  }
  let mut result = [0; 4];
  for i in 0..3 {
    result[i] = ((f64::from(foreground[i]) * alpha + f64::from(background[i]) * behind) / combined).round() as u8;
  }
  result[3] = (combined * 255.0).round() as u8;
  result
}

/// Direction of increasing values in a colorbar.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum Orientation {
  /// Minimum on the left, maximum on the right.
  Horizontal,
  /// Minimum at the bottom, maximum at the top.
  Vertical,
}

/// Independent colorbar rendering options.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Colorbar {
  /// Color scale shared with a heatmap.
  pub color: ColorScale,
  /// Pixel width and height.
  pub resolution: [u32; 2],
  /// Direction of increasing values.
  pub orientation: Orientation,
}

/// Renders a colorbar uniformly spaced in the transformed color coordinate.
///
/// # Parameters
/// * `request`: scale, raster dimensions, and orientation; labels belong in Typst.
///
/// # Returns
/// PNG bytes whose colors exactly match the heatmap's scale.
///
/// # Errors
/// Rejects invalid scales, resolutions, or PNG encoding failures.
pub fn render_colorbar(request: &Colorbar) -> Result<Vec<u8>, Error> {
  let count = pixel_count(request.resolution)?;
  let scale = PreparedScale::new(&request.color)?;
  let mut pixels = Vec::with_capacity(count * 4);
  for row in 0..request.resolution[1] {
    for column in 0..request.resolution[0] {
      let (i, n) = match request.orientation {
        Orientation::Horizontal => (column, request.resolution[0]),
        Orientation::Vertical => (request.resolution[1] - 1 - row, request.resolution[1]),
      };
      let t = if n == 1 { 0.5 } else { f64::from(i) / f64::from(n - 1) };
      pixels.extend_from_slice(&scale.rgba(t));
    }
  }
  encode_png(request.resolution, &pixels)
}

pub(crate) fn missing_color(text: &str) -> Result<[u8; 4], Error> {
  parse_color(text)
}

/// Renders a vector gradient sampled in the heatmap's transformed color coordinate.
///
/// # Parameters
/// * `request`: color scale, SVG viewport dimensions, and direction of increasing values.
///
/// # Returns
/// Self-contained SVG bytes; Oklab interpolation is approximated by up to 1024 gradient stops.
///
/// # Errors
/// Rejects invalid color scales, resolutions, or SVG formatting failures.
pub fn render_colorbar_svg(request: &Colorbar) -> Result<Vec<u8>, Error> {
  use super::svg;
  use std::fmt::Write;

  pixel_count(request.resolution)?;
  let scale = PreparedScale::new(&request.color)?;
  let mut document = svg::begin(request.resolution);
  let (direction, count) = match request.orientation {
    Orientation::Horizontal => ("x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"0%\"", request.resolution[0]),
    Orientation::Vertical => ("x1=\"0%\" y1=\"100%\" x2=\"0%\" y2=\"0%\"", request.resolution[1]),
  };
  let stops = count.clamp(2, 1024);
  write!(
    document,
    "<defs><linearGradient id=\"clio-colors\" {direction} color-interpolation=\"sRGB\">"
  )
  .map_err(|_| Error::Numerical("SVG formatting failed"))?;
  for i in 0..stops {
    let t = f64::from(i) / f64::from(stops - 1);
    let color = scale.rgba(if count == 1 { 0.5 } else { t });
    write!(
      document,
      "<stop offset=\"{t}\" stop-color=\"{}\" stop-opacity=\"{}\"/>",
      svg::hex(color),
      f64::from(color[3]) / 255.0
    )
    .map_err(|_| Error::Numerical("SVG formatting failed"))?;
  }
  let [width, height] = request.resolution;
  write!(
    document,
    "</linearGradient></defs><rect width=\"{width}\" height=\"{height}\" fill=\"url(#clio-colors)\"/>"
  )
  .map_err(|_| Error::Numerical("SVG formatting failed"))?;
  Ok(svg::finish(document))
}
