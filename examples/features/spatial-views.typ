// Toggle the spatial companions without changing sources, planar sampling, or integration.
#import "../../lib.typ": *
#import "../electric/custom-models.typ": custom-models
#import "../electric/common.typ": mask-thickness, plot-field
#import "../electric/spatial-common.typ": scene-for

#set page(paper: "a4", margin: 15mm)
#set text(size: 10pt)

#let show-3d = sys.inputs.at("show-3d", default: "true") == "true"
#let model = custom-models.at("triangle-mesh")

= Folded geometry: slice and spatial context

The two views share the same prescribed sources and physical parameters. Purple
represents the folded sheet; teal represents the annulus. The spatial view shows
the complete geometry within the display box, the observation plane, and field
lines seeded outside that plane.

#electric-field-lines(
  model.sources,
  model.seeds,
  grid: model.grid,
  field: plot-field,
  tracing: model.tracing,
  style: field-line-style(thickness: 0.35, arrow-size: 1.8, arrow-spacing: 24),
  endpoints: field-line-endpoints(size: 2, thickness: 0.6),
  source-overlay: source-overlay(
    color: "#a78bfa",
    thickness: mask-thickness,
    overrides: (
      (
        source: 1,
        style: source-style(color: "#14b8a6", thickness: mask-thickness),
      ),
    ),
  ),
  scene: if show-3d { scene-for() } else { none },
)

The amber diamond indicates numerical stagnation in the planar trace, not a
physical source or a precisely located null. Spatial lines integrate the full
field and use independent world-space seeds; they need not reproduce the planar
curves. Neither set of seeds represents a calibrated electric flux.

== A magnitude slice in space

#electric-field-heatmap(
  model.sources,
  grid: model.grid,
  field: plot-field,
  source-overlay: source-overlay(color: "#a78bfa", thickness: mask-thickness),
  scene: if show-3d { scene-for() } else { none },
)

Pass `--input show-3d=false` to compile only the planar diagrams. Library calls
use `scene: none` to disable the companion; this is also the default.
