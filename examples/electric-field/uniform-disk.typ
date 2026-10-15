#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, surface-sampling, magnitude-colors

#example-panel(
  [Uniformly charged disk],
  sources-for("uniform-disk"),
  grid: grid-for("uniform-disk"),
  description: [A side view of a charged disk in the yz plane.],
  formula: [$sigma = 1, quad R = 0.8$],
  color: magnitude-colors(maximum: 8),
  note: [The disk's axis is x. The heatmap includes all three components in the xy observation plane.],
)
