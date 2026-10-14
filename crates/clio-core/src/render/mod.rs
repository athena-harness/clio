//! Shared rendering infrastructure for mathematical and physical diagrams.

pub mod color;
pub mod heatmap;

use crate::{require, Error};

pub(crate) fn pixel_count(resolution: [u32; 2]) -> Result<usize, Error> {
  let count = u64::from(resolution[0]) * u64::from(resolution[1]);
  require(
    resolution.iter().all(|&v| v > 0) && count <= 4_194_304,
    "resolution must be positive and contain at most 4194304 pixels",
  )?;
  Ok(count as usize)
}

pub(crate) fn encode_png(resolution: [u32; 2], pixels: &[u8]) -> Result<Vec<u8>, Error> {
  let mut bytes = Vec::new();
  {
    let mut encoder = png::Encoder::new(&mut bytes, resolution[0], resolution[1]);
    encoder.set_color(png::ColorType::Rgba);
    encoder.set_depth(png::BitDepth::Eight);
    encoder.set_source_srgb(png::SrgbRenderingIntent::Perceptual);
    let mut writer = encoder.write_header()?;
    writer.write_image_data(pixels)?;
    writer.finish()?;
  }
  Ok(bytes)
}
