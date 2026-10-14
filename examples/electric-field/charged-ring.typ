#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, integration-detail, magnitude-colors

// A narrow band approximates a ring while retaining the existing surface API.
#let inner-radius = 0.77
#let outer-radius = 0.83
#let density = 1 / (calc.pi * (outer-radius * outer-radius - inner-radius * inner-radius))

#example-panel(
  [Charged-ring approximation],
  (charged-annulus(
    inner-radius, outer-radius, density: density, plane: yz-plane(),
    radial-samples: 4 * integration-detail, angular-samples: 96 * integration-detail,
  ),),
  description: [A narrow annulus approximates a circular ring with unit charge.],
  formula: [$Q = 1, quad R approx 0.8$],
  color: magnitude-colors(maximum: 8),
  note: [The band has radii 0.77 and 0.83. Its finite width is part of the model, not an exact line ring.],
)
