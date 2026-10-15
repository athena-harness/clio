#import "../electric-field/models.typ": sources-for
#import "../../lib.typ": *
#import "../electric-field/common.typ": example-panel, yz-plane, integration-detail
#import "common.typ": line-grid-for, line-field, line-overlay

#let line-grid = line-grid-for("parallel-disks")
#let sources = sources-for("parallel-disks")
#example-panel(
  [Parallel-disk field lines], sources,
  grid: line-grid,
  description: [A symmetry-plane slice shows the central field and fringing.],
  formula: [$sigma_1 = +1, quad sigma_2 = -1$],
  note: [Seeds lie between finite, prescribed-charge disks. No conductor charge redistribution is solved.],
  legend: false,
  plot: electric-field-lines(sources, (seed-segment((0, -1.35), (0, 1.35), count: 17),),
    grid: line-grid, field: line-field, tracing: field-line-tracing(step: 0.03),
    source-overlay: line-overlay),
)
