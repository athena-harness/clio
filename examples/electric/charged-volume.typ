// All available views of this object share one example module.
#let heatmap() = [
  #import "../../lib.typ": *
  #import "custom-models.typ": custom-models
  #import "common.typ": example-panel, magnitude-colors, plot-field

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

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "custom-models.typ": custom-models
  #import "common.typ": (
    example-panel, magnitude-colors, mask-thickness, plot-field,
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
    legend: false,
    plot: electric-field-lines(
      model.sources,
      model.seeds,
      grid: model.grid,
      field: plot-field,
      tracing: model.tracing,
      style: field-line-style(
        thickness: 0.35,
        arrow-size: 1.8,
        arrow-spacing: 24,
      ),
      source-overlay: source-overlay(
        color: "#c4b5fd",
        thickness: mask-thickness,
      ),
    ),
  )

]

#let spatial() = [
  #import "spatial-common.typ": scene-panel

  #scene-panel(
    "charged-volume",
    [Volume charge and disk],
    note: [The translucent exterior shell represents the volume. Internal
      tetrahedron faces are omitted. Field lines stop at the charged volume
      boundary.],
  )

]

#import "common.typ": object-example

#context object-example(
  [Charged volume],
  heatmap,
  field-lines,
  spatial: spatial,
)
