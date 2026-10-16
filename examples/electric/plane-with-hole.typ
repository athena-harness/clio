// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, magnitude-colors, surface-sampling, yz-plane,
  )

  #example-panel(
    [Infinite plane with a hole],
    sources-for("plane-with-hole"),
    grid: grid-for("plane-with-hole"),
    description: [A uniformly charged yz plane outside a circular opening.],
    formula: [$sigma = 1, quad R_"hole" = 0.7$],
    color: magnitude-colors(maximum: 8),
    note: [The exterior extends to infinity. The center is uncharged; radial
      sampling includes the infinite tail.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "plane-with-hole",
    [Infinite plane with a hole],
    (
      seed-segment((-0.14, 0.8), (-0.14, 1.4), count: 8),
      seed-segment((0.14, 0.8), (0.14, 1.4), count: 8),
      seed-segment((-0.14, -1.4), (-0.14, -0.8), count: 8),
      seed-segment((0.14, -1.4), (0.14, -0.8), count: 8),
      seed-circle((0, 0), radius: 0.35, count: 12, phase: 0.08),
    ),
    description: [The opening bends trajectories near an otherwise planar
      source.],
    formula: [$sigma = 1, quad R_"hole" = 0.7$],
    note: [Surface-adjacent and interior seeds show edge deflection and the
      central cancellation region.],
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
        result.push((x, 1.0 * calc.cos(angle), 1.0 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Plane with hole: spatial field],
    sources-for("plane-with-hole"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("plane-with-hole"),
    source-colors: ("#a78bfa99",),
    note: [Only a finite patch is displayed. The field calculation still
      includes the infinite charged plane.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Plane with hole],
  heatmap,
  field-lines,
  spatial: spatial,
)
