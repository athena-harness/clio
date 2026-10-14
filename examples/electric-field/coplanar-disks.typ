#import "../../lib.typ": *
#import "common.typ": example-panel, xy-grid, surface-sampling, signed-colors

#example-panel(
  [Opposite coplanar disks],
  (
    charged-disk(0.55, plane: field-plane(origin: (-0.8, 0, 0)), ..surface-sampling),
    charged-disk(0.55, density: -1, plane: field-plane(origin: (0.8, 0, 0)), ..surface-sampling),
  ),
  description: [The normal component above two oppositely charged patches.],
  formula: [$sigma_1 = +1, quad sigma_2 = -1, quad z_"obs" = 0.35$],
  grid: xy-grid(height: 0.35),
  quantity: field-component((0, 0, 1)),
  color: signed-colors(maximum: 6),
  scalar-label: $E_z$,
  note: [A diverging palette distinguishes positive and negative normal fields; the observation slice is above both disks.],
)
