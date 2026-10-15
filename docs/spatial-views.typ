#import "style.typ": fn

= Spatial views

A planar source mask is an intersection with the observation plane. It cannot
show how a folded sheet extends outside that plane. An optional spatial
companion shows the same sources as complete geometry inside a display box,
together with the observation plane and independently seeded spatial lines.

== Opt in from a planar diagram

Both #fn("electric-field-lines") and #fn("electric-field-heatmap") accept
`scene: none` by default. Pass a #fn("field-scene") dictionary to place a
spatial view to the right. The two views share the source array, physical field
parameters, observation plane, and local bounds. Disabling the scene performs no
spatial rendering. The byte renderers continue to return a single planar SVG.

```typ
#let show-3d = true
#electric-field-lines(
  charges,
  (seed-circle((-0.7, 0), count: 18),),
  scene: if show-3d {
    field-scene(
      camera: field-camera(
        azimuth: -1.12, elevation: 0.48, span: 5.4,
      ),
      lines: field-scene-lines((
        (-0.5, 0.15, 0.15),
        (-0.5, -0.15, -0.15),
      )),
    )
  } else { none },
)
```

Use #fn("electric-field-scene") or #fn("electric-field-scene-bytes") for a
standalone view and compose its placement in Typst. The repository example
`examples/spatial-views.typ` demonstrates both enabled and disabled companions:

```sh
typst compile --root . examples/spatial-views.typ /tmp/clio-spatial.pdf
typst compile --root . --input show-3d=false examples/spatial-views.typ /tmp/clio-planar.pdf
```

== Geometry, camera, and field sampling

The camera is orthographic. Its target is the viewport center; azimuth rotates
around world z, elevation measures angle above xy, and span is the visible
horizontal world-space length. Increasing span zooms out. Camera angles use
radians. Changing the camera never changes the field calculation.

The spatial box uses two world-space corners, unlike the planar grid's four
local bounds. Sources and slice geometry are clipped to this box; spatial
tracing stops at its boundary. Infinite planes remain infinite in the field
calculation even though their displayed patch is finite.

Source colors follow source-array order and cycle if fewer colors are supplied.
Their alpha controls transparency. Source curves and boundary edges have a pixel
thickness; point charges have a pixel radius. Parameterized geometry uses the
prepared source cells, and volumes show only the exterior shell of their
tetrahedral cells. Increasing source samples refines both integration and the
parameterized display geometry. Built-in round surfaces use a separate fixed
display tessellation.

The default slice is pale blue, and its arrow indicates the positive observation
normal. Set `slice: none` to hide it, or enable a magnitude heatmap:

```typ
field-scene(
  slice: field-scene-slice(
    color: field-colors(range: (0, 12)),
    opacity: 0.7,
    samples: (48, 36),
  ),
)
```

Slice samples control colored vector tiles independently of source quadrature,
planar raster samples, and the SVG viewport size. The slice evaluates the full
three-dimensional field magnitude, not just its in-plane components. Undefined
unregularized samples remain transparent. This is a heatmap on a plane in space,
not a volume rendering. Use the same color configuration for a separate #fn(
  "field-colorbar",
) in Typst.

== Genuine spatial field lines

#fn("field-scene-lines") accepts explicit *three-dimensional world-space seeds*.
Rust follows the normalized full vector with fixed-step RK4. No field component
is dropped, and seeds need not lie on the observation plane. Planar seed
constructors are not spatial seeds. No spatial lines are drawn unless a line
configuration is supplied.

#fn("spatial-field-line-tracing") separates step size, step limit, weak-field
threshold, source capture distance, and direction from the camera and styles.
The same caveats as planar tracing apply: no adaptive error control or exact
null localization is performed, and seed density is not a calibrated flux.
Source capture requires step no greater than a nonzero capture radius.

Native Rust callers can obtain world-coordinate paths and endpoint reasons
through `electrostatics::scene::trace`. The SVG includes empty diagnostic groups
with `data-spatial-line`, `data-start-termination`, and `data-end-termination`;
projected line segments refer to their index with `data-line`. These retain
numerical reasons even though diagnostic endpoint symbols are currently specific
to the planar view.

== Rendering limits

Geometry, slices, curves, and arrows are vector SVG primitives. Small primitives
are sorted by average camera depth, with translucent materials composited from
back to front. This improves depth cues but does not guarantee exact visibility
where transparent surfaces intersect or overlap cyclically. The axis key is a
screen overlay. The scene is a static projection, not an interactive 3D viewer.

At most 65536 slice tiles, 1024 spatial seeds, 10000 steps per branch, and
4194304 potential trace vertices are accepted. Source geometry is limited to
131072 prepared cells per custom source. Slice evaluation and spatial tracing
each have a one-billion-evaluation budget. Rendering additionally limits output
to 262144 primitives and 64 MiB of SVG; simplify sampling or displayed curves if
that limit is reached.
