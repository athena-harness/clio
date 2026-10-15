#import "../../lib.typ": *
#let layout-grid = grid

// Configure raster samples independently from source integration samples.
#let sample-width = int(sys.inputs.at("samples-x", default: "160"))
#let sample-height = int(sys.inputs.at("samples-y", default: "120"))
#let integration-detail = int(sys.inputs.at("integration-detail", default: "1"))
#assert(integration-detail >= 1, message: "integration-detail must be at least 1")

#let surface-sampling = (
  radial-samples: 24 * integration-detail,
  angular-samples: 64 * integration-detail,
)
#let line-sampling = 128 * integration-detail
#let plot-field = field-parameters(softening: 0.06)

#let xy-grid(bounds: (-2, 2, -1.5, 1.5), height: 0) = field-grid(
  resolution: (sample-width, sample-height),
  bounds: bounds,
  plane: field-plane(origin: (0, 0, height)),
)

#let yz-plane(origin: (0, 0, 0)) = field-plane(
  origin: origin, horizontal: (0, 1, 0), vertical: (0, 0, 1),
)

#let magnitude-colors(maximum: 10) = field-colors(range: (0, maximum))
#let signed-colors(maximum: 10) = field-colors(
  range: (-maximum, maximum), scale: asinh-scale(reference: 1),
  stops: ("#2458a6", "#f7f7f2", "#c43c39"),
)

/// Compose one self-contained example without changing the surrounding page.
#let example-panel(
  title, sources,
  description: [], formula: [], note: [],
  grid: xy-grid(), quantity: field-magnitude(),
  color: magnitude-colors(), scalar-label: $abs(bold(E))$,
  field: plot-field,
  overlay: source-overlay(),
  plot: none, legend: true,
  direction-label: [Arrows follow the electric field.],
) = {
  set text(size: 8pt)
  set par(leading: 0.5em)
  block(
    width: 100%, breakable: false, inset: 8pt, radius: 4pt,
    stroke: 0.5pt + rgb("#dce2e9"),
    layout-grid(
      columns: 1, row-gutter: 3pt,
      text(size: 11pt, weight: "bold", title),
      block(height: 18pt, description),
      block(height: 16pt, formula),
      if plot != none { plot } else { electric-field-heatmap(
        sources, grid: grid, field: field, quantity: quantity, color: color,
        source-overlay: overlay,
      ) },
      layout-grid(
        columns: (1fr, auto, 1fr),
        text(size: 7pt)[#grid.bounds.at(0)],
        text(size: 7pt)[$x$; $y$ increases upward],
        align(right, text(size: 7pt)[#grid.bounds.at(1)]),
      ),
      if legend { field-colorbar(color: color, width: 100%, resolution: (192, 8)) }
      else { block(height: 10pt, text(size: 7pt, direction-label)) },
      if legend { layout-grid(
        columns: (1fr, auto, 1fr),
        text(size: 7pt)[#color.range.at(0)],
        text(size: 7pt)[#scalar-label / #color.transform.kind],
        align(right, text(size: 7pt)[#color.range.at(1)]),
      ) } else { block(height: 8pt) },
      block(height: 24pt, text(size: 7pt, fill: rgb("#475569"), note)),
    ),
  )
}
