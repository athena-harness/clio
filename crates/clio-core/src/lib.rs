//! Mathematical and physical computation and in-memory rendering for Clio.
//! This crate is independent of Typst and the WASM plugin protocol.

pub mod electrostatics;
pub mod geometry;
pub mod render;

/// Errors from model validation, numerical evaluation, or image encoding.
#[derive(Debug, thiserror::Error)]
pub enum Error {
  /// A parameter is outside the supported domain.
  #[error("invalid parameter: {0}")]
  Invalid(String),
  /// Arithmetic exceeded the supported finite range.
  #[error("numerical failure: {0}")]
  Numerical(&'static str),
  /// PNG encoding failed.
  #[error("PNG encoding failed: {0}")]
  Encoding(#[from] png::EncodingError),
}

pub(crate) fn require(valid: bool, message: &str) -> Result<(), Error> {
  if valid {
    Ok(())
  } else {
    Err(Error::Invalid(message.into()))
  }
}
