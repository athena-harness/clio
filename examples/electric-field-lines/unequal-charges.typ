#import "../../lib.typ": *
#import "common.typ": line-panel

#line-panel(
  "unequal-charges",
  [Unequal opposite charges],
  (seed-circle((-0.6, 0), count: 32, phase: 0.05),),
  description: [A stronger positive source feeds a weaker negative sink.],
  formula: [$q_1 = +2, quad q_2 = -1$],
  note: [Some curves reach the negative charge; others leave the viewport. Seed
    counts do not measure electric flux.],
)
