// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, line-sampling, magnitude-colors

  #example-panel(
    [Opposite parallel line charges],
    sources-for("line-dipole"),
    grid: grid-for("line-dipole"),
    description: [Two finite line charges with equal opposite density.],
    formula: [$lambda_1 = +1, quad lambda_2 = -1, quad d = 1.2$],
    color: magnitude-colors(maximum: 16),
    note: [The ends produce fringing. This is a prescribed-charge model, not a
      solution for conducting wires.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "line-dipole",
    [Opposite parallel line charges],
    (seed-segment((0, -1.35), (0, 1.35), count: 19),),
    description: [Lines connect opposite rods and bend around their ends.],
    formula: [$lambda_1 = +1, quad lambda_2 = -1, quad d = 1.2$],
    note: [A mid-gap seed segment traces both branches. Densities are prescribed
      rather than solved for conducting wires.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for y in (-0.7, 0, 0.7) {
      for z in (-0.18, 0.18) { result.push((-0.43, y, z)) }
    }
    result
  }
  #spatial-panel(
    [Line dipole: spatial field],
    sources-for("line-dipole"),
    seeds,
    color: magnitude-colors(maximum: 16),
    observation: grid-for("line-dipole"),
    source-colors: ("#dc504399", "#3769be99"),
    note: [Seeds around the positive rod trace toward the negative rod in three
      dimensions.],
  )
]

#import "common.typ": object-example

#context object-example([Line dipole], heatmap, field-lines, spatial: spatial)
