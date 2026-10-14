//! Discrete Coulomb sources and the kernel shared by continuous quadrature.

use crate::{
  geometry::{dot, finite, mul, norm, sub, Vector},
  require, Error,
};
use serde::{Deserialize, Serialize};

/// A signed point charge in a three-dimensional position.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct PointCharge {
  /// Source position in the same length unit as the observation plane.
  pub position: Vector,
  /// Signed charge in caller-selected charge units.
  pub charge: f64,
}

impl PointCharge {
  pub(crate) fn validate(&self) -> Result<(), Error> {
    require(
      finite(self.position) && self.charge.is_finite(),
      "point charge and position must be finite",
    )
  }

  pub(crate) fn field(&self, position: Vector, softening: f64) -> Result<Option<Vector>, Error> {
    if self.charge == 0.0 {
      return Ok(Some([0.0; 3]));
    }
    let delta = sub(position, self.position);
    let squared = dot(delta, delta) + softening * softening;
    // Ordinary geometry uses one WASM sqrt; hypot is reserved for extreme scales.
    let distance = if squared.is_normal() {
      squared.sqrt()
    } else {
      norm(delta).hypot(softening)
    };
    if distance == 0.0 {
      return Ok(None);
    }
    // Divide sequentially to avoid cubing a large distance.
    let field = mul(delta.map(|d| d / distance), self.charge / distance / distance);
    if !finite(field) {
      return Err(Error::Numerical("Coulomb field overflow"));
    }
    Ok(Some(field))
  }
}
