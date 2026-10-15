// Standalone comparison of custom models mixed with built-in charge sources.
#set page(paper: "a4", margin: 15mm, numbering: "1 / 1")
#set text(size: 9pt)
#set par(leading: 0.6em)

= Clio / Custom charge geometry

Parametric curves, surfaces, volumes, and triangle meshes share the built-in
field evaluator. Relative units; Coulomb multiplier 1 and softening 0.06.

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  include "electric-field/charged-arc.typ",
  include "electric-field/warped-surface.typ",

  include "electric-field/charged-volume.typ",
  include "electric-field/triangle-mesh.typ",
)

#pagebreak()
= Clio / Custom geometry field lines

The same source models and observation grids, with planar RK4 tracing and source
capture.

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  include "electric-field-lines/charged-arc.typ",
  include "electric-field-lines/warped-surface.typ",

  include "electric-field-lines/charged-volume.typ",
  include "electric-field-lines/triangle-mesh.typ",
)
