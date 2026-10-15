#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "uniform-disk", [Uniform-disk field lines],
  (seed-segment((-0.14, -0.7), (-0.14, 0.7), count: 15),
    seed-segment((0.14, -0.7), (0.14, 0.7), count: 15)),
  description: [An axial slice shows emission from both sides of the disk.],
  formula: [$sigma = 1, quad R = 0.8$],
  note: [The source lies in yz and the observation plane is xy. Surface quadrature is shared with the heatmap.],
)
