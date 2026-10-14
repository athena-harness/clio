#import "../../lib.typ": *
#import "common.typ": example-panel, line-sampling, magnitude-colors

#example-panel(
  [Opposite parallel line charges],
  (
    charged-segment((-0.6, -1.1, 0), (-0.6, 1.1, 0), samples: line-sampling),
    charged-segment((0.6, -1.1, 0), (0.6, 1.1, 0), density: -1, samples: line-sampling),
  ),
  description: [Two finite line charges with equal opposite density.],
  formula: [$lambda_1 = +1, quad lambda_2 = -1, quad d = 1.2$],
  color: magnitude-colors(maximum: 16),
  note: [The ends produce fringing. This is a prescribed-charge model, not a solution for conducting wires.],
)
