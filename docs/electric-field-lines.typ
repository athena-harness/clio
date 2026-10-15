// Native Typst guide chapter, included by manual.typ.

= Electric-field lines

Electric-field lines are traced and rendered entirely in Rust. The WASM plugin
returns self-contained SVG bytes with vector strokes and arrowheads. Optional
heatmaps are embedded PNGs; source masks are vector geometry. No external files
are referenced by the SVG.

```typ
#import "lib.typ": *

#let charges = (
  point-charge((-0.7, 0, 0)),
  point-charge((0.7, 0, 0), charge: -1),
)
#electric-field-lines(
  charges,
  (seed-circle((-0.7, 0), radius: 0.14, count: 24),),
  grid: field-grid(resolution: (480, 360)),
  tracing: field-line-tracing(step: 0.02, source-radius: 0.02),
  source-overlay: source-overlay(color: "#8b5cf6", thickness: 0.04),
)
```

Build the plugin with `bash scripts/build-plugin.sh`. Compile the complete
gallery with
`typst compile --root . examples/gallery.typ /tmp/clio-gallery.pdf`, or compile
an individual example from `examples/electric-field-lines/`.

== Matching the heatmap gallery

Sixteen baseline field-line scenes match the baseline heatmap scenes by
filename. Gallery pages 5--8 repeat the order of heatmap pages 1--4. Shared
definitions in `examples/electric-field/models.typ` keep source positions,
charges, densities, quadrature counts, bounds, and observation planes identical.
The SVG viewport is three times the heatmap resolution; changing this does not
change the model.

Pages 9--10 add four custom models with matching heatmaps and field lines. These
use the same raster resolution in both views; their shared sources and seeds
live in `examples/electric-field/custom-models.typ`.

#table(
  columns: (1.2fr, 2.8fr),
  table.header([Scene], [Seed placement]),
  [Single charge], [Circle around the charge],
  [Like charges], [One circle per positive charge],
  [Dipole], [Circle around the positive charge; magnitude heatmap underneath],
  [Unequal charges], [Circle around the stronger positive charge],
  [Square quadrupole], [Circles around both positive corners],
  [Axial quadrupole], [Circles around both positive outer charges],
  [Finite line], [Segments above and below the rod],
  [Long wire], [Segments above and below the visible central region],
  [Opposite line charges], [Mid-gap segment extending beyond the rod ends],
  [Square loop], [Interior circle and four exterior segments],
  [Uniform disk], [Segments on both sides of its axial cross section],
  [Charged ring],
  [Circles around both narrow-band cross sections and inside the opening],

  [Uniform annulus], [Both sides of both charged bands, plus interior seeds],
  [Plane with a hole], [Both sides of the charged regions, plus interior seeds],
  [Parallel disks], [Mid-gap segment spanning the central and fringing regions],
  [Coplanar disks],
  [Circle above the positive patch, in explicit projected mode],
)

The coplanar-disk scene preserves the heatmap's observation height of 0.35. Its
curves are in-plane projected streamlines, while the corresponding heatmap shows
the signed normal component E\_z. These are complementary views of the same
vector field, not curves tangent to an E\_z scalar plot. This distinction is
labeled in the scene. All other line scenes use true planar tracing.

== Seeds, integration, and resolution

Seed coordinates use the observation plane's local coordinates, not raster
pixels. Generators can be mixed in the same array:

#table(
  columns: (1.2fr, 2.8fr),
  table.header([Generator], [Parameters]),
  [`seed-points(points)`], [Explicit two-dimensional coordinates],
  [`seed-circle(center, radius: 0.14, count: 24, phase: 0)`],
  [Uniform circle; phase in radians],

  [`seed-segment(start, end, count: 24)`],
  [Uniform segment including both endpoints],
)

All seeds must be finite and inside the observation bounds. A seed inside the
source termination radius produces no extended line. Seed placement determines
which curves are shown: the resulting density is not automatically proportional
to electric flux or charge magnitude. Seeding both sides of the same trajectory
may display duplicate curves.

`field-line-tracing` exposes independent numerical controls:

#table(
  columns: (1.4fr, 1fr, 2.6fr),
  table.header([Parameter], [Default], [Meaning]),
  [`step`], [`0.02`], [Fixed RK4 arc-length step in geometry units],
  [`max-steps`], [`2000`], [Maximum steps for each branch],
  [`min-field`], [`0.00000001`], [Stop at weak or zero in-plane fields],
  [`source-radius`],
  [`0.08`],
  [Stop near source geometry; zero disables the check],

  [`direction`], [`"both"`], [`"forward"`, `"backward"`, or joined branches],
  [`mode`],
  [`"planar"`],
  [True planar field lines or `"projected"` streamlines],

  [`plane-tolerance`],
  [`0.000001`],
  [Allowed relative normal component in planar mode],
)

RK4 integrates the normalized direction, so `step` controls geometry rather than
the physical speed of a test particle. Reduce it to improve trajectory accuracy;
compare successive step sizes when resolving sharp curvature. A nonzero source
radius must be at least the integration step. Curves stop at bounds, source
geometry, null fields, singular samples, negligible progress, or the step limit.
The last out-of-bounds segment is clipped to the rectangle.

`direction` affects integration only. Rendered paths and arrowheads always
follow the electric field, including a branch traced backward from its seed.

Raster resolution controls the SVG viewport and embedded raster layers, not the
integration step or continuous-source quadrature. `field-grid.sampling` applies
to raster layers; the curve integrator uses continuous local coordinates.
Surface and line-source integration counts retain their existing meaning.

== Observation planes

The default planar mode requires a field tangent to the configured observation
plane at the RK4 evaluation points. Symmetry planes of planar point-charge
configurations and axis-containing planes of circular sources are typical
choices. An incompatible plane produces an error describing the required change.

Explicit `mode: "projected"` traces the in-plane component. These are projected
streamlines, not actual three-dimensional electric-field lines. A vanishing
in-plane component terminates the trace even if the normal component is nonzero.

== Stroke, arrows, and backgrounds

```typ
style: field-line-style(
  color: "#1e293b", thickness: 1.1, arrow-spacing: 36, arrow-size: 5,
)
```

Stroke thickness, arrow size, and arrow spacing are in SVG output pixels.
`arrow-spacing: none` or `arrow-size: 0` disables arrows. Color accepts Typst
colors or hexadecimal RGBA strings. Arrow spacing must be at least twice the
arrow size and at least one pixel.

`field-line-background(color: white)` provides a solid background, including
transparent colors. `field-line-heatmap(color: field-colors(...))` computes a
field-magnitude heatmap underneath the curves. Use a contrasting line color, and
reuse the same color configuration for a separate colorbar.

Existing `source-overlay` settings draw source masks above the curves. Mask
thickness and source termination radius are separate controls: choose a radius
near half the mask thickness if curves should meet the visible source boundary.

`electric-field-lines-bytes` returns raw SVG; `electric-field-lines` returns
plain Typst image content. The wrapper imposes no captions, legends, or page
layout.

== Interpreting trace endpoints

An interior line endpoint is not automatically a charge source. Seeds are traced
in both directions by default; a branch can stop at a source, a boundary, a weak
field, a singularity, numerical stagnation, or its step limit. The folded-mesh
example marks non-source terminations explicitly:

```typ
#electric-field-lines(
  sources, seeds,
  endpoints: field-line-endpoints(color: "#b45309", size: 2, thickness: 0.6),
)
```

#table(
  columns: (1fr, 2.5fr),
  table.header([Marker], [Meaning]),
  [Open diamond],
  [Numerical stagnation: the RK4 step made negligible progress.],

  [Open circle],
  [An RK4 evaluation encountered the configured in-plane field threshold.],

  [Open square], [The branch reached its maximum number of integration steps.],
  [Cross], [An RK4 evaluation encountered an unregularized singularity.],
)

Normal source captures, viewport exits, and untraced seed endpoints are
unmarked. Nearby markers of the same reason are merged for display; underlying
trace reasons are retained per line. These markers describe the numerical
computation and do not certify an exactly located field null. In particular, a
stalled endpoint can still have a nonzero field. No additional null-finding or
integration-error control is performed by enabling markers.

Purple marks the source intersection with the observation plane in the
folded-mesh example. Its amber diamond marks stagnation near field cancellation.
The two marks have different meanings: the full folded surface extends outside
the displayed plane. Seed count and placement control which curves appear, not
their flux weights.

Native Rust callers can use `trace_detailed` to obtain field-oriented paths with
independent `start` and `end` termination reasons. SVG paths also include
`data-start-termination` and `data-end-termination` attributes. Markers are
optional and default to `endpoints: none`; their dimensions are output pixels.

== Limits

At most 1024 seeds and 10000 steps per branch are accepted. The maximum possible
vertex count, including both branches, is 4194304. Tracing has a runtime budget
of one billion source evaluations and geometric termination checks. Raster
backgrounds retain their pixel limits; vector masks have a separate geometry
budget.
