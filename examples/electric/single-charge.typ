// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors

  #example-panel(
    [Single point charge],
    sources-for("single-charge"),
    grid: grid-for("single-charge"),
    description: [A positive charge observed in the xy plane through the
      source.],
    formula: [$q = +1, quad bold(r)_q = (0, 0, 0)$],
    color: magnitude-colors(maximum: 6),
    note: [Radial symmetry and inverse-square decay away from the softened
      core.],
  )

]

#let field-lines() = [
  #import "models.typ": sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, example-tracing
  #import "line-common.typ": line-field, line-grid-for, line-overlay

  #let line-grid = line-grid-for("single-charge")
  #let sources = sources-for("single-charge")
  #example-panel(
    [Radial field lines],
    sources,
    grid: line-grid,
    description: [A positive point charge emits radial electric-field lines.],
    formula: [$q = +1, quad N_"seeds" = 24$],
    note: [Circle seeds are generated in Rust. Joined forward and backward
      branches share the physical arrow direction.],
    legend: false,
    plot: electric-field-lines(
      sources,
      (seed-circle((0, 0), count: 24),),
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

  #let seeds = sphere-seeds((0, 0, 0), count: 16)
  #spatial-panel(
    [Single charge: spatial field],
    sources-for("single-charge"),
    seeds,
    color: magnitude-colors(maximum: 6),
    observation: grid-for("single-charge"),
    source-colors: ("#dc5043",),
    note: [A sphere of seeds reveals radial emission in all spatial
      directions.],
  )
]

#import "common.typ": object-example

#context object-example([Single charge], heatmap, field-lines, spatial: spatial)
