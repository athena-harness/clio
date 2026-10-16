//! Shared self-contained SVG documents and embedded scalar rasters.

use base64::{engine::general_purpose::STANDARD, Engine};

pub(crate) fn begin([width, height]: [u32; 2]) -> String {
  format!("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{width}\" height=\"{height}\" viewBox=\"0 0 {width} {height}\"><defs><clipPath id=\"clio-viewport\"><rect width=\"{width}\" height=\"{height}\"/></clipPath></defs><g clip-path=\"url(#clio-viewport)\">")
}

pub(crate) fn finish(mut svg: String) -> Vec<u8> {
  svg.push_str("</g></svg>");
  svg.into_bytes()
}

pub(crate) fn embed_png(svg: &mut String, png: &[u8], [width, height]: [u32; 2]) {
  svg.push_str(&format!(
    "<image width=\"{width}\" height=\"{height}\" preserveAspectRatio=\"none\" href=\"data:image/png;base64,{}\"/>",
    STANDARD.encode(png)
  ));
}

pub(crate) fn hex(color: [u8; 4]) -> String {
  format!("#{:02x}{:02x}{:02x}", color[0], color[1], color[2])
}
