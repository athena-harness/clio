#import "../../lib.typ": *
#import "custom-models.typ": custom-models
#import "common.typ": magnitude-colors, plot-field

/// Show the magnitude scale used by a spatial heatmap slice.
#let scene-legend(color) = grid(
  columns: 1,
  row-gutter: 2pt,
  field-colorbar(color: color, width: 100%, resolution: (192, 8)),
  grid(
    columns: (1fr, auto, 1fr),
    text(size: 7pt)[#color.range.at(0)],
    text(size: 7pt)[$abs(bold(E))$ / #color.transform.kind],
    align(right, text(size: 7pt)[#color.range.at(1)]),
  ),
)

/// Distribute explicit spatial seeds on a sphere using a Fibonacci lattice.
#let sphere-seeds(center, radius: 0.16, count: 10) = range(count).map(i => {
  let z = 1 - 2 * (i + 0.5) / count
  let angle = i * calc.pi * (3 - calc.sqrt(5))
  let r = calc.sqrt(1 - z * z)
  (
    center.at(0) + radius * r * calc.cos(angle),
    center.at(1) + radius * r * calc.sin(angle),
    center.at(2) + radius * z,
  )
})

/// Show a model's full spatial geometry and independently seeded vector field.
#let spatial-panel(
  title,
  sources,
  seeds,
  observation: field-grid(),
  color: magnitude-colors(),
  note: [],
  source-colors: ("#a78bfa99",),
  curve-radius: 0.025,
) = block(
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
      sources,
      grid: observation,
      field: plot-field,
      scene: field-scene(
        camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
        source-colors: source-colors,
        source-thickness: 0.55,
        curve-radius: curve-radius,
        slice: field-scene-slice(color: color, opacity: 0.65, samples: (
          48,
          36,
        )),
        lines: field-scene-lines(
          seeds,
          tracing: spatial-field-line-tracing(step: 0.03, max-steps: 240),
          style: field-line-style(
            thickness: 0.65,
            arrow-size: 3,
            arrow-spacing: 44,
          ),
        ),
      ),
    ),
    scene-legend(color),
    text(size: 7pt, fill: rgb("#475569"))[#note Slice colors show the full field
      magnitude.],
  ),
)

// Seed positions are world coordinates, deliberately displaced from the z = 0 slice.
#let sheet-seeds = {
  let seeds = ()
  for y in (-0.6, 0, 0.6) {
    for z in (-0.4, 0.4) { seeds.push((0.3, y, z)) }
  }
  seeds
}

#let scene-for(color: magnitude-colors(), curve-radius: 0.025) = field-scene(
  camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
  curve-radius: curve-radius,
  slice: field-scene-slice(
    color: color,
    opacity: 0.65,
    samples: (48, 36),
  ),
  lines: field-scene-lines(
    sheet-seeds,
    tracing: spatial-field-line-tracing(max-steps: 600),
  ),
)

#let scene-panel(
  name,
  title,
  note: [],
  color: magnitude-colors(),
  curve-radius: 0.025,
) = {
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
          color: color,
          curve-radius: curve-radius,
        ),
      ),
      scene-legend(color),
      text(size: 7pt, fill: rgb("#475569"))[#note Slice colors show the full
        field magnitude.],
    ),
  )
}
