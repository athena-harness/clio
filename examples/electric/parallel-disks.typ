// All available views of this object share one example module.
#let heatmap() = [
  #import "models.typ": grid-for, sources-for
  #import "../../lib.typ": *
  #import "common.typ": example-panel, signed-colors, surface-sampling, yz-plane

  #example-panel(
    [Finite parallel-disk capacitor],
    sources-for("parallel-disks"),
    grid: grid-for("parallel-disks"),
    description: [Opposite uniform surface charges on two parallel disks.],
    formula: [$sigma_1 = +1, quad sigma_2 = -1, quad d = 0.8$],
    quantity: field-component((1, 0, 0)),
    color: signed-colors(maximum: 12),
    scalar-label: $E_x$,
    note: [A finite prescribed-charge model shows fringing. Charge
      redistribution on real conductors is not modeled.],
  )

]

#let field-lines() = [
  #import "models.typ": sources-for
  #import "../../lib.typ": *
  #import "common.typ": (
    example-panel, example-tracing, integration-detail, yz-plane,
  )
  #import "line-common.typ": line-field, line-grid-for, line-overlay

  #let line-grid = line-grid-for("parallel-disks")
  #let sources = sources-for("parallel-disks")
  #example-panel(
    [Parallel-disk field lines],
    sources,
    grid: line-grid,
    description: [A symmetry-plane slice shows the central field and fringing.],
    formula: [$sigma_1 = +1, quad sigma_2 = -1$],
    note: [Seeds lie between finite, prescribed-charge disks. No conductor
      charge redistribution is solved.],
    legend: false,
    plot: electric-field-lines(
      sources,
      (seed-segment((0, -1.35), (0, 1.35), count: 17),),
      grid: line-grid,
      field: line-field,
      tracing: example-tracing(step: 0.03),
      source-overlay: line-overlay,
    ),
  )

]

#let spatial() = [
  #import "spatial-common.typ": spatial-panel, sphere-seeds
  #import "common.typ": magnitude-colors
  #import "models.typ": grid-for, sources-for

  #let seeds = {
    let result = ()
    for x in (-0.54, -0.26) {
      for i in range(6) {
        let angle = i * calc.pi / 3
        result.push((x, 0.45 * calc.cos(angle), 0.45 * calc.sin(angle)))
      }
    }
    result
  }
  #spatial-panel(
    [Parallel disks: spatial field],
    sources-for("parallel-disks"),
    seeds,
    color: magnitude-colors(maximum: 12),
    observation: grid-for("parallel-disks"),
    source-colors: ("#dc504399", "#3769be99"),
    note: [The planar heatmap shows $E_x$; this spatial slice shows
      $abs(bold(E))$. Two oppositely charged disks reveal the gap field and
      spatial fringing.],
  )
]

#import "common.typ": object-example

#context object-example(
  [Parallel disks],
  heatmap,
  field-lines,
  spatial: spatial,
)
