## Summary

<!-- Describe what changed and why. -->

## Related issues

<!-- Link related issues or discussions. Use "Closes #..." when appropriate. -->

## Type of change

- [ ] Bug fix
- [ ] Mathematical or physical model
- [ ] Algorithm, numerical method, or solver
- [ ] Geometry, data, or expression handling
- [ ] 2D or 3D diagram rendering and styling
- [ ] Typst API or WASM interface
- [ ] Examples or documentation
- [ ] CI or build tooling

## Mathematical and physical correctness

<!-- Name the mathematical or physical topic. For model or algorithm changes, describe definitions or equations, conventions, assumptions, units where applicable, and reference results. For numerical methods, include approximation limits and convergence or tolerance expectations. Write "N/A" if unrelated. -->

## API and user impact

<!-- Describe visible changes, configuration defaults, compatibility, and migration needs. For shared model or infrastructure changes, explain the effect on affected diagrams and mathematical or physical domains. Write "N/A" if unrelated. -->

## Validation

<!-- Check only commands actually run and relevant to this change. Include additional commands and results below; explain checks that were not run. -->

- [ ] `cargo fmt --all --check`
- [ ] `cargo check --workspace --locked`
- [ ] `cargo clippy --workspace --all-targets --locked -- -D warnings`
- [ ] `just fmt-check`
- [ ] `bash scripts/build-plugin.sh`
- [ ] `typst compile --root . docs/manual.typ /tmp/clio-manual.pdf`
- [ ] `typst compile --root . examples/gallery.typ /tmp/clio-gallery.pdf`

<!-- Additional validation commands, numerical comparisons, and results: -->

## Rendered output

<!-- Attach before/after images, SVGs, or PDFs for rendering changes. Include model inputs, computational settings, and display options needed to reproduce them. Write "N/A" if unrelated. -->

## Limitations and follow-up

<!-- Record known model or algorithm limitations, performance tradeoffs, or remaining work. Write "None" when applicable. -->
