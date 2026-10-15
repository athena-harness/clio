#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Axial quadrupole],
  sources-for("axial-quadrupole"),
  grid: grid-for("axial-quadrupole"),
  description: [Three collinear charges with no monopole or dipole moment.],
  formula: [$q = (+1, -2, +1), quad x = (-0.8, 0, +0.8)$],
  color: magnitude-colors(maximum: 10),
  note: [A different quadrupole geometry with an angular pattern distinct from the square arrangement.],
)
