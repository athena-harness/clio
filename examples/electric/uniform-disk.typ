// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, magnitude-colors, surface-sampling, yz-plane,
  )

  #example-panel(
    [Uniformly charged disk],
    sources-for("uniform-disk"),
    grid: grid-for("uniform-disk"),
    description: [A side view of a charged disk in the yz plane.],
    formula: [$sigma = 1, quad R = 0.8$],
    color: magnitude-colors(maximum: 8),
    note: [The disk's axis is x. The heatmap includes all three components in
      the xy observation plane.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "uniform-disk",
    [Uniform-disk field lines],
    (
      seed-segment((-0.14, -0.7), (-0.14, 0.7), count: 15),
      seed-segment((0.14, -0.7), (0.14, 0.7), count: 15),
    ),
    description: [An axial slice shows emission from both sides of the disk.],
    formula: [$sigma = 1, quad R = 0.8$],
    note: [The source lies in yz and the observation plane is xy. Surface
      quadrature is shared with the heatmap.],
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
        result.push((x, 0.45 * calc.cos(angle), 0.45 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Uniform disk: spatial field],
    sources-for("uniform-disk"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("uniform-disk"),
    source-colors: ("#a78bfa99",),
    note: [The full disk lies in yz; seeds on both faces reveal axial and
      fringing fields.],
  )
]

#import "common.typ": object-example

#context object-example([Uniform disk], heatmap, field-lines, spatial: spatial)
