#import "../electric-field/models.typ": sources-for
#import "../../lib.typ": *
#import "../electric-field/common.typ": example-panel, magnitude-colors
#import "common.typ": line-grid-for, line-field

#let line-grid = line-grid-for("dipole")
#let sources = sources-for("dipole")
#let colors = magnitude-colors(maximum: 8)
#example-panel(
  [Dipole lines on a heatmap], sources,
  grid: line-grid,
  description: [Curves follow the electric field from positive to negative charge.],
  formula: [$q_1 = +1, quad q_2 = -1$],
  color: colors,
  note: [The heatmap shows magnitude. White arrows follow the vector field, independently of the logarithmic colors.],
  plot: electric-field-lines(sources, (seed-circle((-0.7, 0), count: 24),),
    grid: line-grid, field: line-field,
    style: field-line-style(color: white, thickness: 1.2),
    background: field-line-heatmap(color: colors),
    source-overlay: source-overlay(color: "#8b5cf6", thickness: 0.15,
      overrides: ((source: 1, style: source-style(color: "#38bdf8", thickness: 0.15)),))),
)
