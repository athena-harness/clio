use clio_core::{
  geometry::Plane,
  render::{
    color::{ColorScale, ColorSpace, PreparedScale, Transform},
    heatmap::{self, Colorbar, Grid, Orientation, Sampling},
  },
};
use std::io::Cursor;

fn scale() -> ColorScale {
  ColorScale {
    range: [-1.0, 1.0],
    transform: Transform::Linear,
    stops: vec!["#000000".into(), "#ffffff".into()],
    space: ColorSpace::Srgb,
  }
}

fn decode(bytes: Vec<u8>) -> Vec<u8> {
  let mut reader = png::Decoder::new(Cursor::new(bytes)).read_info().unwrap();
  let mut pixels = vec![0; reader.output_buffer_size().unwrap()];
  reader.next_frame(&mut pixels).unwrap();
  pixels
}

#[test]
fn png_rows_follow_ymax_to_ymin_and_preserve_singularity_alpha() {
  let grid = Grid {
    resolution: [1, 3],
    bounds: [-1.0, 1.0, -1.5, 1.5],
    plane: Plane::default(),
    sampling: Sampling::Centers,
  };
  let scale = PreparedScale::new(&scale()).unwrap();
  let bytes = heatmap::render(&grid, &scale, [12, 34, 56, 0], |position| {
    Ok(if position[1] == 0.0 { None } else { Some(position[1]) })
  })
  .unwrap();
  assert_eq!(decode(bytes), [255, 255, 255, 255, 12, 34, 56, 0, 0, 0, 0, 255]);
}

#[test]
fn vertical_colorbar_runs_from_maximum_at_top_to_minimum_at_bottom() {
  let bytes = heatmap::render_colorbar(&Colorbar {
    color: scale(),
    resolution: [1, 2],
    orientation: Orientation::Vertical,
  })
  .unwrap();
  assert_eq!(decode(bytes), [255, 255, 255, 255, 0, 0, 0, 255]);
}

#[test]
fn signed_nonlinear_scales_keep_zero_at_the_center() {
  for transform in [Transform::Log { reference: 0.1 }, Transform::Asinh { reference: 0.1 }] {
    let scale = PreparedScale::new(&ColorScale { transform, ..scale() }).unwrap();
    assert_eq!(scale.normalize(0.0), 0.5);
    assert_eq!(scale.normalize(-10.0), 0.0);
    assert_eq!(scale.normalize(10.0), 1.0);
  }
}

#[test]
fn invalid_sampling_parameters_and_color_stops_are_rejected() {
  let grid = Grid {
    resolution: [1, 3],
    sampling: Sampling::Endpoints,
    ..Grid::default()
  };
  assert!(grid.validate().is_err());
  assert!(PreparedScale::new(&ColorScale {
    stops: vec!["invalid".into(), "#ffffff".into()],
    ..scale()
  })
  .is_err());
}
