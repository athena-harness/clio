#import "../electric-field/models.typ": sources-for
#import "../../lib.typ": *
#import "../electric-field/common.typ": example-panel, example-tracing
#import "common.typ": line-field, line-grid-for, line-overlay

#let line-grid = line-grid-for("single-charge")
#let sources = sources-for("single-charge")
#example-panel(
  [Radial field lines],
  sources,
  grid: line-grid,
  description: [A positive point charge emits radial electric-field lines.],
  formula: [$q = +1, quad N_"seeds" = 24$],
  note: [Circle seeds are generated in Rust. Joined forward and backward branches share the physical arrow direction.],
  legend: false,
  plot: electric-field-lines(
    sources,
    (seed-circle((0, 0), count: 24),),
    grid: line-grid,
    field: line-field,
    tracing: example-tracing(),
    source-overlay: line-overlay,
  ),
)
