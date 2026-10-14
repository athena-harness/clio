//! Cartesian coordinates and orthonormal planes shared by models and sampling.

use crate::{require, Error};
use serde::{Deserialize, Serialize};

/// A three-dimensional Cartesian vector in caller-selected units.
pub type Vector = [f64; 3];

/// A plane whose local coordinates are distances along orthonormal axes.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Plane {
  /// World-space origin.
  pub origin: Vector,
  /// Unit vector for increasing horizontal coordinates.
  pub horizontal: Vector,
  /// Unit vector for increasing vertical coordinates.
  pub vertical: Vector,
}

impl Default for Plane {
  fn default() -> Self {
    Self {
      origin: [0.0; 3],
      horizontal: [1.0, 0.0, 0.0],
      vertical: [0.0, 1.0, 0.0],
    }
  }
}

impl Plane {
  /// Validates finite coordinates and orthonormal axes without rescaling them.
  pub fn validate(&self) -> Result<(), Error> {
    require(finite(self.origin), "plane origin must be finite")?;
    unit(self.horizontal)?;
    unit(self.vertical)?;
    require(
      dot(self.horizontal, self.vertical).abs() < 1e-10,
      "plane axes must be perpendicular",
    )
  }

  /// Converts local distances into a world-space position.
  pub fn position(&self, horizontal: f64, vertical: f64) -> Vector {
    add(
      self.origin,
      add(mul(self.horizontal, horizontal), mul(self.vertical, vertical)),
    )
  }

  /// Returns the oriented plane normal.
  pub fn normal(&self) -> Vector {
    cross(self.horizontal, self.vertical)
  }
}

pub(crate) fn finite(v: Vector) -> bool {
  v.iter().all(|v| v.is_finite())
}
pub(crate) fn add(a: Vector, b: Vector) -> Vector {
  std::array::from_fn(|i| a[i] + b[i])
}
pub(crate) fn sub(a: Vector, b: Vector) -> Vector {
  std::array::from_fn(|i| a[i] - b[i])
}
pub(crate) fn mul(a: Vector, b: f64) -> Vector {
  a.map(|v| v * b)
}
pub(crate) fn dot(a: Vector, b: Vector) -> f64 {
  a.into_iter().zip(b).map(|(a, b)| a * b).sum()
}
pub(crate) fn norm(a: Vector) -> f64 {
  a[0].hypot(a[1]).hypot(a[2])
}
pub(crate) fn cross(a: Vector, b: Vector) -> Vector {
  [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ]
}
pub(crate) fn unit(v: Vector) -> Result<(), Error> {
  require(
    finite(v) && (norm(v) - 1.0).abs() < 1e-10,
    "direction vectors must be finite and unit length",
  )
}
