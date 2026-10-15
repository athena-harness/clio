#import "../../lib.typ": *
#import "../electric-field/custom-models.typ": custom-models
#import "../electric-field/common.typ": example-panel, magnitude-colors, mask-thickness, plot-field

#let model = custom-models.at("charged-volume")
#example-panel(
  model.title,
  model.sources,
  grid: model.grid,
  description: model.description,
  formula: model.formula,
  note: model.note,
  color: magnitude-colors(),
  legend: false,
  plot: electric-field-lines(
    model.sources,
    model.seeds,
    grid: model.grid,
    field: plot-field,
    tracing: model.tracing,
    style: field-line-style(thickness: 0.35, arrow-size: 1.8, arrow-spacing: 24),
    source-overlay: source-overlay(color: "#c4b5fd", thickness: mask-thickness),
  ),
)
