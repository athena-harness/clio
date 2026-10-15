#import "../../lib.typ": *
#import "common.typ": example-tracing, integration-detail, xy-grid

// Custom and built-in sources share one array and one physical field evaluator.
#let custom-models = (
  "charged-arc": (
    sources: (
      charged-curve(
        ("a*cos(t)", "b*sin(t)", 0),
        range: (0.15 * calc.pi, 1.85 * calc.pi),
        density: "1 + 0.4*cos(2*t)",
        samples: 128 * integration-detail,
        constants: (a: 1.1, b: 0.8),
      ),
      point-charge((0.1, 0, 0), charge: -1.5),
    ),
    grid: xy-grid(),
    seeds: (seed-circle((0.1, 0), radius: 0.18, count: 24),),
    tracing: example-tracing(max-steps: 800),
    title: [Nonuniform elliptical arc],
    description: [A parameterized line charge and a built-in negative point
      charge.],
    formula: [$lambda(t) = 1 + 0.4 cos(2t)$],
    note: [Rust evaluates the curve and arc-length Jacobian; the opening is part
      of the parameter range.],
  ),
  "warped-surface": (
    sources: (
      charged-surface(
        ("0.25*(u^2-v^2)-0.65", "u", "v"),
        bounds: ((-0.85, 0.85), (-0.85, 0.85)),
        density: "1 + 0.3*u",
        samples: (16 * integration-detail, 16 * integration-detail),
      ),
      charged-segment(
        (1, -0.9, 0),
        (1, 0.9, 0),
        density: -1,
        samples: 64 * integration-detail,
      ),
    ),
    grid: xy-grid(),
    seeds: (seed-segment((0, -1.2), (0, 1.2), count: 24),),
    tracing: example-tracing(max-steps: 800),
    title: [Saddle surface and finite rod],
    description: [A curved nonuniform sheet interacts with a built-in line
      charge.],
    formula: [$x = (u^2-v^2)/4 - 0.65$],
    note: [Reflection symmetry about z = 0 makes the observation plane
      compatible with planar tracing.],
  ),
  "charged-volume": (
    sources: (
      charged-volume(
        ("0.55*u-0.6", "0.65*v", "0.45*w"),
        bounds: ((-1, 1), (-1, 1), (-1, 1)),
        density: "1 + 0.5*u",
        samples: (
          6 * integration-detail,
          6 * integration-detail,
          6 * integration-detail,
        ),
      ),
      charged-disk(
        0.7,
        density: -0.7,
        plane: field-plane(
          origin: (0.9, 0, 0),
          horizontal: (0, 1, 0),
          vertical: (0, 0, 1),
        ),
        radial-samples: 12 * integration-detail,
        angular-samples: 32 * integration-detail,
      ),
    ),
    grid: xy-grid(),
    seeds: (seed-segment((0.2, -1.2), (0.2, 1.2), count: 24),),
    tracing: example-tracing(max-steps: 800),
    title: [Nonuniform volume and disk],
    description: [A volume charge combines with an unchanged disk constructor.],
    formula: [$rho(u, v, w) = 1 + 0.5u$],
    note: [The volume mask marks its filled cross-section. Tracing stops at
      charged volume cells.],
  ),
  "triangle-mesh": (
    sources: (
      charged-triangle-mesh(
        ((-1, -0.8, 0), (-1, 0.8, 0), (0.1, 0, 0.75), (0.1, 0, -0.75)),
        ((0, 1, 2), (1, 0, 3)),
        density: (1, 1),
        samples: 10 * integration-detail,
      ),
      charged-annulus(
        0.2,
        0.8,
        density: -1,
        plane: field-plane(
          origin: (0.9, 0, 0),
          horizontal: (0, 1, 0),
          vertical: (0, 0, 1),
        ),
        radial-samples: 12 * integration-detail,
        angular-samples: 32 * integration-detail,
      ),
    ),
    grid: xy-grid(),
    seeds: (seed-segment((0.3, -1.2), (0.3, 1.2), count: 24),),
    tracing: example-tracing(max-steps: 800),
    title: [Folded triangle mesh and annulus],
    description: [An open indexed mesh combines with a built-in annular
      source.],
    formula: [$sigma_1 = sigma_2 = 1$],
    note: [Each face is subdivided in Rust. Mesh charge is per surface area,
      independent of winding.],
  ),
)
