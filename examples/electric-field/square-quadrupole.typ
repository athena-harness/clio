#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Square quadrupole],
  (
    point-charge((-0.6, -0.6, 0)),
    point-charge((0.6, 0.6, 0)),
    point-charge((-0.6, 0.6, 0), charge: -1),
    point-charge((0.6, -0.6, 0), charge: -1),
  ),
  description: [Alternating charges at the corners of a square.],
  formula: [$sum q_i = 0, quad sum q_i bold(r)_i = bold(0)$],
  color: magnitude-colors(maximum: 8),
  note: [Both total charge and dipole moment vanish; the central field is zero by symmetry.],
)
