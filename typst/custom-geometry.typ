// Custom models remain data; expression evaluation and geometric integration run in Rust.
#let parametric-source(position, bounds, density, samples, constants) = (
  kind: "parametric",
  position: position,
  bounds: bounds,
  density: density,
  samples: samples,
  constants: constants,
)

/// Describe a charged curve r(t); density is charge per physical arc length.
#let charged-curve(
  position,
  range: (0, 1),
  density: 1,
  samples: 64,
  constants: (:),
) = parametric-source(
  position,
  (range,),
  density,
  (samples,),
  constants,
)

/// Describe a charged surface r(u,v); density is charge per physical area.
#let charged-surface(
  position,
  bounds: ((0, 1), (0, 1)),
  density: 1,
  samples: (24, 24),
  constants: (:),
) = parametric-source(position, bounds, density, samples, constants)

/// Describe a charged volume r(u,v,w); density is charge per physical volume.
#let charged-volume(
  position,
  bounds: ((0, 1), (0, 1), (0, 1)),
  density: 1,
  samples: (8, 8, 8),
  constants: (:),
) = parametric-source(position, bounds, density, samples, constants)

/// Describe an indexed triangle surface with uniform or per-face charge density.
#let charged-triangle-mesh(vertices, faces, density: 1, samples: 4) = (
  kind: "triangle-mesh",
  vertices: vertices,
  faces: faces,
  density: density,
  samples: samples,
)
