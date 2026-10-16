// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors

  #example-panel(
    [Two equal positive charges],
    sources-for("like-charges"),
    grid: grid-for("like-charges"),
    description: [Vector cancellation creates a field null at the midpoint.],
    formula: [$q_1 = q_2 = +1, quad x_1 = -0.7, quad x_2 = +0.7$],
    color: magnitude-colors(maximum: 8),
    note: [The central minimum comes from adding vectors before taking their
      magnitude.],
  )

]

#let field-lines() = [
  #import "models.typ": sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, example-tracing
  #import "line-common.typ": line-field, line-grid-for, line-overlay

  #let line-grid = line-grid-for("like-charges")
  #let sources = sources-for("like-charges")
  #example-panel(
    [Two positive charges],
    sources,
    grid: line-grid,
    description: [Field lines bend away from the central cancellation region.],
    formula: [$q_1 = q_2 = +1, quad N_"seeds" = 36$],
    note: [Each charge has its own seed circle. Curves terminate at the bounds,
      sources, nulls, or the step limit.],
    legend: false,
    plot: electric-field-lines(
      sources,
      (seed-circle((-0.7, 0), count: 18), seed-circle((0.7, 0), count: 18)),
      grid: line-grid,
      field: line-field,
      tracing: example-tracing(),
      source-overlay: line-overlay,
    ),
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = sphere-seeds((-0.7, 0, 0)) + sphere-seeds((0.7, 0, 0))
  #spatial-panel(
    [Like charges: spatial field],
    sources-for("like-charges"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("like-charges"),
    source-colors: ("#dc5043",),
    note: [Positive charges emit into space; the observation slice is one
      symmetry plane.],
  )
]

#import "common.typ": object-example

#context object-example([Like charges], heatmap, field-lines, spatial: spatial)
