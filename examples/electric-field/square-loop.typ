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
  note: [The field cancels at the center. Uniform density is imposed rather than
    determined by conductor equilibrium.],
)
