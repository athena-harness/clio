#import "../../lib.typ": *
#import "common.typ": xy-grid, yz-plane, surface-sampling, integration-detail, line-sampling

// Physical source definitions shared by heatmap and field-line examples.
#let inner-radius = 0.77
#let outer-radius = 0.83
#let density = 1 / (calc.pi * (outer-radius * outer-radius - inner-radius * inner-radius))

#let source-models = (
  "single-charge": (point-charge((0, 0, 0)),),
  "like-charges": (point-charge((-0.7, 0, 0)), point-charge((0.7, 0, 0))),
  "dipole": (point-charge((-0.7, 0, 0)), point-charge((0.7, 0, 0), charge: -1)),
  "unequal-charges": (point-charge((-0.6, 0, 0), charge: 2), point-charge((0.6, 0, 0), charge: -1)),
  "square-quadrupole": (
    point-charge((-0.6, -0.6, 0)),
    point-charge((0.6, 0.6, 0)),
    point-charge((-0.6, 0.6, 0), charge: -1),
    point-charge((0.6, -0.6, 0), charge: -1),
  ),
  "axial-quadrupole": (
    point-charge((-0.8, 0, 0)),
    point-charge((0, 0, 0), charge: -2),
    point-charge((0.8, 0, 0)),
  ),
  "finite-line": (charged-segment((-1.1, 0, 0), (1.1, 0, 0), samples: line-sampling),),
  "long-wire": (charged-segment((-8, 0, 0), (8, 0, 0), samples: 4 * line-sampling),),
  "line-dipole": (
    charged-segment((-0.6, -1.1, 0), (-0.6, 1.1, 0), samples: line-sampling),
    charged-segment((0.6, -1.1, 0), (0.6, 1.1, 0), density: -1, samples: line-sampling),
  ),
  "square-loop": (
    charged-segment((-0.8, -0.8, 0), (0.8, -0.8, 0), samples: line-sampling),
    charged-segment((0.8, -0.8, 0), (0.8, 0.8, 0), samples: line-sampling),
    charged-segment((0.8, 0.8, 0), (-0.8, 0.8, 0), samples: line-sampling),
    charged-segment((-0.8, 0.8, 0), (-0.8, -0.8, 0), samples: line-sampling),
  ),
  "uniform-disk": (charged-disk(0.8, plane: yz-plane(), ..surface-sampling),),
  "charged-ring": (charged-annulus(
    inner-radius, outer-radius, density: density, plane: yz-plane(),
    radial-samples: 4 * integration-detail, angular-samples: 96 * integration-detail,
  ),),
  "uniform-annulus": (charged-annulus(0.4, 0.9, plane: yz-plane(), ..surface-sampling),),
  "plane-with-hole": (charged-plane-with-hole(0.7, plane: yz-plane(), ..surface-sampling),),
  "parallel-disks": (
    charged-disk(1.1, plane: yz-plane(origin: (-0.4, 0, 0)), ..surface-sampling),
    charged-disk(1.1, density: -1, plane: yz-plane(origin: (0.4, 0, 0)), ..surface-sampling),
  ),
  "coplanar-disks": (
    charged-disk(0.55, plane: field-plane(origin: (-0.8, 0, 0)), ..surface-sampling),
    charged-disk(0.55, density: -1, plane: field-plane(origin: (0.8, 0, 0)), ..surface-sampling),
  ),
)

#let sources-for(name) = source-models.at(name)

// All scenes use the xy plane; the last scene is observed above its source plane.
#let grid-for(name) = xy-grid(height: if name == "coplanar-disks" { 0.35 } else { 0 })
