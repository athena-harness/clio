// Source descriptions and byte interfaces; all field computation runs in Rust.
#import "render.typ": backend, field-colors, field-grid, field-plane, hex-color

/// Create a signed point charge at a world-space position.
#let point-charge(position, charge: 1) = (
  kind: "point",
  position: position,
  charge: charge,
)

/// Create a uniform line charge with configurable midpoint integration samples.
#let charged-segment(start, end, density: 1, samples: 64) = (
  kind: "segment",
  start: start,
  end: end,
  density: density,
  samples: samples,
)

/// Create a uniform annulus; plane axes orient its surface in world space.
#let charged-annulus(
  inner-radius,
  outer-radius,
  density: 1,
  plane: field-plane(),
  radial-samples: 32,
  angular-samples: 64,
) = (
  kind: "annulus",
  plane: plane,
  inner-radius: inner-radius,
  outer-radius: outer-radius,
  density: density,
  radial-samples: radial-samples,
  angular-samples: angular-samples,
)

/// Create a uniform disk using the same quadrature as an annulus.
#let charged-disk(radius, ..options) = charged-annulus(0, radius, ..options)

/// Integrate an infinite charged plane outside a circular hole using a compact radial coordinate.
#let charged-plane-with-hole(
  hole-radius,
  density: 1,
  plane: field-plane(),
  radial-samples: 32,
  angular-samples: 64,
) = (
  kind: "plane-with-hole",
  plane: plane,
  hole-radius: hole-radius,
  density: density,
  radial-samples: radial-samples,
  angular-samples: angular-samples,
)

/// Configure the physical multiplier and Plummer regularization length.
#let field-parameters(coulomb-constant: 1, softening: 0.02) = (
  coulomb-constant: coulomb-constant,
  softening: softening,
)

/// Display the full three-dimensional field magnitude.
#let field-magnitude() = (kind: "magnitude")

/// Display a signed component along a world-space unit direction.
#let field-component(direction) = (kind: "component", direction: direction)

/// Style source masks with a color and full thickness in world-space length units.
#let source-style(color: "#ede9fe", thickness: 0.1) = (
  color: hex-color(color),
  thickness: thickness,
)

/// Enable source masks; overrides contain (source: index, style: source-style()) records.
#let source-overlay(color: "#ede9fe", thickness: 0.1, overrides: ()) = (
  style: source-style(color: color, thickness: thickness),
  overrides: overrides,
)

/// Compute an electric field in Rust and return SVG bytes with vector source masks.
#let electric-field-heatmap-bytes(
  sources,
  grid: field-grid(),
  field: field-parameters(),
  quantity: field-magnitude(),
  color: field-colors(),
  singularity-color: "#00000000",
  source-overlay: none,
) = backend.render_electric_field(bytes(json.encode((
  sources: sources,
  grid: grid,
  field: field,
  quantity: quantity,
  color: color,
  singularity-color: hex-color(singularity-color),
  source-overlay: source-overlay,
))))

/// Display an electric-field SVG without imposing labels, figures, or page layout.
#let electric-field-heatmap(sources, width: 100%, ..options) = image(
  electric-field-heatmap-bytes(sources, ..options),
  format: "svg",
  width: width,
)

/// Generate explicit local seed coordinates in Rust.
#let seed-points(points) = (kind: "points", points: points)

/// Generate equally spaced seeds around a local circle in Rust; phase uses radians.
#let seed-circle(center, radius: 0.14, count: 24, phase: 0) = (
  kind: "circle",
  center: center,
  radius: radius,
  count: count,
  phase: phase,
)

/// Generate local seeds along a segment, including both endpoints.
#let seed-segment(start, end, count: 24) = (
  kind: "segment",
  start: start,
  end: end,
  count: count,
)

/// Configure fixed-step RK4 and termination independently of rendering resolution.
#let field-line-tracing(
  step: 0.02,
  max-steps: 2000,
  min-field: 0.00000001,
  source-radius: 0.08,
  direction: "both",
  mode: "planar",
  plane-tolerance: 0.000001,
) = (
  step: step,
  max-steps: max-steps,
  min-field: min-field,
  source-radius: source-radius,
  direction: direction,
  mode: mode,
  plane-tolerance: plane-tolerance,
)

/// Configure SVG stroke and physical-direction arrows in output pixels.
#let field-line-style(
  color: "#1e293b",
  thickness: 1.1,
  arrow-spacing: 36,
  arrow-size: 5,
) = (
  color: hex-color(color),
  width: thickness,
  arrow-spacing: arrow-spacing,
  arrow-size: arrow-size,
)

/// Use a solid or transparent background for field lines.
#let field-line-background(color: white) = (
  kind: "solid",
  color: hex-color(color),
)

/// Place field lines above a field-magnitude heatmap computed in Rust.
#let field-line-heatmap(color: field-colors()) = (kind: "heatmap", color: color)

/// Trace electric-field lines in Rust and return self-contained SVG bytes.
#let electric-field-lines-bytes(
  sources,
  seeds,
  grid: field-grid(resolution: (480, 360)),
  field: field-parameters(),
  tracing: field-line-tracing(),
  style: field-line-style(),
  background: field-line-background(),
  source-overlay: none,
) = backend.render_electric_field_lines(bytes(json.encode((
  sources: sources,
  seeds: seeds,
  grid: grid,
  field: field,
  tracing: tracing,
  style: style,
  background: background,
  source-overlay: source-overlay,
))))

/// Display electric-field lines without imposing document layout or captions.
#let electric-field-lines(sources, seeds, width: 100%, ..options) = image(
  electric-field-lines-bytes(sources, seeds, ..options),
  format: "svg",
  width: width,
)
