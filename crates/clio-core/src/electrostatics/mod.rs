//! Coulomb superposition of discrete, built-in, and user-defined continuous sources.

pub mod continuous_charge;
pub mod custom_geometry;
pub mod field_lines;
pub mod heatmap;
pub mod overlay;
pub mod point_charges;

use crate::{
  geometry::{dot, finite, mul, sub, Plane, Vector},
  require, Error,
};
use continuous_charge::{Annulus, PlaneWithHole, Segment};
use custom_geometry::{Geometry, Parametric, TriangleMesh};
use point_charges::PointCharge;
use serde::{Deserialize, Serialize};

/// Independently configured sources that may be mixed in one field.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "kind", rename_all = "kebab-case")]
pub enum Source {
  /// A discrete signed charge.
  Point(PointCharge),
  /// A finite uniform line charge.
  Segment(Segment),
  /// A uniform annulus or disk.
  Annulus(Annulus),
  /// An infinite uniform plane integrated outside a circular hole.
  PlaneWithHole(PlaneWithHole),
  /// A user-defined curve, surface, or volume with parameter-dependent density.
  Parametric(Parametric),
  /// An indexed charged surface with uniform or per-face density.
  TriangleMesh(TriangleMesh),
}

/// Physical scaling and regularization, independent of the color scale.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct FieldOptions {
  /// Coulomb multiplier; use 1 for relative fields or k_e for SI units.
  pub coulomb_constant: f64,
  /// Length epsilon in the Plummer kernel r/(r^2 + epsilon^2)^(3/2).
  pub softening: f64,
}

impl Default for FieldOptions {
  fn default() -> Self {
    Self {
      coulomb_constant: 1.0,
      softening: 0.02,
    }
  }
}

/// Prepared quadrature nodes reused across all observation points.
pub struct ElectricField {
  nodes: Vec<PointCharge>,
  planes: Vec<(Plane, f64, f64)>,
  options: FieldOptions,
  geometry: Vec<Option<Geometry>>,
  active: Vec<bool>,
  geometry_cost: usize,
}

impl ElectricField {
  /// Validates sources and prepares continuous quadrature once.
  ///
  /// # Parameters
  /// * `sources`: signed point and continuous sources to superpose.
  /// * `options`: Coulomb multiplier and regularization length in the geometry unit.
  ///
  /// # Returns
  /// A field evaluator independent of image resolution and color mapping.
  ///
  /// # Errors
  /// Rejects invalid geometry, non-finite parameters, or excessive quadrature sizes.
  pub fn new(sources: &[Source], options: FieldOptions) -> Result<Self, Error> {
    require(
      options.coulomb_constant.is_finite() && options.coulomb_constant > 0.0,
      "coulomb-constant must be positive and finite",
    )?;
    require(
      options.softening.is_finite() && options.softening >= 0.0,
      "softening must be nonnegative and finite",
    )?;
    require(
      !sources.is_empty() && sources.len() <= 65_536,
      "provide between 1 and 65536 sources",
    )?;
    let mut nodes = Vec::new();
    let mut planes = Vec::new();
    let mut geometry = Vec::with_capacity(sources.len());
    let mut active = Vec::with_capacity(sources.len());
    let mut preparation_budget = 64_000_000_u64;
    for source in sources {
      let first_node = nodes.len();
      let mut cells = None;
      match source {
        Source::Point(point) => {
          point.validate()?;
          nodes.push(*point);
        }
        Source::Segment(segment) => nodes.extend(segment.nodes()?),
        Source::Annulus(annulus) => nodes.extend(annulus.nodes()?),
        Source::PlaneWithHole(source) => {
          nodes.extend(source.nodes()?);
          planes.push((source.plane, source.density, source.hole_radius));
        }
        Source::Parametric(source) => {
          let prepared = source.prepare(&mut preparation_budget)?;
          nodes.extend(prepared.nodes);
          cells = Some(Geometry::new(prepared.cells));
        }
        Source::TriangleMesh(source) => {
          let prepared = source.prepare()?;
          nodes.extend(prepared.nodes);
          cells = Some(Geometry::new(prepared.cells));
        }
      }
      active.push(nodes[first_node..].iter().any(|node| node.charge != 0.0));
      geometry.push(cells);
      require(nodes.len() <= 262_144, "total quadrature nodes must not exceed 262144")?;
    }
    nodes.retain(|node| node.charge != 0.0);
    let geometry_cost = geometry
      .iter()
      .map(|cells| cells.as_ref().map_or(1, Geometry::cost))
      .sum();
    Ok(Self {
      nodes,
      planes,
      options,
      geometry,
      active,
      geometry_cost,
    })
  }

  /// Returns the number of source evaluations per observation point.
  pub fn evaluation_count(&self) -> usize {
    self.nodes.len() + self.planes.len()
  }

  pub(crate) fn geometry_evaluation_count(&self) -> usize {
    self.geometry_cost
  }

  pub(crate) fn custom_geometry(&self, index: usize) -> Option<&Geometry> {
    self.geometry[index].as_ref()
  }

  pub(crate) fn source_geometry_cost(&self, index: usize) -> usize {
    self.geometry[index].as_ref().map_or(1, Geometry::cost)
  }

  pub(crate) fn source_distance(&self, index: usize, source: &Source, position: Vector, charged_only: bool) -> f64 {
    if charged_only && !self.active[index] {
      return f64::INFINITY;
    }
    if let Some(geometry) = &self.geometry[index] {
      geometry.distance(position, charged_only)
    } else {
      overlay::distance(source, position)
    }
  }

  /// Evaluates the total field at one world-space position.
  ///
  /// # Parameters
  /// * `position`: finite Cartesian coordinates in the source length unit.
  ///
  /// # Returns
  /// The full three-dimensional field, or `None` at an unregularized singularity.
  /// At zero softening, points on the charged part of an infinite plane are undefined.
  ///
  /// # Errors
  /// Rejects non-finite positions or arithmetic overflow.
  pub fn at(&self, position: Vector) -> Result<Option<Vector>, Error> {
    require(finite(position), "observation position must be finite")?;
    let mut field = [0.0; 3];
    // Compensated sums reduce cancellation for dipoles and distant surface nodes.
    let mut correction = [0.0; 3];
    let mut accumulate = |term: Vector| {
      for axis in 0..3 {
        let y = term[axis] - correction[axis];
        let total = field[axis] + y;
        correction[axis] = (total - field[axis]) - y;
        field[axis] = total;
      }
    };
    for &(plane, density, hole_radius) in &self.planes {
      if density == 0.0 {
        continue;
      }
      let delta = sub(position, plane.origin);
      let normal = plane.normal();
      let distance = dot(delta, normal);
      if self.options.softening == 0.0
        && distance == 0.0
        && dot(delta, plane.horizontal).hypot(dot(delta, plane.vertical)) >= hole_radius
      {
        return Ok(None);
      }
    }
    for node in &self.nodes {
      let Some(term) = node.field(position, self.options.softening)? else {
        return Ok(None);
      };
      accumulate(term);
    }
    let field = mul(field, self.options.coulomb_constant);
    if !finite(field) {
      return Err(Error::Numerical("field superposition overflow"));
    }
    Ok(Some(field))
  }
}
