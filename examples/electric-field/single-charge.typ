#import "../../lib.typ": *
#import "common.typ": example-panel, magnitude-colors

#example-panel(
  [Single point charge],
  (point-charge((0, 0, 0)),),
  description: [A positive charge observed in the xy plane through the source.],
  formula: [$q = +1, quad bold(r)_q = (0, 0, 0)$],
  color: magnitude-colors(maximum: 6),
  note: [Radial symmetry and inverse-square decay away from the softened core.],
)
