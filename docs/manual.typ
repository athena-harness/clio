#import "../lib.typ": *
#import "style.typ": *
#show: manual-style

#let version = toml("../typst.toml").package.version
#let charges = (
  point-charge((-0.7, 0, 0)),
  point-charge((0.7, 0, 0), charge: -1),
)
#let palette = field-colors(range: (0, 12))
#let seeds = (seed-circle((-0.7, 0), count: 18),)

#v(12mm)
#align(center)[
  #text(font: "DejaVu Sans Mono", size: 40pt, weight: "bold")[clio]
  #v(3mm)
  #text(size: 16pt)[Mathematical and physical diagrams]
  #v(1mm)
  #text(size: 11pt, fill: muted)[A Typst library with a Rust and WebAssembly
    backend]
  #v(10mm)
  #electric-field-lines(
    charges,
    seeds,
    grid: field-grid(resolution: (480, 360)),
    background: field-line-heatmap(color: palette),
    style: field-line-style(color: white, thickness: 1, arrow-size: 4),
    width: 88%,
  )
  #v(8mm)
  #text(size: 12pt)[User guide and function reference]
  #text(fill: muted)[Version #version]
]
#v(1fr)
#align(center, text(size: 9pt, fill: muted)[
  Rust computes fields and images. Typst supplies equations, labels, and layout.
])
#pagebreak()

= Contents <contents>

#grid(
  columns: (1fr, 1fr),
  gutter: 10mm,
  [
    #text(size: 13pt, weight: "bold")[Guide]
    #outline(
      title: none,
      target: selector(heading)
        .before(<function-reference>, inclusive: false)
        .after(<contents>, inclusive: false),
      depth: 2,
    )
  ],
  [
    #text(size: 13pt, weight: "bold")[Reference]
    #set text(size: 8pt)
    #outline(
      title: none,
      target: selector(heading).after(<function-reference>, inclusive: false),
      depth: 3,
    )
  ],
)
#pagebreak()

= Getting started

Clio evaluates electric fields from prescribed point charges and continuous
charge distributions. Its Rust backend integrates the sources, samples the
field, and returns SVG diagrams through a byte-only WebAssembly interface. The
Typst layer provides composable configuration dictionaries and image content
that fits into ordinary documents.

== Build and import

From the repository root, build the plugin and compile this manual:

```sh
bash scripts/build-plugin.sh
typst compile --root . docs/manual.typ /tmp/clio-manual.pdf
```

The build script produces `wasm/clio.wasm`. Import `lib.typ` relative to your
document; the examples below assume a document at the repository root. The Rust
plugin receives JSON bytes and returns image bytes; it does not read or write
files. Typst retains control of display size, labels, formulas, and captions.

== A dipole heatmap

Define the sources once, then choose the sampling grid and color mapping. The
image width changes its placement in the document; it does not change the number
of field samples.

#code-example(
  ```typ
  #import "lib.typ": *
  #let charges = (
    point-charge((-0.7, 0, 0)),
    point-charge((0.7, 0, 0),
      charge: -1),
  )
  #let palette = field-colors(
    range: (0, 12),
  )
  #electric-field-heatmap(
    charges,
    grid: field-grid(
      resolution: (240, 180),
    ),
    color: palette,
  )
  ```,
  electric-field-heatmap(
    charges,
    grid: field-grid(resolution: (240, 180)),
    color: palette,
  ),
  caption: [A positive and a negative unit charge in the default observation
    plane.],
)

#pagebreak()
== Trace the same field

Use the same sources and bounds for a matching field-line view. Seeds and
tracing accuracy are independent of the output resolution. Arrows follow the
electric field from positive toward negative charge.

#code-example(
  ```typ
  #electric-field-lines(
    charges,
    (seed-circle((-0.7, 0),
      count: 18),),
    grid: field-grid(
      resolution: (360, 270),
    ),
    style: field-line-style(
      arrow-size: 4,
    ),
  )
  ```,
  electric-field-lines(
    charges,
    seeds,
    grid: field-grid(resolution: (360, 270)),
    style: field-line-style(arrow-size: 4),
  ),
  caption: [A normalized-field RK4 trace, not a charged particle trajectory.],
)

== Choose configuration by responsibility

Source constructors describe geometry and quadrature. #fn("field-grid") sets the
observation frame and raster sampling. #fn("field-parameters") sets physical
scaling and regularization. Heatmaps select a scalar and palette; field lines
select seeds, tracing controls, and stroke styles. #fn("source-overlay") gives
physical objects their own configurable color, separate from the field palette.

For sampling, adjust #param("field-grid", "resolution") to refine the image, and
#param("charged-annulus", "radial-samples") or #param(
  "charged-annulus",
  "angular-samples",
) to refine surface integration.

The next chapters describe numerical assumptions, examples, and limits. The
@function-reference lists every public constructor and renderer. Inline function
names link to their reference entries.

#include "electric-field.typ"
#include "electric-field-lines.typ"
#include "custom-geometry.typ"
#include "spatial-views.typ"
#pagebreak()
= Function reference <function-reference>

Import the public API from `lib.typ`. Constructors return plain dictionaries;
the renderer serializes them to JSON and evaluates them in Rust. Positional
parameters are required unless their signature supplies a default. Coordinates,
charges, and lengths use one consistent unit system chosen by the caller.

#include "reference.typ"

#v(10pt)
#block(text(size: 8pt, fill: muted)[
  *About this manual.*

  This manual is written entirely in Typst. Its guide/reference organization,
  code-and-output examples, and linked API entries take inspiration from the
  #link(
    "https://github.com/fletcher-package/fletcher/blob/main/docs/manual.typ",
  )[Fletcher manual]. The local styles in `docs/style.typ` require no external
  documentation package. All displayed field diagrams are rendered by Clio
  during compilation.
])
