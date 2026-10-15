#import "../lib.typ": *
#import "style.typ": code-example

= Custom charge geometry

Custom models and built-in shortcuts share the same `sources` array. Rust
prepares all sources into weighted Coulomb nodes, then uses the same field
evaluator for heatmaps and field lines. Existing constructors such as
`charged-disk` retain their signatures and behavior. Custom geometry requires no
backend modification.

== Parametric domains

Describe a curve with three expressions in `t`, a surface with expressions in
`u, v`, or a volume with expressions in `u, v, w`. Coordinates are world-space
positions. `density` is signed charge per *physical* length, area, or volume; it
may be a constant or an expression in the same parameters. Named `constants`
allow model dimensions and density coefficients to change without rewriting
expressions.

```typ
#let shell = charged-surface(
  ("a*sin(u)*cos(v)", "b*sin(u)*sin(v)", "c*cos(u)"),
  bounds: ((0, calc.pi), (0, 2 * calc.pi)),
  constants: (a: 1.1, b: 0.8, c: 0.6),
  density: "1 + 0.2*cos(u)",
  samples: (24, 48),
)
```

The surface above is an ellipsoidal shell. To charge its interior, use a
three-parameter volume map instead of a surface mesh. An indexed closed triangle
mesh still describes a charged *surface*, not a volume.

Rust computes the coordinate derivatives using forward automatic
differentiation. With parameter coordinates $t$, $(u,v)$, or $(u,v,w)$, the
integration weights are

$
  dif q & = lambda(t) norm(bold(r)'(t)) dif t, \
  dif q & = sigma(u, v) norm(partial_u bold(r) times partial_v bold(r)) dif u dif v, \
  dif q & = rho(u, v, w) abs(det(D bold(r))) dif u dif v dif w.
$

Midpoint quadrature evaluates density and geometry once per integration node;
prepared nodes are reused at every observation point. Do not multiply the
density by the Jacobian yourself. The rectangular parameter bounds must be
finite and strictly increasing. Curved physical domains are expressed through
the map; multiple parameter patches can be combined as separate sources.

== Mix a custom curve with a point charge

#let arc = charged-curve(
  ("a*cos(t)", "b*sin(t)", 0),
  range: (0.15 * calc.pi, 1.85 * calc.pi),
  constants: (a: 1.1, b: 0.8),
  density: "1 + 0.4*cos(2*t)",
  samples: 128,
)
#code-example(
  ```typ
  #let arc = charged-curve(
    ("a*cos(t)", "b*sin(t)", 0),
    range: (0.15 * calc.pi,
      1.85 * calc.pi),
    constants: (a: 1.1, b: 0.8),
    density: "1 + 0.4*cos(2*t)",
    samples: 128,
  )
  #electric-field-heatmap(
    (arc, point-charge((0.1, 0, 0),
      charge: -1.5)),
    source-overlay: source-overlay(
      thickness: 0.04,
    ),
  )
  ```,
  electric-field-heatmap(
    (arc, point-charge((0.1, 0, 0), charge: -1.5)),
    source-overlay: source-overlay(thickness: 0.04),
  ),
  caption: [The renderer receives both sources in one request and adds their
    vector fields.],
)

== Expression language

A coordinate or density accepts a number or an ASCII expression string.
Expressions are parsed and evaluated in Rust; Typst functions are not serialized
or executed inside WASM. The language supports:

- Numbers, including decimal and scientific notation.
- The model parameters: `t`, `u, v`, or `u, v, w` according to dimension.
- Named constants, plus built-in `pi` and `e`.
- Parentheses; unary `+` and `-`; binary `+`, `-`, `*`, `/`, and `^`.
- `sin`, `cos`, `tan`, `sqrt`, `exp`, `ln`, `abs`, `sinh`, `cosh`, and `atan`.

Angles are radians. Multiplication must be explicit, as in `2*pi*t`.
Exponentiation is right associative and binds more tightly than unary minus:
`-2^2` is `-4`, and `2^3^2` is `512`. Each function takes one argument. Constant
names start with an ASCII letter, followed by letters, digits, or underscores;
they cannot replace `t`, `u`, `v`, `w`, `pi`, or `e`.

Coordinate expressions must have finite values at cell corners and midpoints,
and finite derivatives with a nonzero Jacobian at integration midpoints. Density
is evaluated only at midpoints; its derivatives are not used. Avoid
nondifferentiable parameterizations at integration nodes. Undefined values,
unknown identifiers, invalid syntax, and non-finite arithmetic produce errors.
The expression language does not provide conditionals, implicit regions, or
arbitrary program execution. Use separate patches, mesh data, or signed source
superposition for models outside a single smooth parameter map.

== Triangle meshes

Use `charged-triangle-mesh` for geometry supplied as vertex and face arrays.
Faces are triples of zero-based vertex indices; open, closed, and disconnected
surfaces are accepted. Each triangle must have positive finite area. Winding
does not change the sign of charge: `density` determines that sign.

```typ
#let mesh = charged-triangle-mesh(
  ((-1, -0.8, 0), (-1, 0.8, 0), (0.1, 0, 0.75), (0.1, 0, -0.75)),
  ((0, 1, 2), (1, 0, 3)),
  density: (1, -0.5),
  samples: 8,
)
```

Density can be one number for the entire mesh or one number per face. An edge
subdivision count of $n$ produces $n^2$ equal-area subtriangles per face, each
sampled at its centroid. Refining the mesh geometry and increasing the
quadrature subdivision count are separate operations. Load external model data
in Typst and pass its arrays to the constructor; the plugin itself performs no
file I/O.

== Masks, tracing, and accuracy

Custom sources accept the existing `source-overlay` styles and per-source color
overrides. A parameter cell is approximated by a segment, two triangles, or six
tetrahedra. Masks show their intersection with the observation slice, expanded
by half the configured thickness. Triangle-mesh masks use the input faces
directly. Filled volume cells are visible throughout their interior.

Field-line source capture uses the same prepared geometry. Parameter cells with
zero midpoint charge and zero-density mesh faces do not capture lines. Masks can
still display these uncharged cells, just as a zero-charge built-in source can
be shown. Source capture can be disabled with `source-radius: 0`; field lines
inside a charged volume then follow the computed regularized field.

A bounding-volume hierarchy accelerates distance queries for the prepared cells.
It is built once per model preparation and reused by masks and source capture.
SVG masks use native paths for planar primitives and adaptive distance contours
for general slices; their edge precision is independent of the heatmap raster.

Parameter sample counts control both quadrature accuracy and the geometric
approximation used for masks and source capture. Image resolution, field
softening, stroke styling, and tracing step remain independent. Refine sampling
until the features of interest converge. The backend does not adapt the mesh,
remove overlapping patches, or solve conductor charge redistribution.
Overlapping sources add their charges; a parameter map that covers a physical
region twice integrates it twice. Custom sources have the same node-based
singularity behavior as existing finite continuous sources at zero softening.

Each custom source has at most 65,536 quadrature nodes, and the entire source
array retains the limit of 262,144 nodes. Expressions have at most 4,096 bytes,
256 instructions, and fewer than 32 nesting levels; each model accepts at most
64 named constants. Preparation across the request is limited to 64 million
expression instructions. Geometric source-capture and vector contour work is
charged per prepared primitive, with tetrahedra charged as four face checks,
rather than per source. This is a conservative budget even when the hierarchy
skips cells. Detailed masks or traces can reach their separate one-billion-work
budgets. Reduce model sampling, or omit masks and disable source capture when
unnecessary; lowering raster resolution does not reduce SVG contour complexity.

Compile `examples/custom-geometry.typ` for four mixed models and matching field
lines, also included on gallery pages 9--10. Shared source definitions live in
`examples/electric-field/custom-models.typ`.
