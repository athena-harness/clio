#import "../../lib.typ": *
#import "../electric-field/common.typ": sample-width, sample-height, plot-field, example-panel
#import "../electric-field/models.typ": sources-for, grid-for

#let line-field = plot-field
#let line-overlay = source-overlay(color: "#8b5cf6", thickness: 0.15)

// Keep the observation geometry identical while increasing SVG viewport detail.
#let line-grid-for(name) = {
  let result = grid-for(name)
  result.resolution = (3 * sample-width, 3 * sample-height)
  result
}

/// Compose a field-line scene using the exact model and frame of its heatmap.
#let line-panel(
  name, title, seeds, description: [], formula: [], note: [],
  tracing: field-line-tracing(),
  direction-label: [Arrows follow the electric field.],
) = {
  let sources = sources-for(name)
  let grid = line-grid-for(name)
  example-panel(
    title, sources, grid: grid, description: description, formula: formula, note: note,
    legend: false, direction-label: direction-label,
    plot: electric-field-lines(sources, seeds, grid: grid, field: line-field,
      tracing: tracing, source-overlay: line-overlay),
  )
}
