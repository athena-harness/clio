#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, line-sampling, magnitude-colors

#example-panel(
  [Opposite parallel line charges],
  sources-for("line-dipole"),
  grid: grid-for("line-dipole"),
  description: [Two finite line charges with equal opposite density.],
  formula: [$lambda_1 = +1, quad lambda_2 = -1, quad d = 1.2$],
  color: magnitude-colors(maximum: 16),
  note: [The ends produce fringing. This is a prescribed-charge model, not a solution for conducting wires.],
)
