//! Connected, shaded tubes for zero-thickness line-charge geometry.

use super::drawing::{clip_segment, Canvas};
use crate::{
  geometry::{add, cross, dot, finite, mul, norm, sub, Vector},
  require, Error,
};
use std::{
  collections::{BTreeMap, BTreeSet},
  f64::consts::TAU,
};

const SIDES: usize = 16;

pub(super) fn draw(
  canvas: &mut Canvas<'_>,
  segments: &[[Vector; 2]],
  color: [u8; 4],
  radius: f64,
  width: f64,
) -> Result<(), Error> {
  if radius == 0.0 {
    for &segment in segments {
      canvas.segment(segment, color, width, None)?;
    }
    return Ok(());
  }
  let diagonal = norm(sub(canvas.bounds[1], canvas.bounds[0]));
  let epsilon = diagonal * 1e-10;
  require(epsilon > 0.0, "scene bounds are too small for tube connectivity")?;
  let padded: [Vector; 2] =
    std::array::from_fn(|side| canvas.bounds[side].map(|v| v + if side == 0 { -radius } else { radius }));
  require(
    padded.iter().all(|&p| finite(p)),
    "tube clipping bounds must remain finite",
  )?;
  let mut vertices = Vec::new();
  let mut indices = BTreeMap::new();
  let mut unique = BTreeSet::new();
  let mut edges = Vec::new();
  for &segment in segments {
    let Some(segment) = clip_segment(segment, padded) else {
      continue;
    };
    if norm(sub(segment[1], segment[0])) <= epsilon {
      continue;
    }
    let mut edge = [0; 2];
    for i in 0..2 {
      // Weld cached cell endpoints and floating-point seams of periodic parameterizations.
      let key: [i64; 3] =
        std::array::from_fn(|axis| ((segment[i][axis] - canvas.bounds[0][axis]) / epsilon).round() as i64);
      edge[i] = *indices.entry(key).or_insert_with(|| {
        vertices.push(segment[i]);
        vertices.len() - 1
      });
    }
    if edge[0] == edge[1] {
      continue;
    }
    let mut key = edge;
    key.sort();
    if unique.insert(key) {
      edges.push(edge);
    }
  }
  let mut adjacent = vec![Vec::new(); vertices.len()];
  for (index, edge) in edges.iter().enumerate() {
    for &vertex in edge {
      adjacent[vertex].push(index);
    }
  }
  let mut used = vec![false; edges.len()];
  // Open paths and branches come first; the remaining edges form closed loops.
  for start in 0..vertices.len() {
    if adjacent[start].len() == 2 {
      continue;
    }
    for &edge in &adjacent[start] {
      if !used[edge] {
        let path = walk(start, edge, &vertices, &edges, &adjacent, &mut used);
        tube(canvas, &path, color, radius, diagonal / 64.0)?;
      }
    }
  }
  for index in 0..edges.len() {
    if !used[index] {
      let path = walk(edges[index][0], index, &vertices, &edges, &adjacent, &mut used);
      tube(canvas, &path, color, radius, diagonal / 64.0)?;
    }
  }
  Ok(())
}

fn walk(
  start: usize,
  mut edge: usize,
  vertices: &[Vector],
  edges: &[[usize; 2]],
  adjacent: &[Vec<usize>],
  used: &mut [bool],
) -> Vec<Vector> {
  let mut path = vec![vertices[start]];
  let mut current = start;
  loop {
    used[edge] = true;
    let [a, b] = edges[edge];
    let next = if a == current { b } else { a };
    path.push(vertices[next]);
    if next == start || adjacent[next].len() != 2 {
      break;
    }
    let Some(&next_edge) = adjacent[next].iter().find(|&&i| !used[i]) else {
      break;
    };
    current = next;
    edge = next_edge;
  }
  path
}

fn unit(v: Vector) -> Result<Vector, Error> {
  let length = norm(v);
  require(
    length.is_finite() && length > 0.0,
    "tube directions must have finite positive length",
  )?;
  Ok(v.map(|component| component / length))
}

fn perpendicular(tangent: Vector) -> Result<Vector, Error> {
  let axis = (0..3)
    .min_by(|&a, &b| tangent[a].abs().total_cmp(&tangent[b].abs()))
    .unwrap_or(0);
  let mut reference = [0.0; 3];
  reference[axis] = 1.0;
  unit(cross(tangent, reference))
}

fn transport(normal: Vector, tangent: Vector) -> Result<Vector, Error> {
  let projected = sub(normal, mul(tangent, dot(normal, tangent)));
  if norm(projected) > 1e-8 {
    unit(projected)
  } else {
    perpendicular(tangent)
  }
}

fn tube(canvas: &mut Canvas<'_>, path: &[Vector], color: [u8; 4], radius: f64, step: f64) -> Result<(), Error> {
  if path.len() < 2 {
    return Ok(());
  }
  let closed = path.first() == path.last();
  let mut points = vec![path[0]];
  for pair in path.windows(2) {
    let length = norm(sub(pair[1], pair[0]));
    let pieces = (length / step).ceil().max(1.0) as usize;
    require(
      points.len().saturating_add(pieces) <= 16_384,
      "tube path exceeds 16384 display rings; simplify curve geometry",
    )?;
    for i in 1..=pieces {
      let t = i as f64 / pieces as f64;
      points.push(add(mul(pair[0], 1.0 - t), mul(pair[1], t)));
    }
  }
  // Shared rings join adjacent cells without overlapping capped cylinders.
  let last = points.len() - 1;
  let mut tangents = Vec::with_capacity(points.len());
  for i in 0..points.len() {
    let previous = if i == 0 {
      if closed {
        last - 1
      } else {
        0
      }
    } else {
      i - 1
    };
    let next = if i == last {
      if closed {
        1
      } else {
        last
      }
    } else {
      i + 1
    };
    let forward = if next == i {
      unit(sub(points[i], points[previous]))?
    } else {
      unit(sub(points[next], points[i]))?
    };
    let backward = if previous == i {
      forward
    } else {
      unit(sub(points[i], points[previous]))?
    };
    let average = add(forward, backward);
    tangents.push(if norm(average) > 1e-8 { unit(average)? } else { forward });
  }
  let mut normals = vec![perpendicular(tangents[0])?];
  for &tangent in &tangents[1..] {
    normals.push(transport(normals[normals.len() - 1], tangent)?);
  }
  if closed {
    // Distribute frame holonomy around a spatial loop instead of leaving a twisted seam.
    let angle = dot(cross(normals[last], normals[0]), tangents[0]).atan2(dot(normals[last], normals[0]));
    for (i, normal) in normals.iter_mut().enumerate() {
      let (sin, cos) = (angle * i as f64 / last as f64).sin_cos();
      *normal = add(mul(*normal, cos), mul(cross(tangents[i], *normal), sin));
    }
    normals[last] = normals[0];
  }
  let binormals: Vec<_> = tangents.iter().zip(&normals).map(|(&t, &n)| cross(t, n)).collect();
  let radial = |i: usize, angle: f64| {
    let (sin, cos) = angle.sin_cos();
    add(mul(normals[i], cos), mul(binormals[i], sin))
  };
  let ring = |i: usize| -> [Vector; SIDES] {
    std::array::from_fn(|j| add(points[i], mul(radial(i, j as f64 * TAU / SIDES as f64), radius)))
  };
  let mut a = ring(0);
  if !closed {
    canvas.polygon(&a, canvas.shade(color, mul(tangents[0], -1.0)))?;
  }
  for i in 1..points.len() {
    let b = ring(i);
    for j in 0..SIDES {
      let next = (j + 1) % SIDES;
      let angle = (j as f64 + 0.5) * TAU / SIDES as f64;
      let average = add(radial(i - 1, angle), radial(i, angle));
      let normal = if norm(average) > 1e-8 {
        unit(average)?
      } else {
        radial(i, angle)
      };
      canvas.polygon(&[a[j], a[next], b[next], b[j]], canvas.shade(color, normal))?;
    }
    a = b;
  }
  if !closed {
    canvas.polygon(&a, canvas.shade(color, tangents[last]))?;
  }
  Ok(())
}
