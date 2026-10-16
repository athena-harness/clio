#import "../../lib.typ": *
#import "common.typ": integration-detail, sample-height, sample-width

// Midpoint quadrature avoids the polar coordinate singularities at u = 0 and pi.
#let shell-radius = 1
#let shell-density = 1
#let shell-sources = (
  charged-surface(
    ("R*sin(u)*cos(v)", "R*sin(u)*sin(v)", "R*cos(u)"),
    bounds: ((0, calc.pi), (0, 2 * calc.pi)),
    density: shell-density,
    samples: (32 * integration-detail, 64 * integration-detail),
    constants: (R: shell-radius),
  ),
)
#let shell-grid = field-grid(
  resolution: (sample-width, sample-height),
  bounds: (-2, 2, -1.5, 1.5),
)
#let shell-field = field-parameters(softening: 0.04)
#let shell-colors = field-colors(range: (0, 14), scale: linear-scale())
#let shell-overlay = source-overlay(color: "#a78bfa", thickness: 0.025)

// Seeds remain outside the shell, where the ideal field is nonzero.
#let shell-seeds = (
  seed-circle((0, 0), radius: 1.12 * shell-radius, count: 24),
)
#let shell-tracing = field-line-tracing(
  step: 0.025,
  max-steps: 200,
  source-radius: 0.03,
)

// A Fibonacci distribution avoids coincident polar seeds in the spatial view.
#let shell-spatial-seeds = range(16).map(i => {
  let z = 1 - 2 * (i + 0.5) / 16
  let angle = i * calc.pi * (3 - calc.sqrt(5))
  let radial = calc.sqrt(1 - z * z)
  let radius = 1.12 * shell-radius
  (
    radius * radial * calc.cos(angle),
    radius * radial * calc.sin(angle),
    radius * z,
  )
})
#let shell-scene = field-scene(
  camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
  source-colors: ("#a78bfa55",),
  source-thickness: 0.35,
  slice: field-scene-slice(color: shell-colors, opacity: 0.6, samples: (
    48,
    36,
  )),
  lines: field-scene-lines(
    shell-spatial-seeds,
    tracing: spatial-field-line-tracing(
      step: 0.025,
      max-steps: 200,
      source-radius: 0.03,
    ),
    style: field-line-style(thickness: 0.65, arrow-size: 3, arrow-spacing: 40),
  ),
)

// All available views of this object share one example module.
#let heatmap() = [
  #import "../../lib.typ": *
  #import "common.typ": example-panel

  #example-panel(
    [Uniform spherical shell: magnitude],
    shell-sources,
    description: [A complete parameterized surface; the purple circle is its
      equatorial section.],
    formula: [$R = 1, sigma = 1, k_e = 1$],
    grid: shell-grid,
    field: shell-field,
    color: shell-colors,
    overlay: shell-overlay,
    note: [The ideal interior field vanishes. Finite quadrature and softening
      leave a residual, especially near the shell.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "common.typ": example-panel

  #let line-grid = {
    let result = shell-grid
    result.resolution = (480, 360)
    result
  }

  #example-panel(
    [Uniform spherical shell: field lines],
    shell-sources,
    grid: shell-grid,
    description: [Exterior seeds trace outward radial lines and capture the
      source backward.],
    formula: [$Q = 4 pi R^2 sigma$],
    legend: false,
    note: [No interior seeds are placed: small numerical residuals should not be
      read as physical interior field lines.],
    plot: electric-field-lines(
      shell-sources,
      shell-seeds,
      grid: line-grid,
      field: shell-field,
      tracing: shell-tracing,
      style: field-line-style(thickness: 0.7, arrow-size: 3, arrow-spacing: 38),
      source-overlay: shell-overlay,
    ),
  )

]

#let spatial() = [
  #import "../../lib.typ": *
  #import "spatial-common.typ": scene-legend

  #electric-field-scene(
    shell-sources,
    grid: shell-grid,
    field: shell-field,
    scene: shell-scene,
  )

  #scene-legend(shell-colors)
]

#context [
  // Standalone spherical-shell example; this page is also included by gallery.typ.
  #import "common.typ": integration-detail

  #set page(paper: "a4", margin: 15mm)
  #set text(size: 9pt)

  = Clio / Uniformly charged spherical shell

  One complete surface model feeds the heatmap, planar lines, and spatial view.
  Relative units; $R = 1$, $sigma = 1$, $k_e = 1$, $epsilon = 0.04$.
  Integration: #(32 * integration-detail) polar × #(64 * integration-detail)
  azimuthal midpoint samples. Purple marks the charged shell, not a filled
  sphere.

  #grid(
    columns: (1fr, 1fr),
    gutter: 10pt,
    heatmap(), field-lines(),
  )

  == Spatial geometry and the equatorial heatmap

  #if sys.inputs.at("show-3d", default: "true") == "true" {
    align(center, block(width: 45%)[
      #spatial()
    ])
  } else {
    [The spatial view is disabled by `show-3d=false`.]
  }

  The translucent surface shows the complete shell. Sixteen exterior seeds
  follow the full three-dimensional field; the colored plane samples its
  magnitude. The slice uses the same range and palette as the planar heatmap.

  == Ideal reference

  For an unregularized continuous shell, away from its surface,

  $ E(r) = cases(0 & "for" r < R, (4 pi k_e sigma R^2) / r^2 & "for" r > R). $

  The exterior field equals that of the total charge at the center. The value on
  the ideal charged surface is discontinuous and is not assigned here.

  Generic Rust surface quadrature supplies every diagram, with no analytic
  interior-zero override. Use `--input integration-detail=2` for more source
  samples; adjust softening independently in the shared model. Use
  `--input show-3d=false` to omit the spatial view.

]
