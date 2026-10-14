#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, surface-sampling, magnitude-colors

#example-panel(
  [Uniformly charged annulus],
  (charged-annulus(0.4, 0.9, plane: yz-plane(), ..surface-sampling),),
  description: [A finite charged surface with an uncharged central hole.],
  formula: [$sigma = 1, quad R_"in" = 0.4, quad R_"out" = 0.9$],
  color: magnitude-colors(maximum: 8),
  note: [The finite outer edge distinguishes this source from an infinite plane with a hole.],
)
