#import "electric-field/common.typ": sample-width, sample-height, integration-detail

#set page(paper: "a4", margin: 15mm, numbering: "1 / 1")
#set text(size: 9pt)
#set par(leading: 0.6em)
#set heading(numbering: none)

#let gallery-page(title, subtitle, panels) = {
  text(size: 22pt, weight: "bold")[Clio / Electric fields]
  v(5pt)
  text(size: 13pt, weight: "bold")[#title]
  v(3pt)
  text(fill: rgb("#475569"))[#subtitle]
  v(4pt)
  text(size: 7pt, fill: rgb("#64748b"))[
    Relative units; $k_e = 1$, $epsilon = 0.06$.
    Raster: #sample-width × #sample-height; integration detail: #integration-detail.
    Colors are clipped at the displayed range endpoints. Pale masks mark source intersections.
  ]
  v(10pt)
  grid(columns: (1fr, 1fr), gutter: 10pt, ..panels)
}

#gallery-page(
  [01 / Point charges and superposition],
  [Isolated sources, cancellation, neutral dipoles, and nonzero net charge.],
  (
    include "electric-field/single-charge.typ",
    include "electric-field/like-charges.typ",
    include "electric-field/dipole.typ",
    include "electric-field/unequal-charges.typ",
  ),
)

#pagebreak()
#gallery-page(
  [02 / Multipoles and line charges],
  [Two quadrupole geometries and the transition from a finite rod to a long wire.],
  (
    include "electric-field/square-quadrupole.typ",
    include "electric-field/axial-quadrupole.typ",
    include "electric-field/finite-line.typ",
    include "electric-field/long-wire.typ",
  ),
)

#pagebreak()
#gallery-page(
  [03 / Wires, disks, and rings],
  [Prescribed line and surface densities reveal different source geometries.],
  (
    include "electric-field/line-dipole.typ",
    include "electric-field/square-loop.typ",
    include "electric-field/uniform-disk.typ",
    include "electric-field/charged-ring.typ",
  ),
)

#pagebreak()
#gallery-page(
  [04 / Openings and charged surfaces],
  [Finite and infinite surfaces, fringing, and signed field components.],
  (
    include "electric-field/uniform-annulus.typ",
    include "electric-field/plane-with-hole.typ",
    include "electric-field/parallel-disks.typ",
    include "electric-field/coplanar-disks.typ",
  ),
)
