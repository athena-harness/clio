// Native Typst guide chapter, included by manual.typ.

= Electric-field heatmaps

Build the package-local WASM artifact before importing `lib.typ`:

```sh
bash scripts/build-plugin.sh
typst compile --root . examples/gallery.typ /tmp/clio-gallery.pdf
```

All Coulomb evaluation, continuous integration, scalar extraction, color
mapping, PNG encoding, and SVG composition run in Rust. Typst creates source
descriptions and composes the returned image with formulas, labels, captions,
and page layout.

== Example gallery

`examples/gallery.typ` includes twenty-two object examples from
`examples/electric/`. Each object file contains its heatmap, matching field
lines, and a spatial view. Each example can also be compiled on its own:

```sh
typst compile --root . examples/electric/dipole.typ /tmp/clio-dipole.pdf
```

Each gallery page groups the views of one object. `examples/electric/models.typ`
owns the baseline source geometry, densities, quadrature counts, and observation
frames. Custom models and both spherical shells use the same paired
presentation. Feature demonstrations live in `examples/features/`. See the
Custom charge geometry chapter for parameter expressions and triangle meshes.

Object modules export `heatmap()`, `field-lines()`, and `spatial()` functions.
Import these functions to compose a selected view in another document. The
complete page is deferred until layout, so importing an object does not render
its unused page. Pass `--input show-3d=false` to omit spatial views from
standalone examples and the gallery.

Every spatial example includes a field-magnitude heatmap slice and a labeled
colorbar. Magnitude views use the same color range as their planar counterpart.
The parallel-disk and coplanar-disk planar heatmaps display signed components;
their spatial slices instead display the full magnitude, as noted in each panel.

The gallery covers an isolated charge, equal and unequal charge pairs, a dipole,
square and axial quadrupoles, a finite rod, a long-wire approximation, opposite
parallel line charges, a square wire loop, a disk, a narrow-band ring
approximation, an annulus, an infinite plane with a hole, parallel charged
disks, and opposite coplanar charged disks.

Raster and integration sampling can be changed independently for the entire
gallery:

```sh
typst compile --root . --input samples-x=240 --input samples-y=180 \
  --input integration-detail=2 examples/gallery.typ /tmp/clio-gallery-detailed.pdf
```

Defaults are 160 by 120 pixels and integration detail 1. The detail multiplier
scales the source sample counts in `examples/electric/common.typ`; each source's
base count is shared in `examples/electric/models.typ`. Increasing both radial
and angular counts by a factor of two quadruples surface quadrature work. Bounds
and pixel aspect ratios in these examples preserve equal lengths along both
axes.

The gallery uses relative units and a regularization length of 0.06. It shows
prescribed charges rather than self-consistent charge redistribution on
conductors. The long-wire example is finite, and the ring example uses a narrow
annulus with total charge normalized to one. Their approximation assumptions are
stated in the panels. Positive and negative field components use a diverging
palette.

Example masks use a shared thickness of 0.04 world units. SVG geometry keeps
these thin lines and small point markers smooth at any display size.

== Independent configuration

```typ
#import "lib.typ": *

#let palette = field-colors(range: (0, 10), scale: logarithmic-scale(reference: 1))
#electric-field-heatmap(
  (point-charge((-0.7, 0, 0)), point-charge((0.7, 0, 0), charge: -1)),
  grid: field-grid(resolution: (241, 181), bounds: (-2, 2, -1.5, 1.5)),
  field: field-parameters(coulomb-constant: 1, softening: 0.02),
  color: palette,
  width: 12cm,
)
#field-colorbar(color: palette)
```

#table(
  columns: (1.2fr, 2.8fr),
  table.header([Configuration], [Responsibility]),
  [Source constructors],
  [Charge geometry, signed charge/density, integration accuracy],

  [`field-grid`],
  [Image resolution, observation bounds, plane, sample placement],

  [`field-parameters`], [Coulomb constant and regularization length],
  [`field-magnitude` / `field-component`],
  [Scalar extracted from the vector field],

  [`field-colors`],
  [Value range, nonlinear scale, palette, interpolation space],

  [`width`], [Typst display size only],
)

== Sources and integration samples

Sources can be mixed in the same array. Rust adds their *vector* fields before
computing the magnitude or projection.

#table(
  columns: (1.4fr, 1fr, 2.6fr),
  table.header(
    [Constructor], [Required arguments], [Named parameters and defaults]
  ),
  [`point-charge`], [`position`], [`charge: 1`],
  [`charged-segment`], [`start, end`], [`density: 1, samples: 64`],
  [`charged-disk`],
  [`radius`],
  [`density: 1, plane: field-plane(), radial-samples: 32, angular-samples: 64`],

  [`charged-annulus`], [`inner-radius, outer-radius`], [Same as disk],
  [`charged-plane-with-hole`], [`hole-radius`], [Same as disk],
)

Positions and endpoints are three-element Cartesian arrays. Densities are signed
charge per unit length for a segment and per unit area for a surface. A source
plane's origin is the disk/annulus/hole center; its horizontal and vertical axes
must be perpendicular unit vectors. The default source plane is `xy`.

For a surface in `yz`, use:

```typ
#let yz = field-plane(horizontal: (0, 1, 0), vertical: (0, 0, 1))
#let source = charged-disk(0.7, plane: yz, radial-samples: 40, angular-samples: 80)
```

Continuous sources use midpoint quadrature. Segment nodes carry
`density * length / samples`; annulus nodes carry
`density * radius * radial-step * angular-step`. Nodes and angles are prepared
once per image, then reused for every observation point.

Increase `resolution` to increase heatmap sampling density. Independently
increase `samples`, or `radial-samples` and `angular-samples`, to refine
continuous-source integration. Uniform quadrature is approximate and needs
convergence checks, especially close to a charged surface or with very small
regularization.

The infinite plane with a hole uses `r = hole-radius/(1-t)` to map `t` in
`[0,1)` onto the charged radial interval `[hole-radius, infinity)`. Midpoint
quadrature includes the Jacobian `r*dr/dt`. It needs no finite outer integration
radius or tail correction, and places no virtual sources inside the hole.
`radial-samples` controls samples in this compact coordinate. Increase radial
and angular samples when observations are far from the hole or close to the
charged surface.

== Observation grid and field quantity

`field-grid` defaults to:

```typ
field-grid(
  resolution: (141, 109),
  bounds: (-2, 2, -1.5, 1.5),
  plane: field-plane(),
  sampling: "centers",
)
```

Bounds are `(xmin, xmax, ymin, ymax)` in the observation plane's local
coordinates. Rows run downward from `ymax`. `"centers"` samples pixel centers;
`"endpoints"` includes both bounds and needs at least two pixels per axis. Frame
axes must be unit vectors and perpendicular, so local coordinates retain
physical distances. The raster aspect ratio follows `resolution`; match it to
the coordinate spans when equal distances should have equal displayed lengths.

`field-magnitude()` includes all three Cartesian components, including the
component normal to the observation plane. `field-component((0, 0, 1))` displays
the signed world-space z component; any finite unit direction is accepted.

== Units and singularities

The default Coulomb multiplier is 1 for relative fields. To use physical units,
provide a Coulomb constant consistent with the charge and length units. Color
range and nonlinear reference values must then use the resulting field unit.

The softened point-charge kernel is

$
  bold(E)(bold(r)) = k q (bold(r) - bold(r)_0) / (norm(bold(r) - bold(r)_0)^2 + epsilon^2)^(3/2).
$

Here $bold(r)_0$ is the charge position and $epsilon$ is `softening`. Softening
is a *length*, defaults to 0.02, and changes the field near sources. It is
separate from integration accuracy and color clipping. Set it to zero for the
exact point-charge kernel away from singularities. Singular samples use
`singularity-color`, defaulting to transparent. At zero softening the charged
part of the infinite plane is undefined; the hole interior remains evaluable.
Finite continuous distributions are represented by quadrature nodes, so exact
coincidence with a nonzero node is also undefined at zero softening. Other
on-surface values may depend strongly on quadrature and are not one-sided
limits.

== Source overlays

Source masks are optional in the library and enabled in the gallery. They mark
the geometric intersection of a source with the observation slice, thickened by
half the configured thickness on each side. Point sources appear as small filled
disks, segments as bands, and surfaces as filled cross sections. Circular
openings remain unfilled except for the configured thickness at their edges. A
source outside the slice is not projected into it; the coplanar-disk example at
observation height 0.35 consequently has no visible source masks.

```typ
#electric-field-heatmap(
  (point-charge((-0.7, 0, 0)), point-charge((0.7, 0, 0), charge: -1)),
  source-overlay: source-overlay(
    color: "#ede9fe", thickness: 0.04,
    overrides: (
      (source: 1, style: source-style(color: "#bae6fd", thickness: 0.04)),
    ),
  ),
)
```

Use `source-overlay: none` to disable all masks. An override with `style: none`
disables one source's mask. Override indices are zero-based and must be unique.
Color strings or Typst colors are accepted, including alpha for translucent
overlays. Later sources take visual precedence when masks overlap.

Thickness uses the same length unit as source coordinates and has no effect on
field softening, quadrature, source charge, or the heatmap color range. Masks
are drawn as vector geometry above the embedded field raster. Translucent
sources composite in source order; later sources appear above earlier ones.

== Color scales and colorbars

`field-colors` defaults to range `(0, 10)`, a signed logarithmic scale with
reference 1, the five-stop Obsino palette, and Oklab interpolation. Colors may
be Typst colors or hexadecimal strings. Transparent stops are supported.

- `linear-scale()` maps values linearly.
- `logarithmic-scale(reference: 1)` maps `sign(v)*ln(1+abs(v)/reference)`.
- `asinh-scale(reference: 1)` maps `asinh(v/reference)`.

All scales map their transformed range endpoints to the palette endpoints.
Values outside the explicit range are clipped. For signed components, use a
signed range and a diverging palette, such as `stops: (blue, white, red)`.
`space: "srgb"` is available as an alternative to perceptual `"oklab"`.

`field-colorbar` uses the same configuration without re-evaluating any sources.
It defaults to `resolution: (256, 16), orientation: "horizontal", width: 50%`. A
vertical colorbar places the maximum at the top. The colorbar is evenly spaced
in the *transformed* coordinate; nonlinear tick positions must use that
transform, not linear interpolation of the original field values. Labels remain
in Typst.

`electric-field-heatmap-bytes` and `field-colorbar-bytes` return SVG bytes for
custom composition. Their counterparts return plain image content and impose no
figure, legend, caption, alignment, or page rules.

== SVG output and vector geometry

All public byte renderers return self-contained SVG. A heatmap contains an
embedded PNG field layer and optional vector source masks. Field lines and
source markers are SVG paths or circles; colorbars are SVG gradients. No
external image files are referenced. For direct composition, use
`image(data, format: "svg")`.

Increasing `field-grid.resolution` refines field sampling. Source masks are
drawn independently: ordinary points, segments, and circular sections use SVG
primitives; complex slices use adaptive vector contours of the prepared
geometry. Their contour cells have a diagonal at most roughly 1/2048 of the
observation diagonal, with further refinement for thin masks. Increasing source
integration samples improves the geometric approximation of a parameterized
model, independently of raster size.

The public heatmap and colorbar byte functions now return SVG instead of PNG;
callers using their bytes directly must select the SVG image format. The Rust
core retains its low-level PNG routines for scalar layers and native callers.

== Limits and errors

The plugin accepts at most 16 MiB of JSON. A raster contains at most 4,194,304
pixels. Per-source integration is limited to 65,536 nodes, with at least four
angular samples for surfaces and 262,144 total nodes. A heatmap may require at
most one billion source/pixel evaluations. Vector masks have a separate budget
of one billion conservative geometry evaluations and 20 subdivision levels.
Invalid fields, unknown parameters, non-finite geometry, and arithmetic overflow
are reported as Typst plugin errors.

== References

- #link(
    "https://openstax.org/books/university-physics-volume-2/pages/5-5-calculating-electric-fields-of-charge-distributions",
  )[Electric fields of charge distributions]: continuous Coulomb integration.
- #link("https://bottosson.github.io/posts/oklab/")[Oklab]: perceptual color
  interpolation, implemented through the Rust `palette` crate.
- #link("https://typst.app/docs/reference/foundations/plugin/")[Typst plugins]:
  byte-based WASM interface.
