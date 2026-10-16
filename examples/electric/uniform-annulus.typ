// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, magnitude-colors, surface-sampling, yz-plane,
  )

  #example-panel(
    [Uniformly charged annulus],
    sources-for("uniform-annulus"),
    grid: grid-for("uniform-annulus"),
    description: [A finite charged surface with an uncharged central hole.],
    formula: [$sigma = 1, quad R_"in" = 0.4, quad R_"out" = 0.9$],
    color: magnitude-colors(maximum: 8),
    note: [The finite outer edge distinguishes this source from an infinite
      plane with a hole.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "uniform-annulus",
    [Uniform-annulus field lines],
    (
      seed-segment((-0.14, 0.48), (-0.14, 0.82), count: 8),
      seed-segment((0.14, 0.48), (0.14, 0.82), count: 8),
      seed-segment((-0.14, -0.82), (-0.14, -0.48), count: 8),
      seed-segment((0.14, -0.82), (0.14, -0.48), count: 8),
      seed-circle((0, 0), radius: 0.25, count: 12, phase: 0.08),
    ),
    description: [A finite opening changes the field near the symmetry axis.],
    formula: [$sigma = 1, quad R_"in" = 0.4, quad R_"out" = 0.9$],
    note: [Seeds beside the charged bands and inside the opening reveal the
      inner and outer field regions.],
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
        result.push((x, 0.65 * calc.cos(angle), 0.65 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Uniform annulus: spatial field],
    sources-for("uniform-annulus"),
    seeds,
    color: magnitude-colors(maximum: 8),
    observation: grid-for("uniform-annulus"),
    source-colors: ("#a78bfa99",),
    note: [Both faces of the annular surface emit spatial field lines around the
      opening.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Uniform annulus],
  heatmap,
  field-lines,
  spatial: spatial,
)
