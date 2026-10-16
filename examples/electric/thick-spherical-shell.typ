#import "../../lib.typ": *
#import "common.typ": integration-detail, sample-height, sample-width

// Density is charge per physical volume; Rust supplies the spherical Jacobian.
#let inner-radius = 0.6
#let outer-radius = 1
#let volume-density = 1
#let volume-samples = (4, 16, 32).map(n => n * integration-detail)
#let thick-shell-sources = (
  charged-volume(
    ("u*sin(v)*cos(w)", "u*sin(v)*sin(w)", "u*cos(v)"),
    bounds: ((inner-radius, outer-radius), (0, calc.pi), (0, 2 * calc.pi)),
    density: volume-density,
    samples: volume-samples,
  ),
)
#let thick-shell-grid = field-grid(
  resolution: (sample-width, sample-height),
  bounds: (-2, 2, -1.5, 1.5),
)
#let thick-shell-field = field-parameters(softening: 0.06)
#let thick-shell-colors = field-colors(range: (0, 3.5), scale: linear-scale())
// The zero-density annulus marks the exact equatorial section without adding field.
// This avoids an expensive volumetric distance contour for a known round section.
#let thick-shell-plot-sources = (
  thick-shell-sources
    + (
      charged-annulus(
        inner-radius,
        outer-radius,
        density: 0,
        radial-samples: 1,
        angular-samples: 4,
      ),
    )
)
#let thick-shell-overlay = source-overlay(
  color: "#a78bfa55",
  thickness: 0.025,
  overrides: ((source: 0, style: none),),
)

// Follow the nonzero field outward from the charged layer, leaving the cavity unseeded.
#let seed-radius = inner-radius + 0.12 * (outer-radius - inner-radius)
#let thick-shell-seeds = (seed-circle((0, 0), radius: seed-radius, count: 24),)
#let thick-shell-tracing = field-line-tracing(
  step: 0.025,
  max-steps: 160,
  source-radius: 0,
  direction: "forward",
)
#let thick-shell-spatial-seeds = range(16).map(i => {
  let z = 1 - 2 * (i + 0.5) / 16
  let angle = i * calc.pi * (3 - calc.sqrt(5))
  let radial = calc.sqrt(1 - z * z)
  (
    seed-radius * radial * calc.cos(angle),
    seed-radius * radial * calc.sin(angle),
    seed-radius * z,
  )
})
#let thick-shell-scene = field-scene(
  camera: field-camera(azimuth: -1.12, elevation: 0.48, span: 5.4),
  source-colors: ("#a78bfa44",),
  source-thickness: 0.35,
  slice: field-scene-slice(
    color: thick-shell-colors,
    opacity: 0.6,
    samples: (48, 36),
  ),
  lines: field-scene-lines(
    thick-shell-spatial-seeds,
    tracing: spatial-field-line-tracing(
      step: 0.025,
      max-steps: 160,
      source-radius: 0,
      direction: "forward",
    ),
    style: field-line-style(thickness: 0.65, arrow-size: 3, arrow-spacing: 40),
  ),
)

// All available views of this object share one example module.
#let heatmap() = [
  #import "../../lib.typ": *
  #import "common.typ": example-panel

  #example-panel(
    [Thick spherical shell: magnitude],
    thick-shell-plot-sources,
    description: [Uniform volume charge between two radii; the cavity contains
      no charge.],
    formula: [$a = 0.6, b = 1, rho = 1$],
    grid: thick-shell-grid,
    field: thick-shell-field,
    color: thick-shell-colors,
    overlay: thick-shell-overlay,
    note: [The translucent purple annulus marks the charged material. Softening
      and finite quadrature leave residual cavity fields.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "common.typ": example-panel

  #let line-grid = {
    let result = thick-shell-grid
    result.resolution = (480, 360)
    result
  }
  #example-panel(
    [Thick spherical shell: field lines],
    thick-shell-sources,
    grid: thick-shell-grid,
    description: [Seeds lie inside the charged layer and follow the field
      outward.],
    formula: [$Q = 4 pi rho (b^3 - a^3) / 3$],
    legend: false,
    note: [Source capture is disabled so lines cross the charged volume. Seed
      density is not calibrated to electric flux.],
    plot: electric-field-lines(
      thick-shell-plot-sources,
      thick-shell-seeds,
      grid: line-grid,
      field: thick-shell-field,
      tracing: thick-shell-tracing,
      style: field-line-style(thickness: 0.7, arrow-size: 3, arrow-spacing: 38),
      source-overlay: thick-shell-overlay,
    ),
  )

]

#let spatial() = [
  #import "../../lib.typ": *
  #import "spatial-common.typ": scene-legend

  #electric-field-scene(
    thick-shell-sources,
    grid: thick-shell-grid,
    field: thick-shell-field,
    scene: thick-shell-scene,
  )

  #scene-legend(thick-shell-colors)
]

#context [
  // Standalone volume-shell example, also included by gallery.typ.

  #set page(paper: "a4", margin: 15mm)
  #set text(size: 9pt)

  = Clio / Thick spherical shell with volume charge

  A uniform volume density fills $a < r < b$, leaving an empty central cavity.
  Relative units; $a = 0.6$, $b = 1$, $rho = 1$, $k_e = 1$, $epsilon = 0.06$.
  Integration: #volume-samples.at(0) radial × #volume-samples.at(1) polar ×
  #volume-samples.at(2) azimuthal midpoint samples, using one `charged-volume`
  model.

  #grid(
    columns: (1fr, 1fr),
    gutter: 10pt,
    heatmap(), field-lines(),
  )

  == Spatial boundaries and the equatorial slice

  #if sys.inputs.at("show-3d", default: "true") == "true" {
    align(center, block(width: 50%)[
      #spatial()
    ])
  } else {
    [The spatial view is disabled by `show-3d=false`.]
  }

  Both translucent spherical boundaries belong to the same charged volume. The
  equatorial heatmap shows the cavity and the charged layer; spatial lines start
  in the layer and continue outward. The display mesh is a finite approximation.
  The planar annulus is a zero-density section marker and adds no electric
  field.

  == Ideal reference

  For an unregularized continuous distribution, the field magnitude is

  $
    E(r) = cases(
      0 & "for" r < a,
      (4 pi k_e rho) / 3 (r - a^3 / r^2) & "for" a <= r <= b,
      (4 pi k_e rho (b^3 - a^3)) / (3 r^2) & "for" r > b,
    ).
  $

  The ideal field is continuous at both radii, grows through the charged layer,
  and decays as $1/r^2$ outside. The cavity is field-free in the ideal model.
  All displayed values come from Rust quadrature, without an analytic zero-field
  override. Source samples and softening are configured independently in the
  shared model; `--input show-3d=false` hides the spatial view.

]
