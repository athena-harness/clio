#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, integration-detail, magnitude-colors

#example-panel(
  [Charged-ring approximation],
  sources-for("charged-ring"),
  grid: grid-for("charged-ring"),
  description: [A narrow annulus approximates a circular ring with unit charge.],
  formula: [$Q = 1, quad R approx 0.8$],
  color: magnitude-colors(maximum: 8),
  note: [The band has radii 0.77 and 0.83. Its finite width is part of the model, not an exact line ring.],
)
