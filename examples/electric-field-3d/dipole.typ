#import "../../lib.typ": *
#import "../electric-field/common.typ": magnitude-colors, plot-field

#let charges = (
  point-charge((-0.7, 0, 0)),
  point-charge((0.7, 0, 0), charge: -1),
)
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
          color: magnitude-colors(),
          opacity: 0.55,
          samples: (48, 36),
        ),
        lines: field-scene-lines(seeds),
      ),
    ),
    text(size: 7pt, fill: rgb("#475569"))[
      Twelve seeds encircle the dipole axis in space. Red: positive charge;
      blue: negative charge. The colored plane samples field magnitude.
    ],
  ),
)
