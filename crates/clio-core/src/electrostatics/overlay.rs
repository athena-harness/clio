//! Geometric source masks configured independently of electric-field evaluation.

use super::Source;
use crate::{
  geometry::{dot, norm, sub, Vector},
  render::color::parse_color,
  require, Error,
};
use serde::{Deserialize, Serialize};

/// Display style for the intersection of a source and the observation slice.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct SourceStyle {
  /// RGBA overlay color in #RRGGBB or #RRGGBBAA notation.
  pub color: String,
  /// Full geometric thickness in world-space length units, not field softening.
  pub thickness: f64,
}

/// An optional style override for one source in the request's source array.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct SourceOverride {
  /// Zero-based source index.
  pub source: usize,
  /// Replacement style, or None to hide this source's overlay.
  pub style: Option<SourceStyle>,
}

/// Source visualization independent of charge values and scalar color mapping.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct SourceOverlay {
  /// Default style applied to every source.
  pub style: SourceStyle,
  /// Per-source replacements; indices must be unique and within the source array.
  pub overrides: Vec<SourceOverride>,
}

struct PreparedStyle {
  color: [u8; 4],
  radius: f64,
}

impl PreparedStyle {
  fn new(style: &SourceStyle) -> Result<Self, Error> {
    require(
      style.thickness.is_finite() && style.thickness > 0.0,
      "source overlay thickness must be positive and finite",
    )?;
    Ok(Self {
      color: parse_color(&style.color)?,
      radius: style.thickness / 2.0,
    })
  }
}

pub(crate) struct PreparedOverlay<'a> {
  sources: &'a [Source],
  styles: Vec<Option<PreparedStyle>>,
}

impl<'a> PreparedOverlay<'a> {
  pub fn new(sources: &'a [Source], overlay: &SourceOverlay) -> Result<Self, Error> {
    let mut selected = vec![Some(&overlay.style); sources.len()];
    let mut assigned = vec![false; sources.len()];
    for replacement in &overlay.overrides {
      require(
        replacement.source < sources.len(),
        "overlay source index is out of bounds",
      )?;
      require(!assigned[replacement.source], "overlay source indices must be unique")?;
      assigned[replacement.source] = true;
      selected[replacement.source] = replacement.style.as_ref();
    }
    let styles = selected
      .into_iter()
      .map(|style| style.map(PreparedStyle::new).transpose())
      .collect::<Result<_, _>>()?;
    Ok(Self { sources, styles })
  }

  pub fn pixel(&self, position: Vector) -> Option<[u8; 4]> {
    // Later sources are drawn on top when their visible masks overlap.
    for (source, style) in self.sources.iter().zip(&self.styles).rev() {
      if let Some(style) = style {
        if style.color[3] > 0 && distance(source, position) <= style.radius {
          return Some(style.color);
        }
      }
    }
    None
  }
}

fn distance(source: &Source, position: Vector) -> f64 {
  match source {
    Source::Point(point) => norm(sub(position, point.position)),
    Source::Segment(segment) => {
      let delta = sub(segment.end, segment.start);
      let length = norm(delta);
      let direction = delta.map(|v| v / length);
      let t = (dot(sub(position, segment.start), direction) / length).clamp(0.0, 1.0);
      let closest = std::array::from_fn(|i| (1.0 - t) * segment.start[i] + t * segment.end[i]);
      norm(sub(position, closest))
    }
    Source::Annulus(surface) => {
      let delta = sub(position, surface.plane.origin);
      let normal = dot(delta, surface.plane.normal()).abs();
      let radial = dot(delta, surface.plane.horizontal).hypot(dot(delta, surface.plane.vertical));
      let gap = (radial - radial.clamp(surface.inner_radius, surface.outer_radius)).abs();
      normal.hypot(gap)
    }
    Source::PlaneWithHole(surface) => {
      let delta = sub(position, surface.plane.origin);
      let normal = dot(delta, surface.plane.normal()).abs();
      let radial = dot(delta, surface.plane.horizontal).hypot(dot(delta, surface.plane.vertical));
      normal.hypot((surface.hole_radius - radial).max(0.0))
    }
  }
}
