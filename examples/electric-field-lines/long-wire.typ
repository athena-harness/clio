#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "long-wire", [Long-wire field lines],
  (seed-segment((-1.8, 0.14), (1.8, 0.14), count: 13),
    seed-segment((-1.8, -0.14), (1.8, -0.14), count: 13)),
  description: [The central field is nearly perpendicular to the long wire.],
  formula: [$lambda = 1, quad L = 16$],
  note: [The actual source extends beyond the viewport. This remains the same finite-wire approximation as the heatmap.],
)
