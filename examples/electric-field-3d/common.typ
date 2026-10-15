#import "../../lib.typ": *
#import "../electric-field/custom-models.typ": custom-models
#import "../electric-field/common.typ": magnitude-colors, plot-field

// Seed positions are world coordinates, deliberately displaced from the z = 0 slice.
#let sheet-seeds = {
  let seeds = ()
  for y in (-0.6, 0, 0.6) {
    for z in (-0.4, 0.4) { seeds.push((0.3, y, z)) }
  }
  seeds
}

#let scene-for(heatmap: false) = field-scene(
  camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
  slice: field-scene-slice(
    color: if heatmap { magnitude-colors() } else { none },
    opacity: if heatmap { 0.7 } else { 0.16 },
    samples: (48, 36),
  ),
  lines: field-scene-lines(
    sheet-seeds,
    tracing: spatial-field-line-tracing(max-steps: 600),
  ),
)

#let scene-panel(name, title, note: [], heatmap: false) = {
  let model = custom-models.at(name)
  block(
    width: 100%,
    breakable: false,
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#dce2e9"),
    grid(
      columns: 1,
      row-gutter: 4pt,
      text(size: 11pt, weight: "bold", title),
      electric-field-scene(
        model.sources,
        grid: model.grid,
        field: plot-field,
        scene: scene-for(
          heatmap: heatmap,
        ),
      ),
      text(size: 7pt, fill: rgb("#475569"), note),
    ),
  )
}
