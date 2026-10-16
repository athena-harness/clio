// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors

  #example-panel(
    [Axial quadrupole],
    sources-for("axial-quadrupole"),
    grid: grid-for("axial-quadrupole"),
    description: [Three collinear charges with no monopole or dipole moment.],
    formula: [$q = (+1, -2, +1), quad x = (-0.8, 0, +0.8)$],
    color: magnitude-colors(maximum: 10),
    note: [A different quadrupole geometry with an angular pattern distinct from
      the square arrangement.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "axial-quadrupole",
    [Axial quadrupole lines],
    (seed-circle((-0.8, 0), count: 18), seed-circle((0.8, 0), count: 18)),
    description: [Two positive outer charges feed a negative central charge.],
    formula: [$q = (+1, -2, +1), quad x = (-0.8, 0, +0.8)$],
    note: [Both positive sources are seeded. Arrow direction follows the vector
      sum of all three charges.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = (
    sphere-seeds((-0.8, 0, 0), count: 8) + sphere-seeds((0.8, 0, 0), count: 8)
  )
  #spatial-panel(
    [Axial quadrupole: spatial field],
    sources-for("axial-quadrupole"),
    seeds,
    color: magnitude-colors(maximum: 10),
    observation: grid-for("axial-quadrupole"),
    source-colors: ("#dc5043", "#3769be", "#dc5043"),
    note: [Spatial curves surround the charge axis and follow the full vector
      field.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Axial quadrupole],
  heatmap,
  field-lines,
  spatial: spatial,
)
