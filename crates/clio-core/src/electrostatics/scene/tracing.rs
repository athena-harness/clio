//! World-space RK4 paths; neither observation-plane projection nor camera enters integration.

use super::{inside, Request};
use crate::{
  electrostatics::{
    field_lines::{Direction, Termination},
    ElectricField,
  },
  geometry::{add, finite, mul, norm, sub, Vector},
  require, Error,
};
use serde::{Deserialize, Serialize};

/// Numerical controls for normalized full-vector field tracing.
#[derive(Clone, Copy, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct SpatialTracing {
  /// Fixed world-space arc-length step, independent of image resolution.
  pub step: f64,
  /// Maximum steps per branch, between 1 and 10000.
  pub max_steps: u32,
  /// Stop when the complete field magnitude is at or below this threshold.
  pub min_field: f64,
  /// Geometry capture distance; zero disables source capture.
  pub source_radius: f64,
  /// Trace forward, backward, or both branches from every seed.
  pub direction: Direction,
}

/// A genuine three-dimensional field line ordered in the direction of the electric field.
#[derive(Clone, Debug, Serialize)]
pub struct SpatialLine {
  /// World-space coordinates, including joined seed positions once.
  pub points: Vec<Vector>,
  /// Numerical termination reason at the beginning of the oriented path.
  pub start: Termination,
  /// Numerical termination reason at the end of the oriented path.
  pub end: Termination,
}

struct Branch {
  points: Vec<Vector>,
  reason: Termination,
}

pub(super) fn prepared(request: &Request, field: &ElectricField) -> Result<Vec<SpatialLine>, Error> {
  let Some(lines) = &request.scene.lines else {
    return Ok(Vec::new());
  };
  let o = lines.tracing;
  require(
    o.step.is_finite() && o.step > 0.0,
    "spatial tracing step must be positive and finite",
  )?;
  require(
    (1..=10_000).contains(&o.max_steps),
    "spatial max-steps must be between 1 and 10000",
  )?;
  require(
    o.min_field.is_finite() && o.min_field >= 0.0,
    "spatial min-field must be nonnegative and finite",
  )?;
  require(
    o.source_radius.is_finite() && o.source_radius >= 0.0,
    "spatial source-radius must be nonnegative and finite",
  )?;
  require(
    o.source_radius == 0.0 || o.step <= o.source_radius,
    "spatial tracing step must not exceed a nonzero source-radius",
  )?;
  require(
    !lines.seeds.is_empty() && lines.seeds.len() <= 1024,
    "provide between 1 and 1024 spatial seeds",
  )?;
  let branches = if matches!(o.direction, Direction::Both) { 2 } else { 1 };
  require(
    lines.seeds.len() as u64 * branches * (u64::from(o.max_steps) + 1) <= 4_194_304,
    "spatial request exceeds 4194304 possible trace vertices",
  )?;
  let mut budget = 1_000_000_000_u64;
  let mut result = Vec::with_capacity(lines.seeds.len());
  for &seed in &lines.seeds {
    require(
      inside(seed, request.scene.bounds),
      "spatial seeds must be finite and inside scene bounds",
    )?;
    let mut backward = if matches!(o.direction, Direction::Forward) {
      Branch {
        points: vec![seed],
        reason: Termination::Seed,
      }
    } else {
      branch(seed, -1.0, request, field, o, &mut budget)?
    };
    backward.points.reverse();
    let forward = if matches!(o.direction, Direction::Backward) {
      Branch {
        points: vec![seed],
        reason: Termination::Seed,
      }
    } else {
      branch(seed, 1.0, request, field, o, &mut budget)?
    };
    backward.points.extend(forward.points.into_iter().skip(1));
    result.push(SpatialLine {
      points: backward.points,
      start: backward.reason,
      end: forward.reason,
    });
  }
  Ok(result)
}

fn charge(budget: &mut u64, cost: usize) -> Result<(), Error> {
  *budget = budget
    .checked_sub(cost as u64)
    .ok_or_else(|| Error::Invalid("spatial tracing exceeds one billion field/geometry evaluations".into()))?;
  Ok(())
}

fn near_source(
  p: Vector,
  request: &Request,
  field: &ElectricField,
  radius: f64,
  budget: &mut u64,
) -> Result<bool, Error> {
  if radius == 0.0 {
    return Ok(false);
  }
  charge(budget, field.geometry_evaluation_count())?;
  Ok(
    request
      .sources
      .iter()
      .enumerate()
      .any(|(i, source)| field.source_distance(i, source, p, true) <= radius),
  )
}

fn tangent(
  p: Vector,
  sign: f64,
  field: &ElectricField,
  o: SpatialTracing,
  budget: &mut u64,
) -> Result<Result<Vector, Termination>, Error> {
  charge(budget, field.evaluation_count())?;
  let Some(vector) = field.at(p)? else {
    return Ok(Err(Termination::Singularity));
  };
  let length = norm(vector);
  require(length.is_finite(), "spatial field magnitude must remain finite")?;
  if length <= o.min_field {
    return Ok(Err(Termination::WeakField));
  }
  Ok(Ok(vector.map(|v| sign * v / length)))
}

fn branch(
  seed: Vector,
  sign: f64,
  request: &Request,
  field: &ElectricField,
  o: SpatialTracing,
  budget: &mut u64,
) -> Result<Branch, Error> {
  let mut points = vec![seed];
  let mut p = seed;
  macro_rules! stop {
    ($reason:expr) => {
      return Ok(Branch {
        points,
        reason: $reason,
      })
    };
  }
  macro_rules! direction {
    ($point:expr) => {
      match tangent($point, sign, field, o, budget)? {
        Ok(v) => v,
        Err(reason) => stop!(reason),
      }
    };
  }
  for _ in 0..o.max_steps {
    if near_source(p, request, field, o.source_radius, budget)? {
      stop!(Termination::Source);
    }
    let k1 = direction!(p);
    let k2 = direction!(add(p, mul(k1, o.step / 2.0)));
    let k3 = direction!(add(p, mul(k2, o.step / 2.0)));
    let k4 = direction!(add(p, mul(k3, o.step)));
    let next = std::array::from_fn(|i| p[i] + o.step * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) / 6.0);
    require(finite(next), "spatial field-line coordinates must remain finite")?;
    if norm(sub(next, p)) < o.step * 1e-6 {
      stop!(Termination::Stagnation);
    }
    if !inside(next, request.scene.bounds) {
      let mut t: f64 = 1.0;
      for i in 0..3 {
        let delta = next[i] - p[i];
        if delta != 0.0 {
          let edge = if delta > 0.0 {
            request.scene.bounds[1][i]
          } else {
            request.scene.bounds[0][i]
          };
          t = t.min(((edge - p[i]) / delta).clamp(0.0, 1.0));
        }
      }
      points.push(add(p, mul(sub(next, p), t)));
      stop!(Termination::Bounds);
    }
    let midpoint = add(mul(p, 0.5), mul(next, 0.5));
    if near_source(midpoint, request, field, o.source_radius, budget)? {
      points.push(midpoint);
      stop!(Termination::Source);
    }
    points.push(next);
    p = next;
  }
  Ok(Branch {
    points,
    reason: Termination::StepLimit,
  })
}
