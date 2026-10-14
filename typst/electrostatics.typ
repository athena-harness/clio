// Source descriptions and byte interfaces; all field computation runs in Rust.
#import "render.typ": backend, field-plane, field-grid, field-colors, hex-color

/// Create a signed point charge at a world-space position.
#let point-charge(position, charge: 1) = (
  kind: "point", position: position, charge: charge,
)

/// Create a uniform line charge with configurable midpoint integration samples.
#let charged-segment(start, end, density: 1, samples: 64) = (
  kind: "segment", start: start, end: end, density: density, samples: samples,
)

/// Create a uniform annulus; plane axes orient its surface in world space.
#let charged-annulus(
  inner-radius, outer-radius, density: 1, plane: field-plane(),
  radial-samples: 32, angular-samples: 64,
) = (
  kind: "annulus", plane: plane, inner-radius: inner-radius,
  outer-radius: outer-radius, density: density,
  radial-samples: radial-samples, angular-samples: angular-samples,
)

/// Create a uniform disk using the same quadrature as an annulus.
#let charged-disk(radius, ..options) = charged-annulus(0, radius, ..options)

/// Integrate an infinite charged plane outside a circular hole using a compact radial coordinate.
#let charged-plane-with-hole(
  hole-radius, density: 1, plane: field-plane(),
  radial-samples: 32, angular-samples: 64,
) = (
  kind: "plane-with-hole", plane: plane, hole-radius: hole-radius,
  density: density, radial-samples: radial-samples, angular-samples: angular-samples,
)

/// Configure the physical multiplier and Plummer regularization length.
#let field-parameters(coulomb-constant: 1, softening: 0.02) = (
  coulomb-constant: coulomb-constant, softening: softening,
)

/// Display the full three-dimensional field magnitude.
#let field-magnitude() = (kind: "magnitude")

/// Display a signed component along a world-space unit direction.
#let field-component(direction) = (kind: "component", direction: direction)

/// Style source masks with a color and full thickness in world-space length units.
#let source-style(color: "#ede9fe", thickness: 0.1) = (
  color: hex-color(color), thickness: thickness,
)

/// Enable source masks; overrides contain (source: index, style: source-style()) records.
#let source-overlay(color: "#ede9fe", thickness: 0.1, overrides: ()) = (
  style: source-style(color: color, thickness: thickness), overrides: overrides,
)

/// Compute an electric field in Rust and return PNG bytes.
#let electric-field-heatmap-bytes(
  sources, grid: field-grid(), field: field-parameters(),
  quantity: field-magnitude(), color: field-colors(),
  singularity-color: "#00000000",
  source-overlay: none,
) = backend.render_electric_field(bytes(json.encode((
  sources: sources, grid: grid, field: field, quantity: quantity, color: color,
  singularity-color: hex-color(singularity-color),
  source-overlay: source-overlay,
))))

/// Display an electric-field PNG without imposing labels, figures, or page layout.
#let electric-field-heatmap(sources, width: 100%, ..options) = image(
  electric-field-heatmap-bytes(sources, ..options), format: "png", width: width,
)
