#import "../../lib.typ": *
#import "common.typ": example-panel, line-sampling, magnitude-colors

#example-panel(
  [Uniform square wire loop],
  (
    charged-segment((-0.8, -0.8, 0), (0.8, -0.8, 0), samples: line-sampling),
    charged-segment((0.8, -0.8, 0), (0.8, 0.8, 0), samples: line-sampling),
    charged-segment((0.8, 0.8, 0), (-0.8, 0.8, 0), samples: line-sampling),
    charged-segment((-0.8, 0.8, 0), (-0.8, -0.8, 0), samples: line-sampling),
  ),
  description: [Four uniformly charged segments form a closed loop.],
  formula: [$lambda = 1, quad "side" = 1.6$],
  color: magnitude-colors(maximum: 16),
  note: [The field cancels at the center. Uniform density is imposed rather than determined by conductor equilibrium.],
)
