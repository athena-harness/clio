// Optional spatial companions are composed in Typst and evaluated only when requested.
#import "electrostatics.typ" as planar
#import "spatial.typ": electric-field-scene
#import "render.typ": field-grid

#let compose(planar-view, sources, width, scene, observation, field) = {
  if scene == none {
    planar-view
  } else {
    block(width: width, grid(
      columns: (1fr, 1fr),
      gutter: 8pt,
      planar-view,
      electric-field-scene(
        sources,
        grid: observation,
        field: field,
        scene: scene,
      ),
    ))
  }
}

/// Display a heatmap with an optional spatial companion using the same physical model.
#let electric-field-heatmap(sources, width: 100%, scene: none, ..options) = {
  let named = options.named()
  compose(
    planar.electric-field-heatmap(
      sources,
      width: if scene == none { width } else { 100% },
      ..options,
    ),
    sources,
    width,
    scene,
    named.at("grid", default: field-grid()),
    named.at("field", default: planar.field-parameters()),
  )
}

/// Display planar field lines with an optional independently seeded spatial companion.
#let electric-field-lines(
  sources,
  seeds,
  width: 100%,
  scene: none,
  ..options,
) = {
  let named = options.named()
  compose(
    planar.electric-field-lines(
      sources,
      seeds,
      width: if scene == none { width } else { 100% },
      ..options,
    ),
    sources,
    width,
    scene,
    named.at("grid", default: field-grid(resolution: (480, 360))),
    named.at("field", default: planar.field-parameters()),
  )
}
