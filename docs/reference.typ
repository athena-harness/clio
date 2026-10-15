#import "style.typ": api

== Observation and physical parameters

#api(
  "field-plane",
  "field-plane(origin: (0, 0, 0), horizontal: (1, 0, 0), vertical: (0, 1, 0))",
  returns: "dictionary",
  parameters: (
    ("origin", "array", "(0, 0, 0)", [World-space origin as three numbers.]),
    ("horizontal", "array", "(1, 0, 0)", [Horizontal world-space unit vector.]),
    ("vertical", "array", "(0, 1, 0)", [Vertical world-space unit vector.]),
  ),
)[Create an orthonormal observation or source plane. World coordinates are
  origin + u horizontal + v vertical; both axes must be perpendicular unit
  vectors.]

#api(
  "field-grid",
  "field-grid(\n  resolution: (141, 109),\n  bounds: (-2, 2, -1.5, 1.5),\n  plane: field-plane(),\n  sampling: \"centers\",\n)",
  returns: "dictionary",
  parameters: (
    (
      "resolution",
      "array",
      "(141, 109)",
      [Positive integer pixel counts (width, height).],
    ),
    (
      "bounds",
      "array",
      "(-2, 2, -1.5, 1.5)",
      [Local bounds (u-min, u-max, v-min, v-max), strictly increasing on each
        axis.],
    ),
    (
      "plane",
      "dictionary",
      "field-plane()",
      [Observation or source frame from field-plane().],
    ),
    (
      "sampling",
      "string",
      "\"centers\"",
      ["centers" samples pixel centers; "endpoints" includes rectangle edges.],
    ),
  ),
)[Choose the raster resolution and local observation rectangle. Pixel sampling
  and continuous-source quadrature are independent. Equal world-space lengths
  need matching pixel and display aspect ratios.]

#api(
  "field-parameters",
  "field-parameters(coulomb-constant: 1, softening: 0.02)",
  returns: "dictionary",
  parameters: (
    (
      "coulomb-constant",
      "number",
      "1",
      [Coulomb multiplier; default uses relative units.],
    ),
    (
      "softening",
      "number",
      "0.02",
      [Nonnegative regularization length in world units.],
    ),
  ),
)[Set the Coulomb multiplier and Plummer regularization length. Choose one
  consistent system of units for every source and coordinate.]

#api(
  "field-magnitude",
  "field-magnitude()",
  returns: "dictionary",
  parameters: (),
)[Select the magnitude of the full three-dimensional vector field, including its
  component normal to the observation plane.]

#api(
  "field-component",
  "field-component(direction)",
  returns: "dictionary",
  parameters: (
    (
      "direction",
      "array",
      "required",
      [World-space unit vector of the scalar component.],
    ),
  ),
)[Select the signed dot product of the field with a world-space unit direction.
  Use a diverging palette for positive and negative values.]

== Charge sources

#api(
  "point-charge",
  "point-charge(position, charge: 1)",
  returns: "dictionary",
  parameters: (
    ("position", "array", "required", [World-space position as three numbers.]),
    ("charge", "number", "1", [Signed total charge.]),
  ),
)[Describe a signed point charge at a world-space position.]

#api(
  "charged-segment",
  "charged-segment(start, end, density: 1, samples: 64)",
  returns: "dictionary",
  parameters: (
    (
      "start",
      "array",
      "required",
      [First endpoint; world-space 3D for sources, local 2D for seeds.],
    ),
    (
      "end",
      "array",
      "required",
      [Second endpoint; same coordinate system as start.],
    ),
    ("density", "number", "1", [Signed charge per unit length or unit area.]),
    (
      "samples",
      "integer",
      "64",
      [Positive midpoint quadrature count for the segment.],
    ),
  ),
)[Describe a uniformly charged finite segment. Rust integrates its field with
  midpoint quadrature; density is charge per unit length.]

#api(
  "charged-disk",
  "charged-disk(radius, ..options)",
  returns: "dictionary",
  parameters: (
    ("radius", "number", "required", [Positive radius in coordinate units.]),
    (
      "..options",
      "arguments",
      "none",
      [Named options forwarded to the underlying constructor or byte renderer.],
    ),
  ),
)[Describe a uniformly charged disk. This is charged-annulus with zero inner
  radius; additional options are forwarded to that constructor.]

#api(
  "charged-annulus",
  "charged-annulus(\n  inner-radius,\n  outer-radius,\n  density: 1,\n  plane: field-plane(),\n  radial-samples: 32,\n  angular-samples: 64,\n)",
  returns: "dictionary",
  parameters: (
    (
      "inner-radius",
      "number",
      "required",
      [Nonnegative inner radius, smaller than the outer radius.],
    ),
    ("outer-radius", "number", "required", [Positive outer radius.]),
    ("density", "number", "1", [Signed charge per unit length or unit area.]),
    (
      "plane",
      "dictionary",
      "field-plane()",
      [Observation or source frame from field-plane().],
    ),
    (
      "radial-samples",
      "integer",
      "32",
      [Positive midpoint count in the radial integration coordinate.],
    ),
    (
      "angular-samples",
      "integer",
      "64",
      [Angular midpoint count, at least four.],
    ),
  ),
)[Describe a uniformly charged annulus. Density is charge per unit area. Radial
  and angular midpoint samples control integration accuracy independently of
  image resolution.]

#api(
  "charged-plane-with-hole",
  "charged-plane-with-hole(\n  hole-radius,\n  density: 1,\n  plane: field-plane(),\n  radial-samples: 32,\n  angular-samples: 64,\n)",
  returns: "dictionary",
  parameters: (
    (
      "hole-radius",
      "number",
      "required",
      [Positive radius of the circular uncharged hole.],
    ),
    ("density", "number", "1", [Signed charge per unit length or unit area.]),
    (
      "plane",
      "dictionary",
      "field-plane()",
      [Observation or source frame from field-plane().],
    ),
    (
      "radial-samples",
      "integer",
      "32",
      [Positive midpoint count in the radial integration coordinate.],
    ),
    (
      "angular-samples",
      "integer",
      "64",
      [Angular midpoint count, at least four.],
    ),
  ),
)[Describe an infinite uniformly charged plane outside a circular hole. Compact
  radial quadrature covers the full infinite domain without a finite outer
  radius.]

== Custom charge sources

#api(
  "charged-curve",
  "charged-curve(\n  position, range: (0, 1), density: 1,\n  samples: 64, constants: (:),\n)",
  parameters: (
    (
      "position",
      "array",
      "required",
      [Three numbers or expressions in `t`, defining world-space coordinates.],
    ),
    (
      "range",
      "array",
      "(0, 1)",
      [Finite, strictly increasing parameter interval.],
    ),
    (
      "density",
      "number / str",
      "1",
      [Signed charge per physical arc length, evaluated in `t`.],
    ),
    (
      "samples",
      "integer",
      "64",
      [Positive midpoint count, also controlling the geometric polyline.],
    ),
    (
      "constants",
      "dictionary",
      "(:)",
      [Finite named coefficients substituted in all coordinate and density
        expressions.],
    ),
  ),
)[
  Describe a nonuniform charged curve. Rust parses expressions, evaluates
  geometry and density, and computes the arc-length Jacobian. Mix this source
  with any built-in constructor in the same heatmap or field-line request.
]

#api(
  "charged-surface",
  "charged-surface(\n  position, bounds: ((0, 1), (0, 1)),\n  density: 1, samples: (24, 24), constants: (:),\n)",
  parameters: (
    (
      "position",
      "array",
      "required",
      [Three numbers or expressions in `u, v`.],
    ),
    (
      "bounds",
      "array",
      "((0, 1), (0, 1))",
      [Two finite, strictly increasing parameter intervals.],
    ),
    (
      "density",
      "number / str",
      "1",
      [Signed charge per physical surface area. Do not include the area
        Jacobian.],
    ),
    (
      "samples",
      "array",
      "(24, 24)",
      [Positive midpoint counts along the two parameter axes.],
    ),
    (
      "constants",
      "dictionary",
      "(:)",
      [Finite named coefficients used in expressions.],
    ),
  ),
)[
  Describe a charged parameterized surface. Rust computes the magnitude of the
  cross product of its coordinate derivatives as the physical area weight.
  Multiple patches can describe a larger or disconnected surface.
]

#api(
  "charged-volume",
  "charged-volume(\n  position, bounds: ((0, 1), (0, 1), (0, 1)),\n  density: 1, samples: (8, 8, 8), constants: (:),\n)",
  parameters: (
    (
      "position",
      "array",
      "required",
      [Three numbers or expressions in `u, v, w`.],
    ),
    (
      "bounds",
      "array",
      "unit cube",
      [Three finite, strictly increasing parameter intervals.],
    ),
    (
      "density",
      "number / str",
      "1",
      [Signed charge per physical volume. Do not include the volume Jacobian.],
    ),
    (
      "samples",
      "array",
      "(8, 8, 8)",
      [Positive midpoint counts along the three parameter axes.],
    ),
    (
      "constants",
      "dictionary",
      "(:)",
      [Finite named coefficients used in expressions.],
    ),
  ),
)[
  Describe a volume charge. The absolute determinant of the coordinate Jacobian
  gives its physical volume weight. Source masks fill the volume cross-section;
  charged cells capture field lines unless source capture is disabled.
]

#api(
  "charged-triangle-mesh",
  "charged-triangle-mesh(\n  vertices, faces, density: 1, samples: 4,\n)",
  parameters: (
    (
      "vertices",
      "array",
      "required",
      [Finite three-dimensional world-space vertex coordinates.],
    ),
    (
      "faces",
      "array",
      "required",
      [Triples of zero-based vertex indices; every face must have positive
        area.],
    ),
    (
      "density",
      "number / array",
      "1",
      [Uniform signed surface density, or one finite density per face.],
    ),
    (
      "samples",
      "integer",
      "4",
      [Subdivisions per triangle edge; each face contributes samples squared
        integration nodes.],
    ),
  ),
)[
  Describe an indexed surface mesh with centroid quadrature. Open and
  disconnected surfaces are accepted; vertex winding does not determine charge
  sign. A closed mesh carries surface charge, not volume charge. Masks use the
  input triangles directly, independently of the integration subdivision count.
]

== Colors and scales

#api(
  "field-colors",
  "field-colors(\n  range: (0, 10),\n  scale: logarithmic-scale(),\n  stops: (\"#163b78\", \"#3fa7a0\", \"#f0e65b\", \"#f6a13a\", \"#d94732\"),\n  space: \"oklab\",\n)",
  returns: "dictionary",
  parameters: (
    ("range", "array", "(0, 10)", [Explicit lower and upper scalar endpoints.]),
    (
      "scale",
      "dictionary",
      "logarithmic-scale()",
      [Linear, logarithmic, or inverse-hyperbolic-sine scale.],
    ),
    (
      "stops",
      "array",
      "default palette",
      [Two or more colors, evenly spaced in transformed value space.],
    ),
    ("space", "string", "\"oklab\"", ["oklab" or "srgb" interpolation.]),
  ),
)[Configure an explicit scalar range and palette shared by heatmaps and
  colorbars. Values outside the range are clipped. At least two color stops are
  required; colors may include alpha.]

#api(
  "linear-scale",
  "linear-scale()",
  returns: "dictionary",
  parameters: (),
)[Map scalar values linearly to palette positions.]

#api(
  "logarithmic-scale",
  "logarithmic-scale(reference: 1)",
  returns: "dictionary",
  parameters: (
    ("reference", "number", "1", [Positive scale reference in field units.]),
  ),
)[Use sign(v) × ln(1 + abs(v) / reference). The transform supports zero and
  signed components; reference must be positive.]

#api(
  "asinh-scale",
  "asinh-scale(reference: 1)",
  returns: "dictionary",
  parameters: (
    ("reference", "number", "1", [Positive scale reference in field units.]),
  ),
)[Use asinh(v / reference), which is nearly linear near zero and compresses
  large magnitudes. Reference must be positive.]

#api(
  "field-colorbar",
  "field-colorbar(width: 50%, ..options)",
  returns: "content",
  parameters: (
    (
      "width",
      "relative length",
      "50%",
      [Typst image width; does not affect computation.],
    ),
    (
      "..options",
      "arguments",
      "none",
      [Named options forwarded to the underlying constructor or byte renderer.],
    ),
  ),
)[Display an independent colorbar SVG gradient as image content. Add tick
  labels, units, and captions in Typst. Additional options are forwarded to
  field-colorbar-bytes.]

#api(
  "field-colorbar-bytes",
  "field-colorbar-bytes(\n  color: field-colors(),\n  resolution: (256, 16),\n  orientation: \"horizontal\",\n)",
  returns: "bytes (SVG)",
  parameters: (
    (
      "color",
      "dictionary",
      "field-colors()",
      [Palette configuration from field-colors().],
    ),
    (
      "resolution",
      "array",
      "(256, 16)",
      [Positive integer pixel counts (width, height).],
    ),
    ("orientation", "string", "\"horizontal\"", ["horizontal" or "vertical".]),
  ),
)[Return an independent colorbar as SVG gradient bytes. Values increase from
  left to right, or from bottom to top for a vertical bar.]

== Source appearance

#api(
  "source-style",
  "source-style(color: \"#ede9fe\", thickness: 0.1)",
  returns: "dictionary",
  parameters: (
    (
      "color",
      "color / string",
      "\"#ede9fe\"",
      [Typst color or RGB/RGBA hex string.],
    ),
    (
      "thickness",
      "number",
      "0.1",
      [Positive full mask thickness in world-space units.],
    ),
  ),
)[Describe the color and full world-space thickness of a source mask. This
  changes object appearance without changing charge geometry or field
  regularization.]

#api(
  "source-overlay",
  "source-overlay(color: \"#ede9fe\", thickness: 0.1, overrides: ())",
  returns: "dictionary",
  parameters: (
    (
      "color",
      "color / string",
      "\"#ede9fe\"",
      [Typst color or RGB/RGBA hex string.],
    ),
    (
      "thickness",
      "number",
      "0.1",
      [Positive full mask thickness in world-space units.],
    ),
    (
      "overrides",
      "array",
      "()",
      [Unique zero-based (source: index, style: source-style()) records. A none
        style hides that source.],
    ),
  ),
)[Enable source masks using a default style and optional per-source overrides.
  Masks are geometric cross-sections in the observation plane; later masks take
  precedence. They do not modify the field.]

== Heatmap rendering

#api(
  "electric-field-heatmap",
  "electric-field-heatmap(sources, width: 100%, scene: none, ..options)",
  returns: "content",
  parameters: (
    (
      "scene",
      "dict / none",
      "none",
      [Optional spatial companion from field-scene(), sharing sources, field,
        and observation grid.],
    ),
    (
      "sources",
      "array",
      "required",
      [Source dictionaries; their vector fields are added before scalar
        extraction.],
    ),
    (
      "width",
      "relative length",
      "100%",
      [Typst image width; does not affect computation.],
    ),
    (
      "..options",
      "arguments",
      "none",
      [Named options forwarded to the underlying constructor or byte renderer.],
    ),
  ),
)[Display a Rust-rendered SVG with an embedded field raster and vector source
  masks. The scene option defaults to none; pass field-scene() to add a spatial
  companion on the right. Other options are forwarded to
  electric-field-heatmap-bytes.]

#api(
  "electric-field-heatmap-bytes",
  "electric-field-heatmap-bytes(\n  sources,\n  grid: field-grid(),\n  field: field-parameters(),\n  quantity: field-magnitude(),\n  color: field-colors(),\n  singularity-color: \"#00000000\",\n  source-overlay: none,\n)",
  returns: "bytes (SVG)",
  parameters: (
    (
      "sources",
      "array",
      "required",
      [Source dictionaries; their vector fields are added before scalar
        extraction.],
    ),
    (
      "grid",
      "dictionary",
      "field-grid()",
      [Sampling frame, bounds, resolution, and pixel placement.],
    ),
    (
      "field",
      "dictionary",
      "field-parameters()",
      [Physical multiplier and regularization parameters.],
    ),
    (
      "quantity",
      "dictionary",
      "field-magnitude()",
      [Magnitude or signed directional component.],
    ),
    (
      "color",
      "dictionary",
      "field-colors()",
      [Palette configuration from field-colors().],
    ),
    (
      "singularity-color",
      "color / string",
      "\"#00000000\"",
      [Fallback color for non-finite singular samples.],
    ),
    (
      "source-overlay",
      "dict / none",
      "none",
      [Optional object masks; independent of the field palette.],
    ),
  ),
)[Sum source vector fields, extract a scalar, map colors, and encode a
  self-contained SVG in Rust. All sources share the same physical parameters.
  Singular samples use singularity-color.]

== Seed placement

#api("seed-points", "seed-points(points)", returns: "dictionary", parameters: (
  ("points", "array", "required", [Explicit (u, v) seed coordinate pairs.]),
))[Describe explicit seed coordinates in the local observation plane. Pass an
  array of seed descriptions to the field-line renderer.]

#api(
  "seed-circle",
  "seed-circle(center, radius: 0.14, count: 24, phase: 0)",
  returns: "dictionary",
  parameters: (
    ("center", "array", "required", [Local (u, v) circle center.]),
    ("radius", "number", "0.14", [Positive radius in coordinate units.]),
    ("count", "integer", "24", [Number of seeds to generate.]),
    ("phase", "number", "0", [Starting circle angle in radians.]),
  ),
)[Describe equally spaced seeds on a circle in the local observation plane.
  Phase is measured in radians.]

#api(
  "seed-segment",
  "seed-segment(start, end, count: 24)",
  returns: "dictionary",
  parameters: (
    (
      "start",
      "array",
      "required",
      [First endpoint; world-space 3D for sources, local 2D for seeds.],
    ),
    (
      "end",
      "array",
      "required",
      [Second endpoint; same coordinate system as start.],
    ),
    ("count", "integer", "24", [Number of seeds to generate.]),
  ),
)[Describe evenly spaced seeds along a local segment, including both endpoints.
  Count must be at least two.]

== Field-line configuration

#api(
  "field-line-tracing",
  "field-line-tracing(\n  step: 0.02,\n  max-steps: 2000,\n  min-field: 0.00000001,\n  source-radius: 0.08,\n  direction: \"both\",\n  mode: \"planar\",\n  plane-tolerance: 0.000001,\n)",
  returns: "dictionary",
  parameters: (
    (
      "step",
      "number",
      "0.02",
      [Positive world-space arc-length step; independent of output resolution.],
    ),
    (
      "max-steps",
      "integer",
      "2000",
      [Maximum steps per seed and tracing branch.],
    ),
    (
      "min-field",
      "number",
      "0.00000001",
      [Nonnegative field magnitude threshold for termination.],
    ),
    (
      "source-radius",
      "number",
      "0.08",
      [Nonnegative source capture distance. If nonzero, at least step.],
    ),
    (
      "direction",
      "string",
      "\"both\"",
      ["both", "forward", or "backward" tracing branches.],
    ),
    (
      "mode",
      "string",
      "\"planar\"",
      ["planar" validates the plane; "projected" follows the in-plane vector
        projection.],
    ),
    (
      "plane-tolerance",
      "number",
      "0.000001",
      [Allowed ratio of normal component to full field magnitude in planar
        mode.],
    ),
  ),
)[Configure fixed-step RK4 integration of the normalized electric field. Tracing
  stops at bounds, sources, weak fields, iteration limits, or numerical
  failures. Backward branches are reversed for arrows to follow the physical
  field.]

#api(
  "field-line-style",
  "field-line-style(\n  color: \"#1e293b\",\n  thickness: 1.1,\n  arrow-spacing: 36,\n  arrow-size: 5,\n)",
  returns: "dictionary",
  parameters: (
    (
      "color",
      "color / string",
      "\"#1e293b\"",
      [Typst color or RGB/RGBA hex string.],
    ),
    (
      "thickness",
      "number",
      "1.1",
      [Positive SVG stroke width in output pixels.],
    ),
    (
      "arrow-spacing",
      "number / none",
      "36",
      [Arrow interval in output pixels, at least max(1, 2 × arrow-size).],
    ),
    ("arrow-size", "number", "5", [Nonnegative arrow size in output pixels.]),
  ),
)[Configure SVG strokes and directional arrows in output pixels. Setting
  arrow-spacing to none or arrow-size to zero disables arrows. The stroke color
  may include alpha.]

#api(
  "field-line-background",
  "field-line-background(color: white)",
  returns: "dictionary",
  parameters: (
    ("color", "color / string", "white", [Typst color or RGB/RGBA hex string.]),
  ),
)[Use a solid or transparent background for SVG field lines.]

#api(
  "field-line-heatmap",
  "field-line-heatmap(color: field-colors())",
  returns: "dictionary",
  parameters: (
    (
      "color",
      "dictionary",
      "field-colors()",
      [Palette configuration from field-colors().],
    ),
  ),
)[Place field lines above a magnitude heatmap with the same sources, frame, and
  physical parameters. The raster is embedded in the returned SVG; it is not an
  external image reference.]

#api(
  "field-line-endpoints",
  "field-line-endpoints(color: \"#b45309\", size: 2.5, thickness: 0.6)",
  parameters: (
    (
      "color",
      "color / string",
      "\"#b45309\"",
      [Color of numerical-termination symbols, including optional alpha.],
    ),
    (
      "size",
      "number",
      "2.5",
      [Positive marker radius, at most 32 SVG output pixels.],
    ),
    (
      "thickness",
      "number",
      "0.6",
      [Positive outline width, no greater than marker size.],
    ),
  ),
)[
  Enable markers for stagnation, weak fields, step limits, and singularities
  through the renderer's `endpoints` parameter. Sources and viewport exits are
  unmarked. Close symbols with the same reason are merged visually. A marker
  does not certify an exact field null or a physical charge source.
]

== Field-line rendering

#api(
  "electric-field-lines",
  "electric-field-lines(sources, seeds, width: 100%, scene: none, ..options)",
  returns: "content",
  parameters: (
    (
      "scene",
      "dict / none",
      "none",
      [Optional spatial companion from field-scene(), sharing sources, field,
        and observation grid.],
    ),
    (
      "sources",
      "array",
      "required",
      [Source dictionaries; their vector fields are added before scalar
        extraction.],
    ),
    (
      "seeds",
      "array",
      "required",
      [Seed descriptions from seed-points(), seed-circle(), or seed-segment().],
    ),
    (
      "width",
      "relative length",
      "100%",
      [Typst image width; does not affect computation.],
    ),
    (
      "..options",
      "arguments",
      "none",
      [Named options forwarded to the underlying constructor or byte renderer.],
    ),
  ),
)[Display Rust-traced field lines as SVG image content. The scene option
  defaults to none; pass field-scene() to add a spatial companion on the right.
  Other options are forwarded to electric-field-lines-bytes. No captions are
  imposed.]

#api(
  "electric-field-lines-bytes",
  "electric-field-lines-bytes(\n  sources,\n  seeds,\n  grid: field-grid(resolution: (480, 360)),\n  field: field-parameters(),\n  tracing: field-line-tracing(),\n  style: field-line-style(),\n  background: field-line-background(),\n  source-overlay: none,\n  endpoints: none,\n)",
  returns: "bytes (SVG)",
  parameters: (
    (
      "sources",
      "array",
      "required",
      [Source dictionaries; their vector fields are added before scalar
        extraction.],
    ),
    (
      "seeds",
      "array",
      "required",
      [Seed descriptions from seed-points(), seed-circle(), or seed-segment().],
    ),
    (
      "grid",
      "dictionary",
      "field-grid(resolution: (480, 360))",
      [Sampling frame, bounds, resolution, and pixel placement.],
    ),
    (
      "field",
      "dictionary",
      "field-parameters()",
      [Physical multiplier and regularization parameters.],
    ),
    (
      "tracing",
      "dictionary",
      "field-line-tracing()",
      [RK4 accuracy, termination, direction, and planarity controls.],
    ),
    (
      "style",
      "dictionary",
      "field-line-style()",
      [SVG stroke and arrow configuration.],
    ),
    (
      "background",
      "dictionary",
      "field-line-background()",
      [Solid color or field-magnitude heatmap background.],
    ),
    (
      "source-overlay",
      "dict / none",
      "none",
      [Optional object masks; independent of the field palette.],
    ),
    (
      "endpoints",
      "dict / none",
      "none",
      [Optional numerical-termination markers from field-line-endpoints().],
    ),
  ),
)[Return a self-contained SVG containing vector strokes, arrows, and any
  background or source masks. Seeds use local plane coordinates; sources use
  world coordinates. Planar mode rejects a significant normal field component.]

== Spatial configuration

#api(
  "field-camera",
  "field-camera(target: (0, 0, 0), azimuth: -1.05, elevation: 0.48, span: 5)",
  parameters: (
    (
      "target",
      "3D vector",
      "(0, 0, 0)",
      [Finite world-space position at the viewport center.],
    ),
    (
      "azimuth",
      "number",
      "-1.05",
      [Camera direction around world z, measured from positive x in radians.],
    ),
    (
      "elevation",
      "number",
      "0.48",
      [Radians above xy, strictly between -pi/2 and pi/2.],
    ),
    (
      "span",
      "number",
      "5",
      [Positive visible horizontal world-space length; larger values zoom out.],
    ),
  ),
)[Configure an orthographic camera without altering the field or traced paths.]

#api(
  "field-scene-slice",
  "field-scene-slice(color: none, opacity: 0.2, samples: (32, 24))",
  parameters: (
    (
      "color",
      "dict / none",
      "none",
      [Optional field-colors() for the complete field magnitude; none gives pale
        blue.],
    ),
    ("opacity", "number", "0.2", [Alpha multiplier between 0 and 1.]),
    (
      "samples",
      "2D integer vector",
      "(32, 24)",
      [Positive tile counts, at most 65536 tiles in total.],
    ),
  ),
)[Display the shared observation rectangle in space. Undefined field samples are
  transparent. Sampling is independent of source quadrature and planar raster
  resolution.]

#api(
  "spatial-field-line-tracing",
  "spatial-field-line-tracing(step: 0.025, max-steps: 1000, min-field: 0.00000001, source-radius: 0.04, direction: \"both\")",
  parameters: (
    (
      "step",
      "number",
      "0.025",
      [Positive fixed world-space RK4 arc-length step.],
    ),
    (
      "max-steps",
      "integer",
      "1000",
      [Maximum steps per branch, between 1 and 10000.],
    ),
    (
      "min-field",
      "number",
      "0.00000001",
      [Nonnegative threshold on the full field magnitude.],
    ),
    (
      "source-radius",
      "number",
      "0.04",
      [Nonnegative geometry capture distance; zero disables capture. Otherwise
        step must not exceed it.],
    ),
    (
      "direction",
      "string",
      "\"both\"",
      ["forward", "backward", or "both"; arrows follow the electric field.],
    ),
  ),
)[Integrate the full three-dimensional vector field, without planar projection.
  No adaptive integration-error control or exact null localization is provided.]

#api(
  "field-scene-lines",
  "field-scene-lines(seeds, tracing: spatial-field-line-tracing(), style: field-line-style(thickness: 0.7, arrow-size: 3, arrow-spacing: 45))",
  parameters: (
    (
      "seeds",
      "array of 3D vectors",
      "required",
      [Between 1 and 1024 explicit finite world positions inside scene bounds.],
    ),
    (
      "tracing",
      "dictionary",
      "spatial-field-line-tracing()",
      [Spatial integration and termination controls.],
    ),
    (
      "style",
      "dictionary",
      "see signature",
      [Projected pixel dimensions and color from field-line-style().],
    ),
  ),
)[Enable spatial field lines. Planar seed constructors are not accepted here.
  Seeds control displayed curves rather than calibrated electric flux.]

#api(
  "field-scene",
  "field-scene(\n  resolution: (640, 480),\n  bounds: ((-2, -1.5, -1.5), (2, 1.5, 1.5)),\n  camera: field-camera(),\n  source-colors: (\"#8b5cf699\", \"#14b8a699\"),\n  source-thickness: 0.6,\n  point-size: 3,\n  slice: field-scene-slice(),\n  lines: none,\n  axes: true,\n)",
  parameters: (
    (
      "resolution",
      "2D integer vector",
      "(640, 480)",
      [SVG viewport dimensions; does not change field integration.],
    ),
    (
      "bounds",
      "two 3D vectors",
      "see signature",
      [Finite world minimum and maximum corners; clips geometry and stops
        spatial traces.],
    ),
    (
      "camera",
      "dictionary",
      "field-camera()",
      [Independent orthographic projection.],
    ),
    (
      "source-colors",
      "color array",
      "see signature",
      [Source-order palette, cycling as needed. Alpha controls transparency; at
        least one color is required.],
    ),
    (
      "source-thickness",
      "number",
      "0.6",
      [Positive curve and boundary width, at most 32 output pixels.],
    ),
    (
      "point-size",
      "number",
      "3",
      [Positive point-charge radius, at most 32 output pixels.],
    ),
    (
      "slice",
      "dict / none",
      "field-scene-slice()",
      [Observation plane or magnitude slice; none hides it.],
    ),
    (
      "lines",
      "dict / none",
      "none",
      [Independent world-space seeds from field-scene-lines(); none draws no
        spatial lines.],
    ),
    (
      "axes",
      "boolean",
      "true",
      [World-axis orientation key and observation-plane normal.],
    ),
  ),
)[Configure a spatial companion or standalone scene. Geometry and field samples
  use Rust; small SVG primitives use approximate back-to-front ordering.]

== Spatial rendering

#api(
  "electric-field-scene-bytes",
  "electric-field-scene-bytes(sources, grid: field-grid(), field: field-parameters(), scene: field-scene())",
  returns: "bytes (SVG)",
  parameters: (
    (
      "sources",
      "array",
      "required",
      [The same source dictionaries accepted by the planar renderers.],
    ),
    (
      "grid",
      "dictionary",
      "field-grid()",
      [Observation plane and local bounds. Planar resolution and sampling do not
        control the spatial slice.],
    ),
    (
      "field",
      "dictionary",
      "field-parameters()",
      [Shared physical multiplier and regularization.],
    ),
    (
      "scene",
      "dictionary",
      "field-scene()",
      [Geometry styles, camera, slice, spatial bounds, and optional spatial
        lines.],
    ),
  ),
)[Return one standalone orthographic vector SVG without filesystem access. This
  is a slice and geometry renderer, not volume ray marching.]

#api(
  "electric-field-scene",
  "electric-field-scene(sources, width: 100%, ..options)",
  returns: "content",
  parameters: (
    (
      "sources",
      "array",
      "required",
      [Built-in and custom source dictionaries.],
    ),
    (
      "width",
      "relative length",
      "100%",
      [Typst image width; does not affect computation.],
    ),
    (
      "..options",
      "arguments",
      "none",
      [Forwarded to electric-field-scene-bytes.],
    ),
  ),
)[Display a standalone spatial scene. Typst supplies labels, legends, and
  layout.]
