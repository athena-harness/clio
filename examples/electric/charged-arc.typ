// All available views of this object share one example module.
#let heatmap() = [
  #import "../../lib.typ": *
  #import "custom-models.typ": custom-models
  #import "common.typ": example-panel, magnitude-colors, plot-field

  #let model = custom-models.at("charged-arc")
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

  #let model = custom-models.at("charged-arc")
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
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "custom-models.typ": custom-models
  #let model = custom-models.at("charged-arc")

  #let seeds = sphere-seeds((0.1, 0, 0), radius: 0.18, count: 16)
  #spatial-panel(
    [Charged arc: spatial field],
    model.sources,
    seeds,
    color: magnitude-colors(maximum: 10),
    observation: model.grid,
    source-colors: ("#a78bfa99", "#3769be"),
    note: [The complete elliptical arc interacts with a negative point charge.
      Seeds also extend outside the arc plane.],
  )
]

#import "common.typ": object-example

#context object-example([Charged arc], heatmap, field-lines, spatial: spatial)
