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
  note: [The finite outer edge distinguishes this source from an infinite plane
    with a hole.],
)
