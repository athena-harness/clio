#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

cargo build --manifest-path "$project_root/Cargo.toml" \
  --package clio-wasm --release --locked --target wasm32-unknown-unknown \
  --target-dir "$project_root/target"

mkdir -p "$project_root/wasm"
cp "$project_root/target/wasm32-unknown-unknown/release/clio_wasm.wasm" \
  "$project_root/wasm/clio.wasm"
