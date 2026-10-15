#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "line-dipole",
  [Opposite parallel line charges],
  (seed-segment((0, -1.35), (0, 1.35), count: 19),),
  description: [Lines connect opposite rods and bend around their ends.],
  formula: [$lambda_1 = +1, quad lambda_2 = -1, quad d = 1.2$],
  note: [A mid-gap seed segment traces both branches. Densities are prescribed rather than solved for conducting wires.],
)
