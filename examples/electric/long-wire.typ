// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, line-sampling, magnitude-colors

  #example-panel(
    [Long-wire approximation],
    sources-for("long-wire"),
    grid: grid-for("long-wire"),
    description: [The central region of a long, finite charged wire.],
    formula: [$lambda = 1, quad L = 16$],
    color: magnitude-colors(maximum: 16),
    note: [The model remains finite. Its central field approximates that of an
      infinite line away from the core.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "long-wire",
    [Long-wire field lines],
    (
      seed-segment((-1.8, 0.14), (1.8, 0.14), count: 13),
      seed-segment((-1.8, -0.14), (1.8, -0.14), count: 13),
    ),
    description: [The central field is nearly perpendicular to the long wire.],
    formula: [$lambda = 1, quad L = 16$],
    note: [The actual source extends beyond the viewport. This remains the same
      finite-wire approximation as the heatmap.],
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
    [Long wire: spatial field],
    sources-for("long-wire"),
    seeds,
    color: magnitude-colors(maximum: 16),
    observation: grid-for("long-wire"),
    source-colors: ("#a78bfa99",),
    note: [The display clips the long rod; the field still integrates its full
      finite length.],
  )
]

#import "common.typ": object-example

#context object-example([Long wire], heatmap, field-lines, spatial: spatial)
