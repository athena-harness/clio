// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, integration-detail, magnitude-colors, yz-plane,
  )

  #example-panel(
    [Charged-ring approximation],
    sources-for("charged-ring"),
    grid: grid-for("charged-ring"),
    description: [A narrow annulus approximates a circular ring with unit
      charge.],
    formula: [$Q = 1, quad R approx 0.8$],
    color: magnitude-colors(maximum: 8),
    note: [The band has radii 0.77 and 0.83. Its finite width is part of the
      model, not an exact line ring.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "charged-ring",
    [Charged-ring approximation],
    (
      seed-circle((0, -0.8), radius: 0.17, count: 16),
      seed-circle((0, 0.8), radius: 0.17, count: 16),
      seed-circle((0, 0), radius: 0.3, count: 12, phase: 0.08),
    ),
    description: [A side slice through a narrow annulus with unit charge.],
    formula: [$Q = 1, quad R approx 0.8$],
    note: [The shared source has radii 0.77 and 0.83. Extra interior seeds
      resolve the field through the opening.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for x in (-0.14, 0.14) {
      for i in range(6) {
        let angle = i * calc.pi / 3
        result.push((x, 0.8 * calc.cos(angle), 0.8 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Charged ring: spatial field],
    sources-for("charged-ring"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("charged-ring"),
    source-colors: ("#a78bfa99",),
    note: [A narrow charged annulus approximates a ring; the full opening is
      visible in space.],
  )
]

#import "common.typ": object-example

#context object-example([Charged ring], heatmap, field-lines, spatial: spatial)
