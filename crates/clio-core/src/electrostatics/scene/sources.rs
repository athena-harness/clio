//! Visual geometry from the same prepared cells used for source capture.

use super::{curves, drawing::Canvas, Request};
use crate::{
  electrostatics::{custom_geometry::Shape, ElectricField, Source},
  geometry::{add, cross, dot, mul, norm, sub, Plane, Vector},
  render::color::parse_color,
  require, Error,
};
use std::{collections::BTreeMap, f64::consts::TAU};

type FaceKey = [[u64; 3]; 3];
type EdgeKey = [[u64; 3]; 2];

pub(super) fn draw(canvas: &mut Canvas<'_>, request: &Request, field: &ElectricField) -> Result<(), Error> {
  let scene = &request.scene;
  let mut line_sources: BTreeMap<[u8; 4], Vec<[Vector; 2]>> = BTreeMap::new();
  let mut line_count = 0;
  let tolerance = norm(sub(scene.bounds[1], scene.bounds[0])) / 24.0;
  require(
    tolerance.is_finite() && tolerance > 0.0,
    "scene box diagonal must be positive and finite",
  )?;
  for (index, source) in request.sources.iter().enumerate() {
    let color = parse_color(&scene.source_colors[index % scene.source_colors.len()])?;
    if color[3] == 0 {
      continue;
    }
    let mut triangles = Vec::new();
    match source {
      Source::Point(point) => canvas.point(point.position, color, scene.point_size)?,
      Source::Segment(segment) => {
        line_sources
          .entry(color)
          .or_default()
          .push([segment.start, segment.end]);
        line_count += 1;
      }
      Source::Annulus(surface) => round(
        &mut triangles,
        surface.plane,
        surface.inner_radius,
        surface.outer_radius,
      ),
      Source::PlaneWithHole(surface) => {
        // Only the displayed patch is finite; the field evaluator still integrates infinity.
        let radius = corners(scene.bounds)
          .iter()
          .map(|&p| {
            let d = sub(p, surface.plane.origin);
            dot(d, surface.plane.horizontal).hypot(dot(d, surface.plane.vertical))
          })
          .fold(surface.hole_radius, f64::max);
        if radius > surface.hole_radius {
          round(&mut triangles, surface.plane, surface.hole_radius, radius);
        }
      }
      Source::Parametric(_) | Source::TriangleMesh(_) => {
        if let Some(geometry) = field.custom_geometry(index) {
          let mut boundary: BTreeMap<FaceKey, (u32, [Vector; 3])> = BTreeMap::new();
          require(
            geometry.cells().len() <= 131_072,
            "spatial source exceeds 131072 geometry cells; reduce source samples",
          )?;
          for cell in geometry.cells() {
            match cell.shape {
              Shape::Segment(points) => {
                line_sources.entry(color).or_default().push(points);
                line_count += 1;
              }
              Shape::Triangle(points) => triangles.push(points),
              Shape::Tetrahedron([a, b, c, d]) => {
                for face in [[a, b, c], [a, b, d], [a, c, d], [b, c, d]] {
                  let mut key = face.map(|p| p.map(f64::to_bits));
                  key.sort();
                  boundary
                    .entry(key)
                    .and_modify(|entry| entry.0 += 1)
                    .or_insert((1, face));
                }
              }
            }
          }
          // Interior tetrahedron faces are omitted, so volumes show their exterior shell.
          triangles.extend(
            boundary
              .into_values()
              .filter(|(count, _)| *count == 1)
              .map(|(_, face)| face),
          );
        }
      }
    }
    require(
      line_count <= 131_072,
      "spatial line sources exceed 131072 segments; reduce curve samples",
    )?;
    let mut edges: BTreeMap<EdgeKey, (u32, [Vector; 2])> = BTreeMap::new();
    for triangle in triangles {
      for i in 0..3 {
        let edge = [triangle[i], triangle[(i + 1) % 3]];
        let mut key = edge.map(|p| p.map(f64::to_bits));
        key.sort();
        edges.entry(key).and_modify(|entry| entry.0 += 1).or_insert((1, edge));
      }
      let normal = cross(sub(triangle[1], triangle[0]), sub(triangle[2], triangle[0]));
      let length = norm(normal);
      let illumination = if length > 0.0 {
        0.65 + 0.35 * (normal[2] / length).abs()
      } else {
        1.0
      };
      let mut shaded = color;
      for channel in &mut shaded[..3] {
        *channel = (f64::from(*channel) * illumination).round() as u8;
      }
      triangle_tiles(canvas, triangle, shaded, tolerance, 0)?;
    }
    let mut edge_color = color;
    for channel in &mut edge_color[..3] {
      *channel = (f64::from(*channel) * 0.7).round() as u8;
    }
    // Low-alpha sources keep low-alpha outlines, including invisible geometry.
    edge_color[3] = color[3].saturating_mul(2);
    for (_, edge) in edges.into_values().filter(|(count, _)| *count == 1) {
      for i in 0..24 {
        let point = |j| {
          add(
            mul(edge[0], 1.0 - f64::from(j) / 24.0),
            mul(edge[1], f64::from(j) / 24.0),
          )
        };
        canvas.segment([point(i), point(i + 1)], edge_color, scene.source_thickness, None)?;
      }
    }
  }
  for (color, segments) in line_sources {
    curves::draw(canvas, &segments, color, scene.curve_radius, scene.source_thickness)?;
  }
  Ok(())
}

fn triangle_tiles(
  canvas: &mut Canvas<'_>,
  [a, b, c]: [Vector; 3],
  color: [u8; 4],
  tolerance: f64,
  depth: u32,
) -> Result<(), Error> {
  let length = norm(sub(a, b)).max(norm(sub(a, c))).max(norm(sub(b, c)));
  if length > tolerance && depth < 5 {
    let ab = add(mul(a, 0.5), mul(b, 0.5));
    let ac = add(mul(a, 0.5), mul(c, 0.5));
    let bc = add(mul(b, 0.5), mul(c, 0.5));
    for triangle in [[a, ab, ac], [ab, b, bc], [ac, bc, c], [ab, bc, ac]] {
      triangle_tiles(canvas, triangle, color, tolerance, depth + 1)?;
    }
    Ok(())
  } else {
    canvas.polygon(&[a, b, c], color)
  }
}

fn round(triangles: &mut Vec<[Vector; 3]>, plane: Plane, inner: f64, outer: f64) {
  for radial in 0..8 {
    let r0 = inner + f64::from(radial) / 8.0 * (outer - inner);
    let r1 = inner + f64::from(radial + 1) / 8.0 * (outer - inner);
    for angular in 0..64 {
      let point = |r: f64, a: u32| {
        let (sin, cos) = (f64::from(a % 64) * TAU / 64.0).sin_cos();
        plane.position(r * cos, r * sin)
      };
      let a = point(r0, angular);
      let b = point(r1, angular);
      let c = point(r1, angular + 1);
      let d = point(r0, angular + 1);
      triangles.push([a, b, c]);
      if r0 > 0.0 {
        triangles.push([a, c, d]);
      }
    }
  }
}

fn corners(bounds: [Vector; 2]) -> [Vector; 8] {
  std::array::from_fn(|i| std::array::from_fn(|axis| bounds[(i >> axis) & 1][axis]))
}
