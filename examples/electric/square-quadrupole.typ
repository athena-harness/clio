// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors

  #example-panel(
    [Square quadrupole],
    sources-for("square-quadrupole"),
    grid: grid-for("square-quadrupole"),
    description: [Alternating charges at the corners of a square.],
    formula: [$sum q_i = 0, quad sum q_i bold(r)_i = bold(0)$],
    color: magnitude-colors(maximum: 8),
    note: [Both total charge and dipole moment vanish; the central field is zero
      by symmetry.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "square-quadrupole",
    [Square quadrupole lines],
    (seed-circle((-0.6, -0.6), count: 18), seed-circle((0.6, 0.6), count: 18)),
    description: [Two positive corners feed the two negative corners.],
    formula: [$sum q_i = 0, quad sum q_i bold(r)_i = bold(0)$],
    note: [This uses the same four charges as the heatmap. The central
      cancellation point terminates nearby trajectories.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = (
    sphere-seeds((-0.6, -0.6, 0), count: 8)
      + sphere-seeds((0.6, 0.6, 0), count: 8)
  )
  #spatial-panel(
    [Square quadrupole: spatial field],
    sources-for("square-quadrupole"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("square-quadrupole"),
    source-colors: ("#dc5043", "#dc5043", "#3769be", "#3769be"),
    note: [Positive and negative corners share the same source array as both
      planar views.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Square quadrupole],
  heatmap,
  field-lines,
  spatial: spatial,
)
