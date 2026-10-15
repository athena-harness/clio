#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, yz-plane, surface-sampling, signed-colors

#example-panel(
  [Finite parallel-disk capacitor],
  sources-for("parallel-disks"),
  grid: grid-for("parallel-disks"),
  description: [Opposite uniform surface charges on two parallel disks.],
  formula: [$sigma_1 = +1, quad sigma_2 = -1, quad d = 0.8$],
  quantity: field-component((1, 0, 0)),
  color: signed-colors(maximum: 12),
  scalar-label: $E_x$,
  note: [A finite prescribed-charge model shows fringing. Charge redistribution on real conductors is not modeled.],
)
