// Shared rendering configuration, independent of any physical model.
#let backend = plugin("../wasm/clio.wasm")

/// Create an orthonormal world-space plane; coordinates use caller-selected units.
#let field-plane(
  origin: (0, 0, 0),
  horizontal: (1, 0, 0),
  vertical: (0, 1, 0),
) = (origin: origin, horizontal: horizontal, vertical: vertical)

/// Configure heatmap pixel counts and observation coordinates independently.
#let field-grid(
  resolution: (141, 109),
  bounds: (-2, 2, -1.5, 1.5),
  plane: field-plane(),
  sampling: "centers",
) = (resolution: resolution, bounds: bounds, plane: plane, sampling: sampling)

/// Use a linear field-to-color coordinate.
#let linear-scale() = (kind: "linear")

/// Use sign(v) * ln(1 + abs(v)/reference), including signed components.
#let logarithmic-scale(reference: 1) = (kind: "log", reference: reference)

/// Use asinh(v/reference), including signed components.
#let asinh-scale(reference: 1) = (kind: "asinh", reference: reference)

#let hex-color(value) = rgb(value).to-hex()

/// Share one explicit color range and palette between heatmaps and colorbars.
#let field-colors(
  range: (0, 10),
  scale: logarithmic-scale(),
  stops: ("#163b78", "#3fa7a0", "#f0e65b", "#f6a13a", "#d94732"),
  space: "oklab",
) = (range: range, transform: scale, stops: stops.map(hex-color), space: space)

/// Return independent SVG gradient bytes; values increase left-to-right or bottom-to-top.
#let field-colorbar-bytes(
  color: field-colors(),
  resolution: (256, 16),
  orientation: "horizontal",
) = backend.render_colorbar(bytes(json.encode((
  color: color,
  resolution: resolution,
  orientation: orientation,
))))

/// Display a colorbar; tick labels and captions can be composed by the caller.
#let field-colorbar(width: 50%, ..options) = image(
  field-colorbar-bytes(..options),
  format: "svg",
  width: width,
)
