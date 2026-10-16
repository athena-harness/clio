// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, magnitude-colors, mask-thickness

  #example-panel(
    [Electric dipole],
    sources-for("dipole"),
    grid: grid-for("dipole"),
    description: [Equal opposite charges with zero net charge.],
    formula: [$q_1 = +1, quad q_2 = -1, quad d = 1.4$],
    color: magnitude-colors(maximum: 8),
    overlay: source-overlay(
      color: "#ede9fe",
      thickness: mask-thickness,
      overrides: (
        (
          source: 1,
          style: source-style(color: "#bae6fd", thickness: mask-thickness),
        ),
      ),
    ),
    note: [The field adds between the charges; its distant magnitude decays
      faster than a monopole.],
  )

]

#let field-lines() = [
  #import "models.typ": sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, example-tracing, magnitude-colors, mask-thickness,
  )
  #import "line-common.typ": line-field, line-grid-for

  #let line-grid = line-grid-for("dipole")
  #let sources = sources-for("dipole")
  #let colors = magnitude-colors(maximum: 8)
  #example-panel(
    [Dipole lines on a heatmap],
    sources,
    grid: line-grid,
    description: [Curves follow the electric field from positive to negative
      charge.],
    formula: [$q_1 = +1, quad q_2 = -1$],
    color: colors,
    note: [The heatmap shows magnitude. White arrows follow the vector field,
      independently of the logarithmic colors.],
    plot: electric-field-lines(
      sources,
      (seed-circle((-0.7, 0), count: 24),),
      grid: line-grid,
      field: line-field,
      tracing: example-tracing(),
      style: field-line-style(color: white, thickness: 1.2),
      background: field-line-heatmap(color: colors),
      source-overlay: source-overlay(
        color: "#8b5cf6",
        thickness: mask-thickness,
        overrides: (
          (
            source: 1,
            style: source-style(color: "#38bdf8", thickness: mask-thickness),
          ),
        ),
      ),
    ),
  )

]

#let spatial() = [
  #import "../../lib.typ": *
  #import "common.typ": magnitude-colors, plot-field
  #import "models.typ": sources-for
  #import "spatial-common.typ": scene-legend

  #let charges = sources-for("dipole")
  #let seeds = range(12).map(i => {
    let angle = i * 2 * calc.pi / 12
    (-0.55, 0.18 * calc.cos(angle), 0.18 * calc.sin(angle))
  })

  #block(
    width: 100%,
    breakable: false,
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#dce2e9"),
    grid(
      columns: 1,
      row-gutter: 4pt,
      text(size: 11pt, weight: "bold")[Dipole: spatial field lines],
      electric-field-scene(
        charges,
        field: plot-field,
        scene: field-scene(
          camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
          source-colors: ("#dc5043", "#3769be"),
          slice: field-scene-slice(
            color: magnitude-colors(maximum: 8),
            opacity: 0.55,
            samples: (48, 36),
          ),
          lines: field-scene-lines(seeds),
        ),
      ),
      scene-legend(magnitude-colors(maximum: 8)),
      text(size: 7pt, fill: rgb("#475569"))[
        Twelve seeds encircle the dipole axis in space. Red: positive charge;
        blue: negative charge. The colored plane samples field magnitude.
      ],
    ),
  )

]

#import "common.typ": object-example

#context object-example([Dipole], heatmap, field-lines, spatial: spatial)
