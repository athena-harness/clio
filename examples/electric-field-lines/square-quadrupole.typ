#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "square-quadrupole",
  [Square quadrupole lines],
  (seed-circle((-0.6, -0.6), count: 18), seed-circle((0.6, 0.6), count: 18)),
  description: [Two positive corners feed the two negative corners.],
  formula: [$sum q_i = 0, quad sum q_i bold(r)_i = bold(0)$],
  note: [This uses the same four charges as the heatmap. The central
    cancellation point terminates nearby trajectories.],
)
