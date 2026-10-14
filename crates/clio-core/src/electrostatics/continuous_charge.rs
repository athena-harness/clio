//! Midpoint quadrature of uniform line and surface charge distributions.

use super::point_charges::PointCharge;
use crate::{
  geometry::{finite, norm, sub, Plane, Vector},
  require, Error,
};
use serde::{Deserialize, Serialize};
use std::f64::consts::TAU;

/// A finite uniformly charged line segment.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Segment {
  /// First endpoint.
  pub start: Vector,
  /// Second endpoint.
  pub end: Vector,
  /// Signed charge per unit length.
  pub density: f64,
  /// Number of midpoint integration samples.
  pub samples: u32,
}

impl Segment {
  pub(crate) fn nodes(&self) -> Result<Vec<PointCharge>, Error> {
    let length = norm(sub(self.end, self.start));
    require(
      finite(self.start) && finite(self.end) && length.is_finite() && length > 0.0,
      "segment endpoints must be finite and distinct",
    )?;
    require(self.density.is_finite(), "line density must be finite")?;
    count(self.samples, 1)?;
    let charge = self.density * (length / f64::from(self.samples));
    require(charge.is_finite(), "line quadrature charge must be finite")?;
    let mut nodes = Vec::with_capacity(self.samples as usize);
    for i in 0..self.samples {
      let t = (f64::from(i) + 0.5) / f64::from(self.samples);
      let position = std::array::from_fn(|axis| (1.0 - t) * self.start[axis] + t * self.end[axis]);
      nodes.push(PointCharge { position, charge });
    }
    Ok(nodes)
  }
}

/// A uniform annulus; an inner radius of zero describes a disk.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Annulus {
  /// Source plane and center.
  pub plane: Plane,
  /// Inner uncharged radius, including zero.
  pub inner_radius: f64,
  /// Outer charged radius.
  pub outer_radius: f64,
  /// Signed charge per unit area.
  pub density: f64,
  /// Number of radial midpoint samples.
  pub radial_samples: u32,
  /// Number of full-circle angular midpoint samples.
  pub angular_samples: u32,
}

impl Annulus {
  pub(crate) fn nodes(&self) -> Result<Vec<PointCharge>, Error> {
    self.plane.validate()?;
    require(
      self.inner_radius.is_finite()
        && self.outer_radius.is_finite()
        && self.inner_radius >= 0.0
        && self.outer_radius > self.inner_radius,
      "annulus radii must satisfy 0 <= inner-radius < outer-radius",
    )?;
    require(self.density.is_finite(), "surface density must be finite")?;
    let count = count(self.radial_samples, self.angular_samples)?;
    require(self.angular_samples >= 4, "angular-samples must be at least 4")?;
    let dr = (self.outer_radius - self.inner_radius) / f64::from(self.radial_samples);
    let da = TAU / f64::from(self.angular_samples);
    let mut nodes = Vec::with_capacity(count);
    // Trigonometric values are independent of pixel and radial index.
    let angles: Vec<_> = (0..self.angular_samples)
      .map(|i| ((f64::from(i) + 0.5) * da).sin_cos())
      .collect();
    for i in 0..self.radial_samples {
      let radius = self.inner_radius + (f64::from(i) + 0.5) * dr;
      let charge = self.density * radius * dr * da;
      require(charge.is_finite(), "surface quadrature charge must be finite")?;
      for &(sin, cos) in &angles {
        let position = self.plane.position(radius * cos, radius * sin);
        require(finite(position), "surface quadrature position must be finite")?;
        nodes.push(PointCharge { position, charge });
      }
    }
    Ok(nodes)
  }
}

/// An infinite uniform plane with an uncharged circular hole.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct PlaneWithHole {
  /// Plane and hole center.
  pub plane: Plane,
  /// Radius of the uncharged circular hole.
  pub hole_radius: f64,
  /// Signed surface charge density outside the hole.
  pub density: f64,
  /// Midpoint samples on the compactified infinite radial interval.
  pub radial_samples: u32,
  /// Full-circle angular midpoint samples outside the hole.
  pub angular_samples: u32,
}

impl PlaneWithHole {
  pub(crate) fn nodes(&self) -> Result<Vec<PointCharge>, Error> {
    self.plane.validate()?;
    require(
      self.hole_radius.is_finite() && self.hole_radius > 0.0,
      "hole-radius must be positive and finite",
    )?;
    require(self.density.is_finite(), "surface density must be finite")?;
    let count = count(self.radial_samples, self.angular_samples)?;
    require(self.angular_samples >= 4, "angular-samples must be at least 4")?;
    let dt = 1.0 / f64::from(self.radial_samples);
    let da = TAU / f64::from(self.angular_samples);
    let angles: Vec<_> = (0..self.angular_samples)
      .map(|i| ((f64::from(i) + 0.5) * da).sin_cos())
      .collect();
    let mut nodes = Vec::with_capacity(count);
    for i in 0..self.radial_samples {
      // r = R/(1-t) maps t in [0,1) onto every charged radius [R,infinity).
      // The Jacobian r*dr/dt integrates the infinite tail without a cutoff.
      let u = 1.0 - (f64::from(i) + 0.5) * dt;
      let radius = self.hole_radius / u;
      let charge = self.density * radius * (radius / u) * dt * da;
      require(charge.is_finite(), "infinite-plane quadrature charge must be finite")?;
      for &(sin, cos) in &angles {
        let position = self.plane.position(radius * cos, radius * sin);
        require(finite(position), "infinite-plane quadrature position must be finite")?;
        nodes.push(PointCharge { position, charge });
      }
    }
    Ok(nodes)
  }
}

pub(crate) fn count(radial: u32, angular: u32) -> Result<usize, Error> {
  let count = u64::from(radial) * u64::from(angular);
  require(
    radial > 0 && angular > 0 && count <= 65_536,
    "integration sample counts must be positive with a product at most 65536",
  )?;
  Ok(count as usize)
}
