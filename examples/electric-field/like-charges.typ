#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Two equal positive charges],
  (point-charge((-0.7, 0, 0)), point-charge((0.7, 0, 0))),
  description: [Vector cancellation creates a field null at the midpoint.],
  formula: [$q_1 = q_2 = +1, quad x_1 = -0.7, quad x_2 = +0.7$],
  color: magnitude-colors(maximum: 8),
  note: [The central minimum comes from adding vectors before taking their magnitude.],
)
