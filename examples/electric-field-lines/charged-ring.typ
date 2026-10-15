#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "charged-ring",
  [Charged-ring approximation],
  (
    seed-circle((0, -0.8), radius: 0.17, count: 16),
    seed-circle((0, 0.8), radius: 0.17, count: 16),
    seed-circle((0, 0), radius: 0.3, count: 12, phase: 0.08),
  ),
  description: [A side slice through a narrow annulus with unit charge.],
  formula: [$Q = 1, quad R approx 0.8$],
  note: [The shared source has radii 0.77 and 0.83. Extra interior seeds resolve
    the field through the opening.],
)
