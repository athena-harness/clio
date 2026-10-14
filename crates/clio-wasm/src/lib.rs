//! Byte-oriented Typst plugin boundary for Clio.
//! JSON requests enter; PNG bytes leave. No file or system access is used.

use serde::de::DeserializeOwned;

#[cfg(target_arch = "wasm32")]
wasm_minimal_protocol::initiate_protocol!();

fn decode<T: DeserializeOwned>(input: &[u8]) -> Result<T, String> {
  if input.len() > 16 * 1024 * 1024 {
    return Err("JSON request exceeds 16 MiB".into());
  }
  serde_json::from_slice(input).map_err(|error| format!("invalid JSON request: {error}"))
}

/// Renders a JSON electric-field request into PNG bytes.
///
/// # Parameters
/// * `input`: JSON encoding of `clio_core::electrostatics::heatmap::Request`.
///
/// # Returns
/// In-memory PNG bytes accepted by Typst's `image` function.
///
/// # Errors
/// Reports decoding, validation, numerical, and encoding errors to Typst.
#[cfg_attr(target_arch = "wasm32", wasm_minimal_protocol::wasm_func)]
pub fn render_electric_field(input: &[u8]) -> Result<Vec<u8>, String> {
  clio_core::electrostatics::heatmap::render(&decode(input)?).map_err(|error| error.to_string())
}

/// Renders a JSON colorbar request using the heatmap's shared color mapping.
///
/// # Parameters
/// * `input`: JSON encoding of `clio_core::render::heatmap::Colorbar`.
///
/// # Returns
/// PNG bytes without labels or other document presentation.
///
/// # Errors
/// Reports decoding, color validation, and encoding errors to Typst.
#[cfg_attr(target_arch = "wasm32", wasm_minimal_protocol::wasm_func)]
pub fn render_colorbar(input: &[u8]) -> Result<Vec<u8>, String> {
  clio_core::render::heatmap::render_colorbar(&decode(input)?).map_err(|error| error.to_string())
}
