#import "models.typ": sources-for, grid-for
#import "../../lib.typ": *
#import "common.typ": example-panel, line-sampling, magnitude-colors

#example-panel(
  [Long-wire approximation],
  sources-for("long-wire"),
  grid: grid-for("long-wire"),
  description: [The central region of a long, finite charged wire.],
  formula: [$lambda = 1, quad L = 16$],
  color: magnitude-colors(maximum: 16),
  note: [The model remains finite. Its central field approximates that of an infinite line away from the core.],
)
