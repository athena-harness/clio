#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, surface-sampling, magnitude-colors

#example-panel(
  [Infinite plane with a hole],
  (charged-plane-with-hole(0.7, plane: yz-plane(), ..surface-sampling),),
  description: [A uniformly charged yz plane outside a circular opening.],
  formula: [$sigma = 1, quad R_"hole" = 0.7$],
  color: magnitude-colors(maximum: 8),
  note: [The exterior extends to infinity. The center is uncharged; radial sampling includes the infinite tail.],
)
