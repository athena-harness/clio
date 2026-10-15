//! Optional vector markers for numerical trace termination, independent of source masks.

use super::{Point, Termination, TracedLine};
use crate::{
  render::{color::parse_color, svg::hex},
  require, Error,
};
use serde::{Deserialize, Serialize};
use std::fmt::Write;

/// Output-pixel styling for weak-field, singularity, stagnation, and step-limit markers.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct EndpointStyle {
  /// Diagnostic marker color, including optional alpha.
  pub color: String,
  /// Positive center-to-corner radius in SVG output pixels.
  pub size: f64,
  /// Positive outline width in output pixels.
  pub thickness: f64,
}

impl EndpointStyle {
  pub(super) fn validate(&self) -> Result<(), Error> {
    require(
      self.size.is_finite() && self.size > 0.0 && self.size <= 32.0,
      "endpoint size must be positive and at most 32 pixels",
    )?;
    require(
      self.thickness.is_finite() && self.thickness > 0.0 && self.thickness <= self.size,
      "endpoint thickness must be positive and no greater than marker size",
    )?;
    parse_color(&self.color)?;
    Ok(())
  }
}

impl Termination {
  pub(super) fn name(self) -> &'static str {
    match self {
      Self::Seed => "seed",
      Self::Source => "source",
      Self::Bounds => "bounds",
      Self::WeakField => "weak-field",
      Self::Singularity => "singularity",
      Self::Stagnation => "stagnation",
      Self::StepLimit => "step-limit",
    }
  }

  fn description(self) -> &'static str {
    match self {
      Self::WeakField => "Field threshold encountered; no exact null certified",
      Self::Singularity => "Singularity encountered during integration",
      Self::Stagnation => "Numerical stagnation; no charge source or exact null certified",
      Self::StepLimit => "Maximum integration step count reached",
      _ => "",
    }
  }
}

pub(super) fn draw(
  svg: &mut String,
  lines: &[TracedLine],
  pixel: &impl Fn(Point) -> Point,
  style: &EndpointStyle,
) -> Result<(), Error> {
  let color = parse_color(&style.color)?;
  let mut shown: Vec<(Point, Termination)> = Vec::new();
  for line in lines {
    let positions = [(line.points.first(), line.start), (line.points.last(), line.end)];
    for (point, reason) in positions {
      let Some(point) = point else { continue };
      if matches!(reason, Termination::Seed | Termination::Source | Termination::Bounds) {
        continue;
      }
      let [x, y] = pixel(*point);
      if shown
        .iter()
        .any(|(p, r)| *r == reason && (p[0] - x).hypot(p[1] - y) < 2.0 * style.size)
      {
        continue;
      }
      shown.push(([x, y], reason));
      let r = style.size;
      write!(
        svg,
        "<g data-termination=\"{}\" fill=\"white\" stroke=\"{}\" stroke-width=\"{}\" opacity=\"{}\"><title>{}</title>",
        reason.name(),
        hex(color),
        style.thickness,
        f64::from(color[3]) / 255.0,
        reason.description()
      )
      .map_err(format_error)?;
      match reason {
        Termination::WeakField => write!(svg, "<circle cx=\"{x}\" cy=\"{y}\" r=\"{r}\"/>"),
        Termination::Stagnation => write!(
          svg,
          "<path d=\"M{x} {}L{} {y}L{x} {}L{} {y}Z\"/>",
          y - r,
          x + r,
          y + r,
          x - r
        ),
        Termination::StepLimit => write!(
          svg,
          "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"{}\"/>",
          x - r,
          y - r,
          2.0 * r,
          2.0 * r
        ),
        Termination::Singularity => write!(
          svg,
          "<path fill=\"none\" d=\"M{} {}L{} {}M{} {}L{} {}\"/>",
          x - r,
          y - r,
          x + r,
          y + r,
          x - r,
          y + r,
          x + r,
          y - r
        ),
        _ => Ok(()),
      }
      .map_err(format_error)?;
      svg.push_str("</g>");
    }
  }
  Ok(())
}

fn format_error(_: std::fmt::Error) -> Error {
  Error::Numerical("SVG endpoint formatting failed")
}
