//! User-defined charged parameter domains and triangle meshes.

use super::point_charges::PointCharge;
use crate::{
  expression::{Compiled, Expression},
  geometry::{add, cross, dot, finite, mul, norm, sub, Vector},
  require, Error,
};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// A curve, surface, or volume mapped from a finite rectangular parameter domain.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct Parametric {
  /// Three world-coordinate expressions; parameters are t, (u,v), or (u,v,w).
  pub position: [Expression; 3],
  /// One to three strictly increasing parameter intervals.
  pub bounds: Vec<[f64; 2]>,
  /// Signed charge per physical length, area, or volume, evaluated in parameter space.
  pub density: Expression,
  /// Positive midpoint counts, one for each parameter axis.
  pub samples: Vec<u32>,
  /// Finite named constants substituted before expression evaluation.
  #[serde(default)]
  pub constants: BTreeMap<String, f64>,
}

/// Uniform density or one signed surface density for each triangle.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum MeshDensity {
  /// Uniform charge per unit area.
  Uniform(f64),
  /// Surface density for each face in input order.
  Faces(Vec<f64>),
}

/// An indexed triangle surface, including open or disconnected meshes.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct TriangleMesh {
  /// Finite world-space vertex positions.
  pub vertices: Vec<Vector>,
  /// Zero-based vertex indices for every nondegenerate triangle.
  pub faces: Vec<[usize; 3]>,
  /// Uniform or per-face signed charge per unit area.
  pub density: MeshDensity,
  /// Edge subdivision count; each face generates samples squared quadrature nodes.
  pub samples: u32,
}

pub(crate) struct Prepared {
  pub nodes: Vec<PointCharge>,
  pub cells: Vec<Cell>,
}

pub(crate) struct Cell {
  pub shape: Shape,
  pub charged: bool,
}

pub(crate) enum Shape {
  Segment([Vector; 2]),
  Triangle([Vector; 3]),
  Tetrahedron([Vector; 4]),
}

impl Parametric {
  pub(crate) fn prepare(&self, budget: &mut u64) -> Result<Prepared, Error> {
    let dimension = self.bounds.len();
    require(
      (1..=3).contains(&dimension) && self.samples.len() == dimension,
      "parametric bounds and samples must have the same dimension between 1 and 3",
    )?;
    let mut count = 1_usize;
    let mut sizes = [1; 3];
    let mut steps = [1.0; 3];
    for axis in 0..dimension {
      let [low, high] = self.bounds[axis];
      require(
        low.is_finite() && high.is_finite() && high > low && (high - low).is_finite(),
        "parameter bounds must be finite and strictly increasing",
      )?;
      require(
        self.samples[axis] > 0 && self.samples[axis] <= 65_536,
        "parameter sample counts must be between 1 and 65536",
      )?;
      sizes[axis] = self.samples[axis] as usize;
      count = count
        .checked_mul(sizes[axis])
        .filter(|&n| n <= 65_536)
        .ok_or_else(|| Error::Invalid("parametric sources must not exceed 65536 integration nodes".into()))?;
      steps[axis] = (high - low) / f64::from(self.samples[axis]);
      require(steps[axis] > 0.0, "parameter step underflow")?;
    }
    require(self.constants.len() <= 64, "provide at most 64 expression constants")?;
    for (name, value) in &self.constants {
      require(
        !name.is_empty()
          && name.len() <= 64
          && name.as_bytes()[0].is_ascii_alphabetic()
          && name.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'_')
          && !["t", "u", "v", "w", "pi", "e"].contains(&name.as_str())
          && value.is_finite(),
        "expression constants require finite values and non-reserved ASCII identifiers",
      )?;
    }
    let names: &[&str] = if dimension == 1 {
      &["t"]
    } else {
      &["u", "v", "w"][..dimension]
    };
    let coordinates = self
      .position
      .iter()
      .map(|e| Compiled::new(e, names, &self.constants))
      .collect::<Result<Vec<_>, _>>()?;
    let density = Compiled::new(&self.density, names, &self.constants)?;
    let vertex_sizes = sizes.map(|n| n + 1);
    let vertex_count = (0..dimension).map(|i| vertex_sizes[i]).product::<usize>();
    let cost = count * (density.cost() + coordinates.iter().map(Compiled::cost).sum::<usize>())
      + vertex_count * coordinates.iter().map(Compiled::cost).sum::<usize>();
    *budget = budget
      .checked_sub(cost as u64)
      .ok_or_else(|| Error::Invalid("parametric preparation exceeds 64 million expression instructions".into()))?;
    let map = |parameters| -> Result<_, Error> {
      let values = coordinates
        .iter()
        .map(|e| e.at(parameters))
        .collect::<Result<Vec<_>, _>>()?;
      Ok((std::array::from_fn::<_, 3, _>(|i| values[i].value), values))
    };
    // Reuse corner positions between neighboring cells for the visual/termination mesh.
    let mut vertices = Vec::with_capacity(vertex_count);
    for index in 0..vertex_count {
      let ijk = indices(index, vertex_sizes, dimension);
      let parameters = std::array::from_fn(|axis| {
        if axis < dimension {
          let [low, high] = self.bounds[axis];
          let fraction = ijk[axis] as f64 / sizes[axis] as f64;
          (1.0 - fraction) * low + fraction * high
        } else {
          0.0
        }
      });
      vertices.push(map(parameters)?.0);
    }
    let mut nodes = Vec::with_capacity(count);
    let mut cells = Vec::new();
    for index in 0..count {
      let ijk = indices(index, sizes, dimension);
      let parameters = std::array::from_fn(|axis| {
        if axis < dimension {
          self.bounds[axis][0] + (ijk[axis] as f64 + 0.5) * steps[axis]
        } else {
          0.0
        }
      });
      let (position, values) = map(parameters)?;
      let derivatives: [Vector; 3] = std::array::from_fn(|axis| std::array::from_fn(|i| values[i].gradient[axis]));
      require(
        derivatives.iter().all(|&v| finite(v)),
        "geometry derivatives must be finite at integration nodes",
      )?;
      let jacobian = match dimension {
        1 => norm(derivatives[0]),
        2 => norm(cross(derivatives[0], derivatives[1])),
        _ => dot(derivatives[0], cross(derivatives[1], derivatives[2])).abs(),
      };
      require(
        jacobian.is_finite() && jacobian > 0.0,
        "parametric mapping must have a positive finite Jacobian at integration nodes",
      )?;
      let charge = density.at(parameters)?.value * jacobian * steps[..dimension].iter().product::<f64>();
      require(charge.is_finite(), "parametric quadrature charge must be finite")?;
      nodes.push(PointCharge { position, charge });
      let mut corners = [[0.0; 3]; 8];
      for (bits, corner) in corners.iter_mut().enumerate().take(1 << dimension) {
        let coordinate = std::array::from_fn::<_, 3, _>(|a| ijk[a] + if a < dimension { (bits >> a) & 1 } else { 0 });
        let vertex = coordinate[0]
          + vertex_sizes[0]
            * (coordinate[1]
              + if dimension == 3 {
                vertex_sizes[1] * coordinate[2]
              } else {
                0
              });
        *corner = vertices[vertex];
      }
      let mut push = |shape| {
        cells.push(Cell {
          shape,
          charged: charge != 0.0,
        })
      };
      match dimension {
        1 => push(Shape::Segment([corners[0], corners[1]])),
        2 => {
          push(Shape::Triangle([corners[0], corners[1], corners[3]]));
          push(Shape::Triangle([corners[0], corners[3], corners[2]]));
        }
        _ => {
          // Six tetrahedra around the 0--7 diagonal cover a parameter cube.
          for [a, b] in [[1, 3], [3, 2], [2, 6], [6, 4], [4, 5], [5, 1]] {
            push(Shape::Tetrahedron([corners[0], corners[a], corners[b], corners[7]]));
          }
        }
      }
    }
    Ok(Prepared { nodes, cells })
  }
}

fn indices(mut index: usize, sizes: [usize; 3], dimension: usize) -> [usize; 3] {
  std::array::from_fn(|axis| {
    if axis < dimension {
      let value = index % sizes[axis];
      index /= sizes[axis];
      value
    } else {
      0
    }
  })
}

impl TriangleMesh {
  pub(crate) fn prepare(&self) -> Result<Prepared, Error> {
    require(
      !self.vertices.is_empty() && self.vertices.len() <= 262_144 && self.vertices.iter().all(|&p| finite(p)),
      "mesh requires between 1 and 262144 finite vertices",
    )?;
    require(
      self.faces.len() <= 65_536 && self.samples <= 256,
      "mesh requires at most 65536 faces and 256 subdivisions per edge",
    )?;
    let count = (self.faces.len() as u64) * u64::from(self.samples) * u64::from(self.samples);
    require(
      !self.faces.is_empty() && self.samples > 0 && count <= 65_536,
      "mesh subdivision requires between 1 and 65536 total integration nodes",
    )?;
    match &self.density {
      MeshDensity::Uniform(d) => require(d.is_finite(), "mesh density must be finite")?,
      MeshDensity::Faces(values) => require(
        values.len() == self.faces.len() && values.iter().all(|d| d.is_finite()),
        "mesh face densities must be finite and match the face count",
      )?,
    }
    let mut nodes = Vec::with_capacity(count as usize);
    let mut cells = Vec::with_capacity(self.faces.len());
    let n = self.samples;
    for (index, face) in self.faces.iter().enumerate() {
      require(
        face.iter().all(|&i| i < self.vertices.len()),
        "mesh face vertex index is out of bounds",
      )?;
      let [a, b, c] = face.map(|i| self.vertices[i]);
      let area = norm(cross(sub(b, a), sub(c, a))) / 2.0;
      require(
        area.is_finite() && area > 0.0,
        "mesh triangles must have positive finite area",
      )?;
      let density = match &self.density {
        MeshDensity::Uniform(d) => *d,
        MeshDensity::Faces(v) => v[index],
      };
      let charge = density * (area / f64::from(n).powi(2));
      require(charge.is_finite(), "mesh quadrature charge must be finite")?;
      for i in 0..n {
        for j in 0..n - i {
          let mut push = |fraction| -> Result<(), Error> {
            let u = (f64::from(i) + fraction) / f64::from(n);
            let v = (f64::from(j) + fraction) / f64::from(n);
            let position = add(mul(a, 1.0 - u - v), add(mul(b, u), mul(c, v)));
            require(finite(position), "mesh quadrature position must be finite")?;
            nodes.push(PointCharge { position, charge });
            Ok(())
          };
          push(1.0 / 3.0)?;
          if i + j + 1 < n {
            push(2.0 / 3.0)?;
          }
        }
      }
      cells.push(Cell {
        shape: Shape::Triangle([a, b, c]),
        charged: density != 0.0,
      });
    }
    Ok(Prepared { nodes, cells })
  }
}

impl Shape {
  pub fn cost(&self) -> usize {
    if matches!(self, Self::Tetrahedron(_)) {
      4
    } else {
      1
    }
  }

  pub fn distance(&self, point: Vector) -> f64 {
    match *self {
      Self::Segment([a, b]) => segment_distance(point, a, b),
      Self::Triangle(vertices) => triangle_distance(point, vertices),
      Self::Tetrahedron([a, b, c, d]) => {
        let delta = sub(point, a);
        let edges = [sub(b, a), sub(c, a), sub(d, a)];
        let determinant = dot(edges[0], cross(edges[1], edges[2]));
        if determinant != 0.0 {
          let u = dot(delta, cross(edges[1], edges[2])) / determinant;
          let v = dot(edges[0], cross(delta, edges[2])) / determinant;
          let w = dot(edges[0], cross(edges[1], delta)) / determinant;
          if u >= 0.0 && v >= 0.0 && w >= 0.0 && u + v + w <= 1.0 {
            return 0.0;
          }
        }
        [[a, b, c], [a, b, d], [a, c, d], [b, c, d]]
          .into_iter()
          .map(|triangle| triangle_distance(point, triangle))
          .fold(f64::INFINITY, f64::min)
      }
    }
  }
}

fn segment_distance(point: Vector, a: Vector, b: Vector) -> f64 {
  let delta = sub(b, a);
  let length = norm(delta);
  if length == 0.0 {
    return norm(sub(point, a));
  }
  let t = (dot(sub(point, a), delta.map(|v| v / length)) / length).clamp(0.0, 1.0);
  norm(sub(point, add(mul(a, 1.0 - t), mul(b, t))))
}

fn triangle_distance(point: Vector, [a, b, c]: [Vector; 3]) -> f64 {
  let ab = sub(b, a);
  let ac = sub(c, a);
  let normal = cross(ab, ac);
  let normal_length = norm(normal);
  if normal_length > 0.0 {
    let normal = normal.map(|v| v / normal_length);
    let sides = [(a, b), (b, c), (c, a)].map(|(p, q)| dot(cross(sub(q, p), sub(point, p)), normal));
    if sides.iter().all(|s| *s >= 0.0) {
      return dot(sub(point, a), normal).abs();
    }
  }
  [(a, b), (b, c), (c, a)]
    .into_iter()
    .map(|(a, b)| segment_distance(point, a, b))
    .fold(f64::INFINITY, f64::min)
}

pub(crate) struct Geometry {
  cells: Vec<Cell>,
  branches: Vec<Branch>,
  cost: usize,
}

struct Branch {
  bounds: [[f64; 3]; 2],
  charged: bool,
  range: std::ops::Range<usize>,
  children: Option<[usize; 2]>,
}

impl Geometry {
  pub fn cells(&self) -> &[Cell] {
    &self.cells
  }

  pub fn new(cells: Vec<Cell>) -> Self {
    let cost = cells.iter().map(|cell| cell.shape.cost()).sum();
    let length = cells.len();
    let mut geometry = Self {
      cells,
      branches: Vec::new(),
      cost,
    };
    geometry.build(0..length);
    geometry
  }

  pub fn cost(&self) -> usize {
    self.cost
  }

  fn build(&mut self, range: std::ops::Range<usize>) -> usize {
    let mut bounds = [[f64::INFINITY; 3], [f64::NEG_INFINITY; 3]];
    let mut charged = false;
    for cell in &self.cells[range.clone()] {
      charged |= cell.charged;
      for point in cell.shape.vertices() {
        for axis in 0..3 {
          bounds[0][axis] = bounds[0][axis].min(point[axis]);
          bounds[1][axis] = bounds[1][axis].max(point[axis]);
        }
      }
    }
    let index = self.branches.len();
    self.branches.push(Branch {
      bounds,
      charged,
      range: range.clone(),
      children: None,
    });
    if range.len() > 8 {
      let mut axis = 0;
      for candidate in 1..3 {
        if bounds[1][candidate] - bounds[0][candidate] > bounds[1][axis] - bounds[0][axis] {
          axis = candidate;
        }
      }
      let middle = range.start + range.len() / 2;
      let center = |cell: &Cell| {
        let mut low = f64::INFINITY;
        let mut high = f64::NEG_INFINITY;
        for vertex in cell.shape.vertices() {
          low = low.min(vertex[axis]);
          high = high.max(vertex[axis]);
        }
        low * 0.5 + high * 0.5
      };
      self.cells[range.clone()].select_nth_unstable_by(range.len() / 2, |a, b| center(a).total_cmp(&center(b)));
      let children = [self.build(range.start..middle), self.build(middle..range.end)];
      self.branches[index].children = Some(children);
    }
    index
  }

  pub fn distance(&self, point: Vector, charged_only: bool) -> f64 {
    let mut best = f64::INFINITY;
    self.visit(0, point, charged_only, &mut best);
    best
  }

  fn visit(&self, index: usize, point: Vector, charged_only: bool, best: &mut f64) {
    let branch = &self.branches[index];
    if (charged_only && !branch.charged) || box_distance(branch.bounds, point) >= *best {
      return;
    }
    if let Some([a, b]) = branch.children {
      let order = if box_distance(self.branches[a].bounds, point) <= box_distance(self.branches[b].bounds, point) {
        [a, b]
      } else {
        [b, a]
      };
      for child in order {
        self.visit(child, point, charged_only, best);
      }
    } else {
      for cell in &self.cells[branch.range.clone()] {
        if !charged_only || cell.charged {
          *best = best.min(cell.shape.distance(point));
        }
        if *best == 0.0 {
          break;
        }
      }
    }
  }
}

impl Shape {
  fn vertices(&self) -> &[Vector] {
    match self {
      Self::Segment(vertices) => vertices,
      Self::Triangle(vertices) => vertices,
      Self::Tetrahedron(vertices) => vertices,
    }
  }
}

fn box_distance(bounds: [[f64; 3]; 2], point: Vector) -> f64 {
  norm(std::array::from_fn(|i| {
    (bounds[0][i] - point[i]).max(0.0).max(point[i] - bounds[1][i])
  }))
}
