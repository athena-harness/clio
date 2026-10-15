#import "../../lib.typ": *
#import "common.typ": line-panel
#import "../electric-field/common.typ": example-tracing

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
