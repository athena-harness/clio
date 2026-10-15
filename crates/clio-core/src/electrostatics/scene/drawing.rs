//! Bounded vector primitives with approximate back-to-front transparency.

use super::{inside, sources, Projection, Request, SpatialLine};
use crate::{
  electrostatics::ElectricField,
  geometry::{add, dot, mul, norm, Vector},
  render::{color::PreparedScale, heatmap::Sampling, svg},
  require, Error,
};
use std::fmt::Write;

enum Shape {
  Polygon(Vec<Vector>, bool),
  Segment([Vector; 2], f64, Option<usize>),
  Point(Vector, f64),
}

struct Primitive {
  depth: f64,
  shape: Shape,
  color: [u8; 4],
}

pub(super) struct Canvas<'a> {
  projection: &'a Projection,
  pub bounds: [Vector; 2],
  primitives: Vec<Primitive>,
}

impl Canvas<'_> {
  fn push(&mut self, shape: Shape, color: [u8; 4], depth: f64) -> Result<(), Error> {
    require(
      self.primitives.len() < 262_144,
      "scene exceeds 262144 vector primitives; reduce slice, source, or tracing detail",
    )?;
    self.primitives.push(Primitive { shape, color, depth });
    Ok(())
  }

  pub fn polygon(&mut self, points: &[Vector], color: [u8; 4]) -> Result<(), Error> {
    if color[3] == 0 {
      return Ok(());
    }
    let mut clipped = points.to_vec();
    // Clip before projection so every displayed fragment lies in the physical scene box.
    for axis in 0..3 {
      for side in 0..2 {
        let input = std::mem::take(&mut clipped);
        if input.len() < 3 {
          return Ok(());
        }
        let edge = self.bounds[side][axis];
        let within = |p: Vector| if side == 0 { p[axis] >= edge } else { p[axis] <= edge };
        for (&a, &b) in input.iter().zip(input.iter().cycle().skip(1)).take(input.len()) {
          if within(a) {
            clipped.push(a);
          }
          if within(a) != within(b) {
            let t = (edge - a[axis]) / (b[axis] - a[axis]);
            clipped.push(add(mul(a, 1.0 - t), mul(b, t)));
          }
        }
      }
    }
    if clipped.len() < 3 {
      return Ok(());
    }
    let points = clipped
      .iter()
      .map(|&p| self.projection.point(p))
      .collect::<Result<Vec<_>, _>>()?;
    let depth = points.iter().map(|p| p[2] / points.len() as f64).sum();
    self.push(Shape::Polygon(points, true), color, depth)
  }

  pub fn segment(&mut self, points: [Vector; 2], color: [u8; 4], width: f64, line: Option<usize>) -> Result<(), Error> {
    let Some(points) = clip_segment(points, self.bounds) else {
      return Ok(());
    };
    let points = [self.projection.point(points[0])?, self.projection.point(points[1])?];
    let depth = points[0][2] * 0.5 + points[1][2] * 0.5;
    self.push(Shape::Segment(points, width, line), color, depth)
  }

  pub fn point(&mut self, point: Vector, color: [u8; 4], radius: f64) -> Result<(), Error> {
    if !inside(point, self.bounds) {
      return Ok(());
    }
    let p = self.projection.point(point)?;
    self.push(Shape::Point(p, radius), color, p[2])
  }

  pub fn arrow(&mut self, points: [Vector; 2], color: [u8; 4], size: f64) -> Result<(), Error> {
    let [a, b] = points;
    let length = (b[0] - a[0]).hypot(b[1] - a[1]);
    if length <= 1e-8 || size == 0.0 {
      return Ok(());
    }
    let u = [(b[0] - a[0]) / length, (b[1] - a[1]) / length];
    let base = [b[0] - size * u[0], b[1] - size * u[1]];
    self.push(
      Shape::Polygon(
        vec![
          b,
          [base[0] - 0.4 * size * u[1], base[1] + 0.4 * size * u[0], b[2]],
          [base[0] + 0.4 * size * u[1], base[1] - 0.4 * size * u[0], b[2]],
        ],
        false,
      ),
      color,
      b[2],
    )
  }
}

fn clip_segment([a, b]: [Vector; 2], bounds: [Vector; 2]) -> Option<[Vector; 2]> {
  let mut low: f64 = 0.0;
  let mut high: f64 = 1.0;
  for i in 0..3 {
    let delta = b[i] - a[i];
    if delta == 0.0 {
      if a[i] < bounds[0][i] || a[i] > bounds[1][i] {
        return None;
      }
    } else {
      let t0 = (bounds[0][i] - a[i]) / delta;
      let t1 = (bounds[1][i] - a[i]) / delta;
      low = low.max(t0.min(t1));
      high = high.min(t0.max(t1));
    }
  }
  if low > high {
    return None;
  }
  Some([
    add(mul(a, 1.0 - low), mul(b, low)),
    add(mul(a, 1.0 - high), mul(b, high)),
  ])
}

pub(super) fn render(
  request: &Request,
  field: &ElectricField,
  projection: &Projection,
  lines: &[SpatialLine],
) -> Result<Vec<u8>, Error> {
  let mut canvas = Canvas {
    projection,
    bounds: request.scene.bounds,
    primitives: Vec::new(),
  };
  sources::draw(&mut canvas, request, field)?;
  slice(&mut canvas, request, field)?;
  if let Some(config) = &request.scene.lines {
    let style = &config.style;
    let color = style.validate()?;
    for (index, line) in lines.iter().enumerate() {
      let mut travelled = 0.0;
      let mut target = style.arrow_spacing.unwrap_or(f64::INFINITY) / 2.0;
      for pair in line.points.windows(2) {
        canvas.segment([pair[0], pair[1]], color, style.width, Some(index))?;
        let a = projection.point(pair[0])?;
        let b = projection.point(pair[1])?;
        let distance = (b[0] - a[0]).hypot(b[1] - a[1]);
        if distance > 0.0 && style.arrow_size > 0.0 {
          while target <= travelled + distance {
            let t = (target - travelled) / distance;
            let tip = add(mul(a, 1.0 - t), mul(b, t));
            canvas.arrow([a, tip], color, style.arrow_size)?;
            target += style.arrow_spacing.unwrap_or(f64::INFINITY);
          }
        }
        travelled += distance;
      }
    }
  }
  canvas.primitives.sort_by(|a, b| a.depth.total_cmp(&b.depth));
  let mut document = svg::begin(request.scene.resolution);
  for (index, line) in lines.iter().enumerate() {
    write!(
      document,
      "<g data-spatial-line=\"{index}\" data-start-termination=\"{}\" data-end-termination=\"{}\"/>",
      line.start.name(),
      line.end.name()
    )
    .map_err(format_error)?;
  }
  for primitive in canvas.primitives {
    let color = svg::hex(primitive.color);
    let alpha = f64::from(primitive.color[3]) / 255.0;
    match primitive.shape {
      Shape::Polygon(points, tiled) => {
        // Adjacent transparent tiles must not expose anti-aliasing seams between faces.
        let edges = if tiled { "crispEdges" } else { "geometricPrecision" };
        write!(
          document,
          "<polygon shape-rendering=\"{edges}\" fill=\"{color}\" fill-opacity=\"{alpha}\" points=\""
        )
        .map_err(format_error)?;
        for p in points {
          write!(document, "{:.3},{:.3} ", p[0], p[1]).map_err(format_error)?;
        }
        document.push_str("\"/>");
      }
      Shape::Segment([a, b], width, line) => {
        write!(document,"<path stroke=\"{color}\" stroke-opacity=\"{alpha}\" stroke-width=\"{width}\" stroke-linecap=\"round\" d=\"M{:.3} {:.3}L{:.3} {:.3}\"",a[0],a[1],b[0],b[1]).map_err(format_error)?;
        if let Some(index) = line {
          write!(document, " data-line=\"{index}\"").map_err(format_error)?;
        }
        document.push_str("/>");
      }
      Shape::Point(p, radius) => {
        write!(
          document,
          "<circle cx=\"{:.3}\" cy=\"{:.3}\" r=\"{radius}\" fill=\"{color}\" fill-opacity=\"{alpha}\"/>",
          p[0], p[1]
        )
        .map_err(format_error)?;
      }
    }
    require(document.len() <= 64 * 1024 * 1024, "scene SVG exceeds 64 MiB")?;
  }
  if request.scene.axes {
    axes(&mut document, request, projection)?;
  }
  Ok(svg::finish(document))
}

fn slice(canvas: &mut Canvas<'_>, request: &Request, field: &ElectricField) -> Result<(), Error> {
  let Some(slice) = &request.scene.slice else {
    return Ok(());
  };
  require(
    slice.opacity.is_finite() && (0.0..=1.0).contains(&slice.opacity),
    "scene slice opacity must be between 0 and 1",
  )?;
  let pixels = u64::from(slice.samples[0]) * u64::from(slice.samples[1]);
  require(
    slice.samples.iter().all(|&v| v > 0) && pixels <= 65_536,
    "scene slice requires between 1 and 65536 tiles",
  )?;
  require(
    pixels * field.evaluation_count() as u64 <= 1_000_000_000,
    "scene slice exceeds one billion field evaluations",
  )?;
  let scale = slice.color.as_ref().map(PreparedScale::new).transpose()?;
  let mut grid = request.grid.clone();
  grid.resolution = slice.samples;
  grid.sampling = Sampling::Centers;
  let [nx, ny] = slice.samples;
  let [xmin, xmax, ymin, ymax] = grid.bounds;
  for row in 0..ny {
    for column in 0..nx {
      let a = [
        xmin + f64::from(column) / f64::from(nx) * (xmax - xmin),
        ymin + f64::from(row) / f64::from(ny) * (ymax - ymin),
      ];
      let b = [
        xmin + f64::from(column + 1) / f64::from(nx) * (xmax - xmin),
        ymin + f64::from(row + 1) / f64::from(ny) * (ymax - ymin),
      ];
      let points = [[a[0], a[1]], [b[0], a[1]], [b[0], b[1]], [a[0], b[1]]].map(|p| grid.plane.position(p[0], p[1]));
      let mut color = if let Some(scale) = &scale {
        let center = grid.plane.position(a[0] * 0.5 + b[0] * 0.5, a[1] * 0.5 + b[1] * 0.5);
        let Some(vector) = field.at(center)? else { continue };
        let magnitude = norm(vector);
        require(magnitude.is_finite(), "scene slice magnitude must remain finite")?;
        scale.rgba(scale.normalize(magnitude))
      } else {
        [125, 180, 224, 255]
      };
      color[3] = (f64::from(color[3]) * slice.opacity).round() as u8;
      canvas.polygon(&points, color)?;
    }
  }
  let corners = [[xmin, ymin], [xmax, ymin], [xmax, ymax], [xmin, ymax]].map(|p| grid.plane.position(p[0], p[1]));
  for i in 0..4 {
    canvas.segment([corners[i], corners[(i + 1) % 4]], [59, 130, 180, 180], 0.7, None)?;
  }
  if request.scene.axes {
    let start = grid.plane.position((xmin + xmax) / 2.0, (ymin + ymax) / 2.0);
    let end = add(start, mul(grid.plane.normal(), request.scene.camera.span * 0.12));
    if let Some([a, b]) = clip_segment([start, end], canvas.bounds) {
      canvas.segment([a, b], [37, 99, 170, 255], 1.1, None)?;
      canvas.arrow(
        [canvas.projection.point(a)?, canvas.projection.point(b)?],
        [37, 99, 170, 255],
        5.0,
      )?;
    }
  }
  Ok(())
}

fn axes(document: &mut String, request: &Request, projection: &Projection) -> Result<(), Error> {
  let anchor = [42.0, f64::from(request.scene.resolution[1]) - 40.0];
  for (axis, label, color) in [(0, "x", "#c2413b"), (1, "y", "#168453"), (2, "z", "#2563b8")] {
    let mut direction = [0.0; 3];
    direction[axis] = 1.0;
    let tip = [
      anchor[0] + 27.0 * dot(direction, projection.right),
      anchor[1] - 27.0 * dot(direction, projection.up),
    ];
    write!(document,"<path d=\"M{} {}L{} {}\" stroke=\"{color}\" stroke-width=\"1.4\"/><text x=\"{}\" y=\"{}\" fill=\"{color}\" font-size=\"11\" font-family=\"sans-serif\">{label}</text>", anchor[0],anchor[1],tip[0],tip[1],tip[0]+3.0,tip[1]-3.0).map_err(format_error)?;
  }
  Ok(())
}

fn format_error(_: std::fmt::Error) -> Error {
  Error::Numerical("spatial SVG formatting failed")
}
