//! Resolution-independent vector masks with analytic and adaptive geometry paths.

use super::PreparedOverlay;
use crate::{
  electrostatics::{custom_geometry::Shape, Source},
  geometry::{cross, dot, finite, norm, sub, Plane, Vector},
  render::{heatmap::Grid, svg::hex},
  require, Error,
};
use std::fmt::Write;

type Point = [f64; 2];

impl PreparedOverlay<'_> {
  /// Appends vector source geometry in source order, with one opacity group per source.
  pub(crate) fn write_svg(&self, svg: &mut String, grid: &Grid) -> Result<(), Error> {
    let [xmin, xmax, ymin, ymax] = grid.bounds;
    let sx = f64::from(grid.resolution[0]) / (xmax - xmin);
    let sy = f64::from(grid.resolution[1]) / (ymax - ymin);
    require(
      sx.is_finite() && sy.is_finite() && (-xmin * sx).is_finite() && (ymax * sy).is_finite(),
      "SVG coordinate scaling must be finite",
    )?;
    write!(
      svg,
      "<g transform=\"matrix({sx} 0 0 {} {} {})\">",
      -sy,
      -xmin * sx,
      ymax * sy
    )
    .map_err(format_error)?;
    let mut budget = 1_000_000_000_u64;
    for (index, (source, style)) in self.sources.iter().zip(&self.styles).enumerate() {
      let Some(style) = style.as_ref().filter(|style| style.color[3] > 0) else {
        continue;
      };
      write!(svg, "<g fill=\"{}\" stroke=\"{}\" stroke-width=\"{}\" stroke-linecap=\"round\" stroke-linejoin=\"round\" opacity=\"{}\">",
        hex(style.color), hex(style.color), 2.0 * style.radius, f64::from(style.color[3]) / 255.0).map_err(format_error)?;
      if !self.analytic(svg, source, index, grid, style.radius)? {
        let span = (xmax - xmin).hypot(ymax - ymin);
        require(span.is_finite(), "SVG bounds diagonal must be finite")?;
        // Boundary precision follows physical geometry, never the heatmap pixel count.
        let tolerance = (span / 4096.0).min(style.radius / 4.0);
        let mut contour = Contour {
          overlay: self,
          index,
          source,
          grid,
          radius: style.radius,
          tolerance,
          budget: &mut budget,
          path: String::new(),
        };
        contour.cell(grid.bounds, 0)?;
        write!(
          svg,
          "<path stroke=\"none\" fill-rule=\"nonzero\" d=\"{}\"/>",
          contour.path
        )
        .map_err(format_error)?;
      }
      svg.push_str("</g>");
      require(svg.len() <= 64 * 1024 * 1024, "SVG source geometry exceeds 64 MiB")?;
    }
    svg.push_str("</g>");
    Ok(())
  }

  fn analytic(&self, svg: &mut String, source: &Source, index: usize, grid: &Grid, radius: f64) -> Result<bool, Error> {
    let plane = grid.plane;
    match source {
      Source::Point(point) => {
        let height = dot(sub(point.position, plane.origin), plane.normal()).abs();
        if height < radius {
          circle(svg, local(plane, point.position), section_radius(radius, height))?;
        }
      }
      Source::Segment(segment) => {
        if !parallel_segment(svg, plane, [segment.start, segment.end], radius)? {
          return Ok(false);
        }
      }
      Source::Annulus(surface) => {
        if !round_surface(
          svg,
          grid,
          surface.plane,
          surface.inner_radius,
          Some(surface.outer_radius),
          radius,
        )? {
          return Ok(false);
        }
      }
      Source::PlaneWithHole(surface) => {
        if !round_surface(svg, grid, surface.plane, surface.hole_radius, None, radius)? {
          return Ok(false);
        }
      }
      Source::Parametric(_) | Source::TriangleMesh(_) => {
        let Some(geometry) = self.field.custom_geometry(index) else {
          return Ok(false);
        };
        let epsilon = 1e-10 * radius;
        let coplanar = geometry.cells().iter().all(|cell| match &cell.shape {
          Shape::Segment(points) => points.iter().all(|&p| height(plane, p).abs() <= epsilon),
          Shape::Triangle(points) => points.iter().all(|&p| height(plane, p).abs() <= epsilon),
          Shape::Tetrahedron(_) => false,
        });
        if !coplanar {
          return Ok(false);
        }
        let mut path = String::new();
        for cell in geometry.cells() {
          match &cell.shape {
            Shape::Segment([a, b]) => {
              let [a, b] = [local(plane, *a), local(plane, *b)];
              require(
                a.into_iter().chain(b).all(f64::is_finite),
                "SVG path coordinates must be finite",
              )?;
              write!(path, "M{} {}L{} {}", a[0], a[1], b[0], b[1]).map_err(format_error)?;
            }
            Shape::Triangle(points) => {
              let mut points = points.map(|p| local(plane, p));
              let area = (points[1][0] - points[0][0]) * (points[2][1] - points[0][1])
                - (points[1][1] - points[0][1]) * (points[2][0] - points[0][0]);
              if area < 0.0 {
                points.swap(1, 2);
              }
              polygon(&mut path, &points)?;
            }
            Shape::Tetrahedron(_) => {}
          }
        }
        // Positive polygon winding makes overlapping mesh faces a filled union.
        write!(svg, "<path fill-rule=\"nonzero\" d=\"{path}\"/>").map_err(format_error)?;
      }
    }
    Ok(true)
  }
}

fn local(plane: Plane, world: Vector) -> Point {
  let delta = sub(world, plane.origin);
  [dot(delta, plane.horizontal), dot(delta, plane.vertical)]
}

fn height(plane: Plane, world: Vector) -> f64 {
  dot(sub(world, plane.origin), plane.normal())
}

fn circle(svg: &mut String, [x, y]: Point, radius: f64) -> Result<(), Error> {
  require(
    [x, y, radius].into_iter().all(f64::is_finite),
    "SVG circle coordinates must be finite",
  )?;
  write!(svg, "<circle cx=\"{x}\" cy=\"{y}\" r=\"{radius}\" stroke=\"none\"/>").map_err(format_error)
}

fn parallel_segment(svg: &mut String, plane: Plane, points: [Vector; 2], radius: f64) -> Result<bool, Error> {
  let heights = points.map(|p| height(plane, p));
  if (heights[0] - heights[1]).abs() > 1e-10 * radius {
    return Ok(false);
  }
  let distance = heights[0].abs();
  if distance < radius {
    let width = 2.0 * section_radius(radius, distance);
    segment(svg, points.map(|p| local(plane, p)), width)?;
  }
  Ok(true)
}

fn segment(svg: &mut String, [a, b]: [Point; 2], width: f64) -> Result<(), Error> {
  require(
    a.into_iter().chain(b).chain([width]).all(f64::is_finite),
    "SVG segment coordinates must be finite",
  )?;
  write!(
    svg,
    "<path fill=\"none\" stroke-width=\"{width}\" d=\"M{} {}L{} {}\"/>",
    a[0], a[1], b[0], b[1]
  )
  .map_err(format_error)
}

fn round_surface(
  svg: &mut String,
  grid: &Grid,
  source: Plane,
  inner: f64,
  outer: Option<f64>,
  radius: f64,
) -> Result<bool, Error> {
  let normal_dot = dot(source.normal(), grid.plane.normal()).abs();
  let normal_cross = norm(cross(source.normal(), grid.plane.normal()));
  let offset = height(grid.plane, source.origin);
  let center = local(grid.plane, source.origin);
  let extent = outer.unwrap_or_else(|| {
    let [xmin, xmax, ymin, ymax] = grid.bounds;
    [[xmin, ymin], [xmin, ymax], [xmax, ymin], [xmax, ymax]]
      .into_iter()
      .map(|p| (p[0] - center[0]).hypot(p[1] - center[1]))
      .fold(0.0, f64::max)
  });
  if normal_cross == 0.0 || normal_cross * extent <= 1e-10 * radius {
    if offset.abs() >= radius {
      return Ok(true);
    }
    let padding = section_radius(radius, offset.abs());
    let mut path = String::new();
    if let Some(outer) = outer {
      ring(&mut path, center, outer + padding)?;
    } else {
      rectangle(&mut path, grid.bounds)?;
    }
    if inner > padding {
      ring(&mut path, center, inner - padding)?;
    }
    write!(svg, "<path stroke=\"none\" fill-rule=\"evenodd\" d=\"{path}\"/>").map_err(format_error)?;
    return Ok(true);
  }
  if normal_dot < 1e-12 && offset.abs() <= 1e-10 * radius {
    let source_normal = source.normal();
    let normal = [
      dot(source_normal, grid.plane.horizontal),
      dot(source_normal, grid.plane.vertical),
    ];
    let length = normal[0].hypot(normal[1]);
    let direction = [-normal[1] / length, normal[0] / length];
    let [xmin, xmax, ymin, ymax] = grid.bounds;
    let corners = [[xmin, ymin], [xmin, ymax], [xmax, ymin], [xmax, ymax]];
    let parameters = corners.map(|p| (p[0] - center[0]) * direction[0] + (p[1] - center[1]) * direction[1]);
    let minimum = outer.map_or(parameters.into_iter().fold(f64::INFINITY, f64::min) - radius, |r| -r);
    let maximum = outer.unwrap_or(parameters.into_iter().fold(f64::NEG_INFINITY, f64::max) + radius);
    let point = |t: f64| [center[0] + t * direction[0], center[1] + t * direction[1]];
    if inner == 0.0 {
      segment(svg, [point(minimum), point(maximum)], 2.0 * radius)?;
    } else {
      if minimum < -inner {
        segment(svg, [point(minimum), point((-inner).min(maximum))], 2.0 * radius)?;
      }
      if maximum > inner {
        segment(svg, [point(inner.max(minimum)), point(maximum)], 2.0 * radius)?;
      }
    }
    return Ok(true);
  }
  Ok(false)
}

fn ring(path: &mut String, [x, y]: Point, radius: f64) -> Result<(), Error> {
  require(
    [x - radius, x + radius, y, radius].into_iter().all(f64::is_finite),
    "SVG circle bounds must be finite",
  )?;
  write!(
    path,
    "M{} {y}A{radius} {radius} 0 1 0 {} {y}A{radius} {radius} 0 1 0 {} {y}Z",
    x + radius,
    x - radius,
    x + radius
  )
  .map_err(format_error)
}

fn rectangle(path: &mut String, [xmin, xmax, ymin, ymax]: [f64; 4]) -> Result<(), Error> {
  polygon(path, &[[xmin, ymin], [xmax, ymin], [xmax, ymax], [xmin, ymax]])
}

fn polygon(path: &mut String, points: &[Point]) -> Result<(), Error> {
  require(
    points.iter().flatten().all(|v| v.is_finite()),
    "SVG polygon coordinates must be finite",
  )?;
  if points.len() < 3 {
    return Ok(());
  }
  for (index, point) in points.iter().enumerate() {
    write!(path, "{}{} {}", if index == 0 { "M" } else { "L" }, point[0], point[1]).map_err(format_error)?;
  }
  path.push('Z');
  Ok(())
}

struct Contour<'a, 'b> {
  overlay: &'a PreparedOverlay<'a>,
  index: usize,
  source: &'a Source,
  grid: &'a Grid,
  radius: f64,
  tolerance: f64,
  budget: &'b mut u64,
  path: String,
}

impl Contour<'_, '_> {
  fn value(&mut self, [u, v]: Point) -> Result<f64, Error> {
    *self.budget = self
      .budget
      .checked_sub(self.overlay.field.source_geometry_cost(self.index) as u64)
      .ok_or_else(|| {
        Error::Invalid(
          "vector mask exceeds one billion geometry evaluations; simplify the model or increase mask thickness".into(),
        )
      })?;
    let world = self.grid.plane.position(u, v);
    require(finite(world), "vector mask coordinates must be finite")?;
    let distance = self
      .overlay
      .field
      .source_distance(self.index, self.source, world, false);
    require(distance.is_finite(), "vector mask distance must be finite")?;
    Ok(distance - self.radius)
  }

  fn cell(&mut self, bounds: [f64; 4], depth: u32) -> Result<(), Error> {
    let [xmin, xmax, ymin, ymax] = bounds;
    let middle = [xmin * 0.5 + xmax * 0.5, ymin * 0.5 + ymax * 0.5];
    let diagonal = (xmax - xmin).hypot(ymax - ymin) * 0.5;
    let value = self.value(middle)?;
    // Distance to a closed source is 1-Lipschitz: whole tiles can be accepted or skipped.
    if value > diagonal {
      return Ok(());
    }
    if value < -diagonal {
      return rectangle(&mut self.path, bounds);
    }
    if diagonal > self.tolerance {
      require(
        depth < 20,
        "vector mask requires more than 20 subdivision levels; increase mask thickness",
      )?;
      for tile in [
        [xmin, middle[0], ymin, middle[1]],
        [middle[0], xmax, ymin, middle[1]],
        [xmin, middle[0], middle[1], ymax],
        [middle[0], xmax, middle[1], ymax],
      ] {
        self.cell(tile, depth + 1)?;
      }
      return Ok(());
    }
    let corners = [[xmin, ymin], [xmax, ymin], [xmax, ymax], [xmin, ymax]];
    let mut values = [0.0; 4];
    for (i, corner) in corners.iter().enumerate() {
      values[i] = self.value(*corner)?;
    }
    // Four center-connected triangles resolve ambiguous saddle cells consistently.
    for index in 0..4 {
      let next = (index + 1) % 4;
      let points = [middle, corners[index], corners[next]];
      let values = [value, values[index], values[next]];
      let mut clipped = Vec::with_capacity(4);
      for i in 0..3 {
        let j = (i + 1) % 3;
        if values[i] <= 0.0 {
          clipped.push(points[i]);
        }
        if (values[i] <= 0.0) != (values[j] <= 0.0) {
          let t = values[i] / (values[i] - values[j]);
          clipped.push(std::array::from_fn(|axis| {
            (1.0 - t) * points[i][axis] + t * points[j][axis]
          }));
        }
      }
      polygon(&mut self.path, &clipped)?;
    }
    require(self.path.len() <= 32 * 1024 * 1024, "vector mask path exceeds 32 MiB")?;
    Ok(())
  }
}

fn format_error(_: std::fmt::Error) -> Error {
  Error::Numerical("SVG formatting failed")
}

fn section_radius(radius: f64, distance: f64) -> f64 {
  let fraction = distance / radius;
  radius * ((1.0 - fraction) * (1.0 + fraction)).sqrt()
}
