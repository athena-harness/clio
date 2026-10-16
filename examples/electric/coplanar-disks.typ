// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, signed-colors, surface-sampling, xy-grid

  #example-panel(
    [Opposite coplanar disks],
    sources-for("coplanar-disks"),
    grid: grid-for("coplanar-disks"),
    description: [The normal component above two oppositely charged patches.],
    formula: [$sigma_1 = +1, quad sigma_2 = -1, quad z_"obs" = 0.35$],
    quantity: field-component((0, 0, 1)),
    color: signed-colors(maximum: 6),
    scalar-label: $E_z$,
    note: [A diverging palette distinguishes positive and negative normal
      fields; the observation slice is above both disks.],
  )

]

#let field-lines() = [
  #import "../../lib.typ": *
  #import "line-common.typ": line-panel
  #import "common.typ": example-tracing

  #line-panel(
    "coplanar-disks",
    [Projected coplanar-disk flow],
    (seed-circle((-0.8, 0), radius: 0.35, count: 24),),
    description: [In-plane streamlines above two opposite charged patches.],
    formula: [$sigma_1 = +1, quad sigma_2 = -1, quad z_"obs" = 0.35$],
    tracing: example-tracing(mode: "projected"),
    direction-label: [Arrows follow the in-plane projection.],
    note: [This matches the heatmap's elevated slice. Curves trace projected E,
      while the heatmap shows E_z; these are not 3D field lines.],
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for x in (-1.0, -0.6) {
      for y in (-0.2, 0.2) {
        for z in (-0.14, 0.14) { result.push((x, y, z)) }
      }
    }
    result
  }
  #spatial-panel(
    [Coplanar disks: spatial field],
    sources-for("coplanar-disks"),
    seeds,
    color: magnitude-colors(maximum: 6),
    observation: grid-for("coplanar-disks"),
    source-colors: ("#dc504399", "#3769be99"),
    note: [The planar heatmap shows $E_z$; this spatial slice shows
      $abs(bold(E))$. The observation plane is elevated above the source disks;
      spatial curves are full-vector paths.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Coplanar disks],
  heatmap,
  field-lines,
  spatial: spatial,
)
