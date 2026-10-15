#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "square-loop",
  [Uniform square-loop field lines],
  (
    seed-circle((0, 0), radius: 0.4, count: 12),
    seed-segment((-0.6, -0.95), (0.6, -0.95), count: 6),
    seed-segment((-0.6, 0.95), (0.6, 0.95), count: 6),
    seed-segment((-0.95, -0.6), (-0.95, 0.6), count: 6),
    seed-segment((0.95, -0.6), (0.95, 0.6), count: 6),
  ),
  description: [Interior curves approach the central planar field null.],
  formula: [$lambda = 1, quad "side" = 1.6$],
  note: [Interior and exterior seeds reveal both regions. A null in this symmetry plane does not imply stable 3D confinement.],
)
