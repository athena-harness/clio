#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "uniform-annulus",
  [Uniform-annulus field lines],
  (
    seed-segment((-0.14, 0.48), (-0.14, 0.82), count: 8),
    seed-segment((0.14, 0.48), (0.14, 0.82), count: 8),
    seed-segment((-0.14, -0.82), (-0.14, -0.48), count: 8),
    seed-segment((0.14, -0.82), (0.14, -0.48), count: 8),
    seed-circle((0, 0), radius: 0.25, count: 12, phase: 0.08),
  ),
  description: [A finite opening changes the field near the symmetry axis.],
  formula: [$sigma = 1, quad R_"in" = 0.4, quad R_"out" = 0.9$],
  note: [Seeds beside the charged bands and inside the opening reveal the inner and outer field regions.],
)
