#import "../../lib.typ": *
#import "../electric-field/custom-models.typ": custom-models
#import "../electric-field/common.typ": example-panel, magnitude-colors, mask-thickness, plot-field

#let model = custom-models.at("triangle-mesh")
#example-panel(
  model.title,
  model.sources,
  grid: model.grid,
  description: model.description,
  formula: model.formula,
  note: [Purple: source cross-section at $z = 0$. Amber diamond: numerical stagnation near field cancellation.],
  color: magnitude-colors(),
  legend: false,
  plot: electric-field-lines(
    model.sources,
    model.seeds,
    grid: model.grid,
    field: plot-field,
    tracing: model.tracing,
    style: field-line-style(thickness: 0.35, arrow-size: 1.8, arrow-spacing: 24),
    endpoints: field-line-endpoints(size: 2, thickness: 0.6),
    source-overlay: source-overlay(color: "#c4b5fd", thickness: mask-thickness),
  ),
)
