#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "axial-quadrupole",
  [Axial quadrupole lines],
  (seed-circle((-0.8, 0), count: 18), seed-circle((0.8, 0), count: 18)),
  description: [Two positive outer charges feed a negative central charge.],
  formula: [$q = (+1, -2, +1), quad x = (-0.8, 0, +0.8)$],
  note: [Both positive sources are seeded. Arrow direction follows the vector sum of all three charges.],
)
