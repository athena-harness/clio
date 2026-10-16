// Spatial presentation shares the planar renderer's sources and physical field.
#import "render.typ": backend, field-grid, hex-color
#import "electrostatics.typ": field-line-style, field-parameters

/// Orthographic view; angles use radians, span uses world-space length units.
#let field-camera(
  target: (0, 0, 0),
  azimuth: -1.05,
  elevation: 0.48,
  span: 5,
) = (
  target: target,
  azimuth: azimuth,
  elevation: elevation,
  span: span,
)

/// A pale observation plane, or a field-magnitude slice using a shared color scale.
#let field-scene-slice(color: none, opacity: 0.2, samples: (32, 24)) = (
  color: color,
  opacity: opacity,
  samples: samples,
)

/// Full-vector RK4 settings; no planar projection or planarity tolerance applies.
#let spatial-field-line-tracing(
  step: 0.025,
  max-steps: 1000,
  min-field: 0.00000001,
  source-radius: 0.04,
  direction: "both",
) = (
  step: step,
  max-steps: max-steps,
  min-field: min-field,
  source-radius: source-radius,
  direction: direction,
)

/// Explicit world-space seeds; image resolution and camera never alter integration.
#let field-scene-lines(
  seeds,
  tracing: spatial-field-line-tracing(),
  style: field-line-style(thickness: 0.7, arrow-size: 3, arrow-spacing: 45),
) = (seeds: seeds, tracing: tracing, style: style)

/// Spatial context configuration, independent of planar masks and source quadrature.
#let field-scene(
  resolution: (640, 480),
  bounds: ((-2, -1.5, -1.5), (2, 1.5, 1.5)),
  camera: field-camera(),
  source-colors: ("#8b5cf699", "#14b8a699"),
  source-thickness: 0.6,
  curve-radius: 0.02,
  point-size: 3,
  slice: field-scene-slice(),
  lines: none,
  axes: true,
) = (
  resolution: resolution,
  bounds: bounds,
  camera: camera,
  source-colors: source-colors.map(hex-color),
  source-thickness: source-thickness,
  curve-radius: curve-radius,
  point-size: point-size,
  slice: slice,
  lines: lines,
  axes: axes,
)

/// Render complete source geometry and optional spatial field lines as vector SVG.
#let electric-field-scene-bytes(
  sources,
  grid: field-grid(),
  field: field-parameters(),
  scene: field-scene(),
) = backend.render_electric_field_scene(bytes(json.encode((
  sources: sources,
  grid: grid,
  field: field,
  scene: scene,
))))

/// Display a standalone spatial view; Typst retains control of captions and layout.
#let electric-field-scene(sources, width: 100%, ..options) = image(
  electric-field-scene-bytes(sources, ..options),
  format: "svg",
  width: width,
)
