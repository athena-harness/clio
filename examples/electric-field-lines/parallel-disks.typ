#import "../electric-field/models.typ": sources-for
#import "../../lib.typ": *
#import "../electric-field/common.typ": (
  example-panel, example-tracing, integration-detail, yz-plane,
)
#import "common.typ": line-field, line-grid-for, line-overlay

#let line-grid = line-grid-for("parallel-disks")
#let sources = sources-for("parallel-disks")
#example-panel(
  [Parallel-disk field lines],
  sources,
  grid: line-grid,
  description: [A symmetry-plane slice shows the central field and fringing.],
  formula: [$sigma_1 = +1, quad sigma_2 = -1$],
  note: [Seeds lie between finite, prescribed-charge disks. No conductor charge
    redistribution is solved.],
  legend: false,
  plot: electric-field-lines(
    sources,
    (seed-segment((0, -1.35), (0, 1.35), count: 17),),
    grid: line-grid,
    field: line-field,
    tracing: example-tracing(step: 0.03),
    source-overlay: line-overlay,
  ),
)
