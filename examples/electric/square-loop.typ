// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, line-sampling, magnitude-colors

  #example-panel(
    [Uniform square wire loop],
    sources-for("square-loop"),
    grid: grid-for("square-loop"),
    description: [Four uniformly charged segments form a closed loop.],
    formula: [$lambda = 1, quad "side" = 1.6$],
    color: magnitude-colors(maximum: 16),
    note: [The field cancels at the center. Uniform density is imposed rather
      than determined by conductor equilibrium.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel

  #line-panel(
    "square-loop",
    [Uniform square-loop field lines],
    (
      seed-circle((0, 0), radius: 0.4, count: 12),
      seed-segment((-0.6, -0.95), (0.6, -0.95), count: 6),
      seed-segment((-0.6, 0.95), (0.6, 0.95), count: 6),
      seed-segment((-0.95, -0.6), (-0.95, 0.6), count: 6),
      seed-segment((0.95, -0.6), (0.95, 0.6), count: 6),
    ),
    description: [Interior curves approach the central planar field null.],
    formula: [$lambda = 1, quad "side" = 1.6$],
    note: [Interior and exterior seeds reveal both regions. A null in this
      symmetry plane does not imply stable 3D confinement.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for xy in ((-0.8, 0), (0.8, 0), (0, -0.8), (0, 0.8)) {
      for z in (-0.18, 0.18) { result.push((xy.at(0), xy.at(1), z)) }
    }
    result
  }
  #spatial-panel(
    [Square loop: spatial field],
    sources-for("square-loop"),
    seeds,
    color: magnitude-colors(maximum: 16),
    observation: grid-for("square-loop"),
    source-colors: ("#a78bfa99",),
    note: [The complete square loop is planar, while its electric field extends
      outside that plane.],
  )
]

#import "common.typ": object-example

#context object-example([Square loop], heatmap, field-lines, spatial: spatial)
