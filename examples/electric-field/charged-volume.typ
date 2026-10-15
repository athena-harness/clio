#import "../../lib.typ": *
#import "../electric-field/custom-models.typ": custom-models
#import "../electric-field/common.typ": (
  example-panel, magnitude-colors, plot-field,
)

#let model = custom-models.at("charged-volume")
#example-panel(
  model.title,
  model.sources,
  grid: model.grid,
  description: model.description,
  formula: model.formula,
  note: model.note,
  color: magnitude-colors(),
)
