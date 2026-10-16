// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, line-sampling, magnitude-colors

  #example-panel(
    [Finite uniform line charge],
    sources-for("finite-line"),
    grid: grid-for("finite-line"),
    description: [A straight rod with prescribed uniform linear density.],
    formula: [$lambda = 1, quad L = 2.2$],
    color: magnitude-colors(maximum: 16),
    note: [Near the rod the transverse field dominates; far away it approaches a
      point-source pattern.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "finite-line",
    [Finite line-charge field lines],
    (
      seed-segment((-1, 0.14), (1, 0.14), count: 13),
      seed-segment((-1, -0.14), (1, -0.14), count: 13),
    ),
    description: [Seeds on both sides show transverse fields and end effects.],
    formula: [$lambda = 1, quad L = 2.2$],
    note: [Source length, linear density, and quadrature match the finite-rod
      heatmap. The end trajectories curve outward.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for x in (-0.8, 0, 0.8) {
      for i in range(4) {
        let angle = i * calc.pi / 2 + calc.pi / 4
        result.push((x, 0.18 * calc.cos(angle), 0.18 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Finite line: spatial field],
    sources-for("finite-line"),
    seeds,
    color: magnitude-colors(maximum: 16),
    observation: grid-for("finite-line"),
    source-colors: ("#a78bfa99",),
    note: [The finite rod emits around its full circumference, including outside
      the slice.],
  )
]

#import "common.typ": object-example

#context object-example([Finite line], heatmap, field-lines, spatial: spatial)
