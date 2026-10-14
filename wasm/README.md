# WASM artifact

`scripts/build-plugin.sh` places the compiled plugin at `wasm/clio.wasm`.
The binary is generated locally and included with a future package release.
Typst wrappers will load it through a path inside the package, never through
a consumer project's Cargo target directory.
