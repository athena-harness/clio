//! Byte-oriented Typst plugin boundary for Clio.
//! Future exports decode request bytes, call clio-core, and return image bytes.

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();
