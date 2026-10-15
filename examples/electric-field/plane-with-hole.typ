#import "models.typ": grid-for, sources-for
#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors, surface-sampling, yz-plane

#example-panel(
  [Infinite plane with a hole],
  sources-for("plane-with-hole"),
  grid: grid-for("plane-with-hole"),
  description: [A uniformly charged yz plane outside a circular opening.],
  formula: [$sigma = 1, quad R_"hole" = 0.7$],
  color: magnitude-colors(maximum: 8),
  note: [The exterior extends to infinity. The center is uncharged; radial sampling includes the infinite tail.],
)
