#import "models.typ": grid-for, sources-for
#import "../../lib.typ": *
#import "common.typ": example-panel, line-sampling, magnitude-colors

#example-panel(
  [Finite uniform line charge],
  sources-for("finite-line"),
  grid: grid-for("finite-line"),
  description: [A straight rod with prescribed uniform linear density.],
  formula: [$lambda = 1, quad L = 2.2$],
  color: magnitude-colors(maximum: 16),
  note: [Near the rod the transverse field dominates; far away it approaches a point-source pattern.],
)
