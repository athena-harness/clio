#import "../electric-field/models.typ": sources-for
#import "../../lib.typ": *
#import "../electric-field/common.typ": example-panel, example-tracing
#import "common.typ": line-field, line-grid-for, line-overlay

#let line-grid = line-grid-for("like-charges")
#let sources = sources-for("like-charges")
#example-panel(
  [Two positive charges],
  sources,
  grid: line-grid,
  description: [Field lines bend away from the central cancellation region.],
  formula: [$q_1 = q_2 = +1, quad N_"seeds" = 36$],
  note: [Each charge has its own seed circle. Curves terminate at the bounds, sources, nulls, or the step limit.],
  legend: false,
  plot: electric-field-lines(
    sources,
    (seed-circle((-0.7, 0), count: 18), seed-circle((0.7, 0), count: 18)),
    grid: line-grid,
    field: line-field,
    tracing: example-tracing(),
    source-overlay: line-overlay,
  ),
)
