#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "plane-with-hole",
  [Infinite plane with a hole],
  (
    seed-segment((-0.14, 0.8), (-0.14, 1.4), count: 8),
    seed-segment((0.14, 0.8), (0.14, 1.4), count: 8),
    seed-segment((-0.14, -1.4), (-0.14, -0.8), count: 8),
    seed-segment((0.14, -1.4), (0.14, -0.8), count: 8),
    seed-circle((0, 0), radius: 0.35, count: 12, phase: 0.08),
  ),
  description: [The opening bends trajectories near an otherwise planar
    source.],
  formula: [$sigma = 1, quad R_"hole" = 0.7$],
  note: [Surface-adjacent and interior seeds show edge deflection and the
    central cancellation region.],
)
