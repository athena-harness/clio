#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "finite-line", [Finite line-charge field lines],
  (seed-segment((-1, 0.14), (1, 0.14), count: 13),
    seed-segment((-1, -0.14), (1, -0.14), count: 13)),
  description: [Seeds on both sides show transverse fields and end effects.],
  formula: [$lambda = 1, quad L = 2.2$],
  note: [Source length, linear density, and quadrature match the finite-rod heatmap. The end trajectories curve outward.],
)
