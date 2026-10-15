#import "models.typ": grid-for, sources-for
#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors, mask-thickness

#example-panel(
  [Electric dipole],
  sources-for("dipole"),
  grid: grid-for("dipole"),
  description: [Equal opposite charges with zero net charge.],
  formula: [$q_1 = +1, quad q_2 = -1, quad d = 1.4$],
  color: magnitude-colors(maximum: 8),
  overlay: source-overlay(
    color: "#ede9fe",
    thickness: mask-thickness,
    overrides: ((source: 1, style: source-style(color: "#bae6fd", thickness: mask-thickness)),),
  ),
  note: [The field adds between the charges; its distant magnitude decays faster than a monopole.],
)
