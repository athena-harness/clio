#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Unequal opposite charges],
  (point-charge((-0.6, 0, 0), charge: 2), point-charge((0.6, 0, 0), charge: -1)),
  description: [An asymmetric pair with net positive charge.],
  formula: [$q_1 = +2, quad q_2 = -1$],
  color: magnitude-colors(maximum: 8),
  note: [Unlike a neutral dipole, this pair retains a monopole contribution at large distances.],
)
