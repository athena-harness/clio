#import "models.typ": grid-for, sources-for
#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Square quadrupole],
  sources-for("square-quadrupole"),
  grid: grid-for("square-quadrupole"),
  description: [Alternating charges at the corners of a square.],
  formula: [$sum q_i = 0, quad sum q_i bold(r)_i = bold(0)$],
  color: magnitude-colors(maximum: 8),
  note: [Both total charge and dipole moment vanish; the central field is zero by symmetry.],
)
