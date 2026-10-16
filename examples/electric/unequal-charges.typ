// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors

  #example-panel(
    [Unequal opposite charges],
    sources-for("unequal-charges"),
    grid: grid-for("unequal-charges"),
    description: [An asymmetric pair with net positive charge.],
    formula: [$q_1 = +2, quad q_2 = -1$],
    color: magnitude-colors(maximum: 8),
    note: [Unlike a neutral dipole, this pair retains a monopole contribution at
      large distances.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "unequal-charges",
    [Unequal opposite charges],
    (seed-circle((-0.6, 0), count: 32, phase: 0.05),),
    description: [A stronger positive source feeds a weaker negative sink.],
    formula: [$q_1 = +2, quad q_2 = -1$],
    note: [Some curves reach the negative charge; others leave the viewport.
      Seed counts do not measure electric flux.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = sphere-seeds((-0.6, 0, 0), count: 16)
  #spatial-panel(
    [Unequal charges: spatial field],
    sources-for("unequal-charges"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("unequal-charges"),
    source-colors: ("#dc5043", "#3769be"),
    note: [Some curves reach the negative charge; others leave the spatial box.
      Seed counts do not calibrate flux.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Unequal charges],
  heatmap,
  field-lines,
  spatial: spatial,
)
