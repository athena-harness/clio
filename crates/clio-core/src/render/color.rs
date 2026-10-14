//! Validated scalar transforms and reusable sRGB/Oklab palettes.

use crate::{require, Error};
use palette::{FromColor, Oklab, Srgb};
use serde::{Deserialize, Serialize};

/// A monotone scalar transform; signed transforms also support field components.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "kebab-case", deny_unknown_fields)]
pub enum Transform {
  /// Uniform scaling in the original field units.
  Linear,
  /// sign(v) * ln(1 + abs(v)/reference).
  Log {
    /// Positive reference magnitude in the same unit as the scalar field.
    reference: f64,
  },
  /// asinh(v/reference), including negative component values.
  Asinh {
    /// Positive reference magnitude in the same unit as the scalar field.
    reference: f64,
  },
}

impl Transform {
  fn validate(self) -> Result<(), Error> {
    match self {
      Self::Linear => Ok(()),
      Self::Log { reference } | Self::Asinh { reference } => require(
        reference.is_finite() && reference > 0.0,
        "scale reference must be positive and finite",
      ),
    }
  }

  fn apply(self, value: f64) -> f64 {
    match self {
      Self::Linear => value,
      Self::Log { reference } => {
        let ratio = value.abs() / reference;
        let result = if ratio.is_finite() {
          ratio.ln_1p()
        } else {
          value.abs().ln() - reference.ln()
        };
        value.signum() * result
      }
      Self::Asinh { reference } => {
        let ratio = value / reference;
        if ratio.is_finite() {
          ratio.asinh()
        } else {
          value.signum() * (value.abs().ln() - reference.ln() + std::f64::consts::LN_2)
        }
      }
    }
  }
}

/// Interpolation space used between evenly spaced color stops.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case")]
pub enum ColorSpace {
  /// Perceptual Oklab interpolation with final sRGB gamut clipping.
  Oklab,
  /// Direct interpolation of encoded sRGB channels.
  Srgb,
}

/// Color mapping independent of the source model and sampling resolution.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct ColorScale {
  /// Scalar values mapped to the first and last stops; outside values are clipped.
  pub range: [f64; 2],
  /// Linear or signed nonlinear mapping.
  pub transform: Transform,
  /// At least two #RRGGBB or #RRGGBBAA colors, including transparent stops.
  pub stops: Vec<String>,
  /// Space used to interpolate RGB; alpha is always interpolated linearly.
  pub space: ColorSpace,
}

impl Default for ColorScale {
  fn default() -> Self {
    Self {
      range: [0.0, 10.0],
      transform: Transform::Log { reference: 1.0 },
      stops: ["#163b78", "#3fa7a0", "#f0e65b", "#f6a13a", "#d94732"]
        .map(String::from)
        .to_vec(),
      space: ColorSpace::Oklab,
    }
  }
}

struct Stop {
  rgb: Srgb<f64>,
  lab: Oklab<f64>,
  alpha: f64,
}

/// Validated color mapping with converted stops cached outside the pixel loop.
pub struct PreparedScale {
  range: [f64; 2],
  transformed: [f64; 2],
  transform: Transform,
  space: ColorSpace,
  stops: Vec<Stop>,
}

impl PreparedScale {
  /// Validates the scalar range, transform, and hexadecimal color stops.
  ///
  /// # Parameters
  /// * `scale`: mapping shared by a heatmap and its colorbar.
  ///
  /// # Returns
  /// A reusable map with RGB and Oklab stops prepared once.
  ///
  /// # Errors
  /// Rejects invalid colors, unordered ranges, or degenerate transformed ranges.
  pub fn new(scale: &ColorScale) -> Result<Self, Error> {
    let [min, max] = scale.range;
    require(
      min.is_finite() && max.is_finite() && min < max,
      "color range must be finite and increasing",
    )?;
    scale.transform.validate()?;
    require(
      (2..=256).contains(&scale.stops.len()),
      "provide between 2 and 256 color stops",
    )?;
    let transformed = scale.range.map(|v| scale.transform.apply(v));
    require(
      transformed.iter().all(|v| v.is_finite())
        && transformed[0] < transformed[1]
        && (transformed[1] - transformed[0]).is_finite(),
      "transformed color range must have a finite positive span",
    )?;
    let stops = scale
      .stops
      .iter()
      .map(|text| {
        let [r, g, b, a] = parse_color(text)?;
        let rgb = Srgb::new(f64::from(r) / 255.0, f64::from(g) / 255.0, f64::from(b) / 255.0);
        Ok(Stop {
          lab: Oklab::from_color(rgb.into_linear()),
          rgb,
          alpha: f64::from(a) / 255.0,
        })
      })
      .collect::<Result<Vec<_>, Error>>()?;
    Ok(Self {
      range: scale.range,
      transformed,
      transform: scale.transform,
      space: scale.space,
      stops,
    })
  }

  /// Maps a finite scalar value to its clipped color-scale coordinate.
  pub fn normalize(&self, value: f64) -> f64 {
    if value <= self.range[0] {
      0.0
    } else if value >= self.range[1] {
      1.0
    } else {
      (self.transform.apply(value) - self.transformed[0]) / (self.transformed[1] - self.transformed[0])
    }
  }

  /// Maps a normalized coordinate to an sRGB RGBA pixel.
  pub fn rgba(&self, coordinate: f64) -> [u8; 4] {
    let position = coordinate.clamp(0.0, 1.0) * (self.stops.len() - 1) as f64;
    let index = (position.floor() as usize).min(self.stops.len() - 2);
    let t = position - index as f64;
    let a = &self.stops[index];
    let b = &self.stops[index + 1];
    let mix = |a: f64, b: f64| (1.0 - t) * a + t * b;
    let rgb = match self.space {
      ColorSpace::Srgb => Srgb::new(
        mix(a.rgb.red, b.rgb.red),
        mix(a.rgb.green, b.rgb.green),
        mix(a.rgb.blue, b.rgb.blue),
      ),
      ColorSpace::Oklab => Srgb::from_linear(palette::LinSrgb::from_color(Oklab::new(
        mix(a.lab.l, b.lab.l),
        mix(a.lab.a, b.lab.a),
        mix(a.lab.b, b.lab.b),
      ))),
    };
    [rgb.red, rgb.green, rgb.blue, mix(a.alpha, b.alpha)].map(|v| (v.clamp(0.0, 1.0) * 255.0).round() as u8)
  }
}

pub(crate) fn parse_color(text: &str) -> Result<[u8; 4], Error> {
  let hex = text.strip_prefix('#').unwrap_or("");
  require(
    (hex.len() == 6 || hex.len() == 8) && hex.bytes().all(|b| b.is_ascii_hexdigit()),
    "colors must use #RRGGBB or #RRGGBBAA",
  )?;
  let mut rgba = [0, 0, 0, 255];
  for (i, channel) in rgba.iter_mut().enumerate().take(hex.len() / 2) {
    *channel =
      u8::from_str_radix(&hex[2 * i..2 * i + 2], 16).map_err(|_| Error::Invalid("invalid hexadecimal color".into()))?;
  }
  Ok(rgba)
}
