use clio_core::{
  electrostatics::{
    continuous_charge::Annulus,
    heatmap::{self, Quantity, Request},
    overlay::{SourceOverlay, SourceOverride, SourceStyle},
    point_charges::PointCharge,
    FieldOptions, Source,
  },
  geometry::Plane,
  render::{
    color::ColorScale,
    heatmap::{Grid, Sampling},
  },
};
use std::io::Cursor;

fn request(sources: Vec<Source>) -> Request {
  Request {
    sources,
    grid: Grid {
      resolution: [3, 3],
      bounds: [-1.0, 1.0, -1.0, 1.0],
      sampling: Sampling::Endpoints,
      plane: Plane::default(),
    },
    field: FieldOptions::default(),
    quantity: Quantity::Magnitude,
    color: ColorScale::default(),
    singularity_color: "#00000000".into(),
    source_overlay: Some(SourceOverlay {
      style: SourceStyle {
        color: "#123456".into(),
        thickness: 0.1,
      },
      overrides: vec![],
    }),
  }
}

fn pixels(request: &Request) -> Vec<u8> {
  let bytes = heatmap::render(request).unwrap();
  let mut reader = png::Decoder::new(Cursor::new(bytes)).read_info().unwrap();
  let mut output = vec![0; reader.output_buffer_size().unwrap()];
  reader.next_frame(&mut output).unwrap();
  output
}

#[test]
fn opaque_source_mask_covers_an_exact_point_singularity() {
  let mut request = request(vec![Source::Point(PointCharge {
    position: [0.0; 3],
    charge: 1.0,
  })]);
  request.field.softening = 0.0;
  assert_eq!(&pixels(&request)[16..20], &[0x12, 0x34, 0x56, 255]);
}

#[test]
fn surface_mask_preserves_annulus_holes_and_observation_offsets() {
  let source = Source::Annulus(Annulus {
    plane: Plane::default(),
    inner_radius: 0.5,
    outer_radius: 1.2,
    density: 1.0,
    radial_samples: 8,
    angular_samples: 16,
  });
  let mut request = request(vec![source]);
  let output = pixels(&request);
  assert_ne!(&output[16..20], &[0x12, 0x34, 0x56, 255]);
  assert_eq!(&output[12..16], &[0x12, 0x34, 0x56, 255]);
  request.grid.plane.origin[2] = 0.2;
  assert_ne!(&pixels(&request)[12..16], &[0x12, 0x34, 0x56, 255]);
}

#[test]
fn per_source_overrides_can_recolor_or_disable_a_mask() {
  let mut request = request(vec![Source::Point(PointCharge {
    position: [0.0; 3],
    charge: 1.0,
  })]);
  request.source_overlay.as_mut().unwrap().overrides = vec![SourceOverride {
    source: 0,
    style: Some(SourceStyle {
      color: "#abcdef".into(),
      thickness: 0.2,
    }),
  }];
  assert_eq!(&pixels(&request)[16..20], &[0xab, 0xcd, 0xef, 255]);
  request.source_overlay.as_mut().unwrap().overrides[0].style = None;
  assert_ne!(&pixels(&request)[16..20], &[0xab, 0xcd, 0xef, 255]);
}

#[test]
fn translucent_overlay_blends_with_the_existing_field_pixel() {
  let mut request = request(vec![Source::Point(PointCharge {
    position: [0.0; 3],
    charge: 1.0,
  })]);
  request.source_overlay = None;
  let background = pixels(&request);
  request.source_overlay = Some(SourceOverlay {
    style: SourceStyle {
      color: "#ffffff80".into(),
      thickness: 0.1,
    },
    overrides: vec![],
  });
  let output = pixels(&request);
  for i in 16..19 {
    let expected = (255.0 * 128.0 / 255.0 + f64::from(background[i]) * 127.0 / 255.0).round() as u8;
    assert_eq!(output[i], expected);
  }
}

#[test]
fn invalid_source_indices_and_thickness_are_rejected() {
  let mut request = request(vec![Source::Point(PointCharge {
    position: [0.0; 3],
    charge: 1.0,
  })]);
  request.source_overlay.as_mut().unwrap().overrides = vec![SourceOverride { source: 1, style: None }];
  assert!(heatmap::render(&request).is_err());
  let overlay = request.source_overlay.as_mut().unwrap();
  overlay.overrides.clear();
  overlay.style.thickness = 0.0;
  assert!(heatmap::render(&request).is_err());
}
