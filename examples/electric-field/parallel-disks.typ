#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, surface-sampling, signed-colors

#example-panel(
  [Finite parallel-disk capacitor],
  (
    charged-disk(1.1, plane: yz-plane(origin: (-0.4, 0, 0)), ..surface-sampling),
    charged-disk(1.1, density: -1, plane: yz-plane(origin: (0.4, 0, 0)), ..surface-sampling),
  ),
  description: [Opposite uniform surface charges on two parallel disks.],
  formula: [$sigma_1 = +1, quad sigma_2 = -1, quad d = 0.8$],
  quantity: field-component((1, 0, 0)),
  color: signed-colors(maximum: 12),
  scalar-label: $E_x$,
  note: [A finite prescribed-charge model shows fringing. Charge redistribution on real conductors is not modeled.],
)
