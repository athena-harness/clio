//! Electric-field quantities composed with the shared scalar heatmap renderer.

use super::overlay::{PreparedOverlay, SourceOverlay};
use super::{ElectricField, FieldOptions, Source};
use crate::{
  geometry::{dot, norm, unit, Vector},
  render::{
    color::{ColorScale, PreparedScale},
    heatmap::{self, Grid},
  },
  require, Error,
};
use serde::{Deserialize, Serialize};

/// Scalar extracted from the complete three-dimensional electric field.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "kebab-case", deny_unknown_fields)]
pub enum Quantity {
  /// Euclidean norm, including components normal to the observation plane.
  Magnitude,
  /// Signed projection onto a world-space unit direction.
  Component {
    /// Unit direction for the projection.
    direction: Vector,
  },
}

/// Electric-field heatmap request, independent of Typst presentation settings.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Request {
  /// Discrete and continuous sources, evaluated by superposition.
  pub sources: Vec<Source>,
  /// Observation grid.
  pub grid: Grid,
  /// Physical scaling and regularization.
  pub field: FieldOptions,
  /// Magnitude or signed component.
  pub quantity: Quantity,
  /// Color scale, also usable by an independent colorbar.
  pub color: ColorScale,
  /// #RRGGBB or #RRGGBBAA for undefined, unregularized samples.
  pub singularity_color: String,
  /// Optional source mask styling, independent of field computation and colors.
  #[serde(default)]
  pub source_overlay: Option<SourceOverlay>,
}

/// Computes an electric field and renders its scalar heatmap as PNG bytes.
///
/// # Parameters
/// * `request`: independent source, grid, physical, quantity, and color settings.
///
/// # Returns
/// PNG bytes; singular samples use `singularity_color` rather than a finite cap.
///
/// # Errors
/// Rejects invalid parameters, more than one billion source/pixel evaluations,
/// numerical overflow, or PNG encoding failures.
pub fn render(request: &Request) -> Result<Vec<u8>, Error> {
  let pixels = request.grid.validate()?;
  if let Quantity::Component { direction } = request.quantity {
    unit(direction)?;
  }
  let scale = PreparedScale::new(&request.color)?;
  let missing = heatmap::missing_color(&request.singularity_color)?;
  let field = ElectricField::new(&request.sources, request.field)?;
  let overlay = request
    .source_overlay
    .as_ref()
    .map(|style| PreparedOverlay::new(&request.sources, style))
    .transpose()?;
  require(
    (pixels as u64) * ((field.evaluation_count() + if overlay.is_some() { request.sources.len() } else { 0 }) as u64)
      <= 1_000_000_000,
    "request exceeds one billion source/pixel evaluations; reduce resolution or integration samples",
  )?;
  heatmap::render_with_overlay(
    &request.grid,
    &scale,
    missing,
    |position| {
      Ok(field.at(position)?.map(|field| match request.quantity {
        Quantity::Magnitude => norm(field),
        Quantity::Component { direction } => dot(field, direction),
      }))
    },
    |position| overlay.as_ref().and_then(|overlay| overlay.pixel(position)),
  )
}
