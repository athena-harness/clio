use clio_core::{
  electrostatics::{
    field_lines::{self, Background, Direction, LineStyle, Mode, Request, Seeds, Tracing},
    point_charges::PointCharge,
    FieldOptions, Source,
  },
  render::heatmap::Grid,
};

fn request(charge: f64) -> Request {
  Request {
    sources: vec![Source::Point(PointCharge {
      position: [0.0; 3],
      charge,
    })],
    grid: Grid::default(),
    field: FieldOptions::default(),
    seeds: vec![Seeds::Points {
      points: vec![[0.3, 0.1]],
    }],
    tracing: Tracing::default(),
    style: LineStyle {
      color: "#123456".into(),
      width: 1.0,
      arrow_spacing: Some(30.0),
      arrow_size: 4.0,
    },
    background: Background::Solid {
      color: "#ffffff".into(),
    },
    source_overlay: None,
  }
}

#[test]
fn positive_charge_paths_are_radial_and_ordered_outward() {
  let request = request(1.0);
  let lines = field_lines::trace(&request).unwrap();
  let line = &lines[0];
  assert!(line.len() > 10);
  assert!(line.iter().all(|p| (p[1] - p[0] / 3.0).abs() < 1e-10));
  assert!(line.windows(2).all(|pair| pair[1][0] >= pair[0][0]));
  let end = line.last().unwrap();
  assert!((end[0] - request.grid.bounds[1]).abs() < 1e-10);
}

#[test]
fn negative_charge_paths_point_inward_even_for_backward_only_tracing() {
  let mut request = request(-1.0);
  request.tracing.direction = Direction::Backward;
  let lines = field_lines::trace(&request).unwrap();
  assert!(lines[0].windows(2).all(|pair| pair[1][0] <= pair[0][0]));
  assert_eq!(*lines[0].last().unwrap(), [0.3, 0.1]);
}

#[test]
fn tracing_stops_at_sources_and_respects_the_step_limit() {
  let mut request = request(-1.0);
  request.tracing.direction = Direction::Forward;
  let lines = field_lines::trace(&request).unwrap();
  let end = lines[0].last().unwrap();
  assert!(end[0].hypot(end[1]) <= request.tracing.source_radius + request.tracing.step);
  request.tracing.max_steps = 3;
  assert_eq!(field_lines::trace(&request).unwrap()[0].len(), 4);
}

#[test]
fn normalized_paths_are_independent_of_coulomb_multiplier() {
  let mut request = request(1.0);
  let original = field_lines::trace(&request).unwrap();
  request.field.coulomb_constant = 5.0;
  let scaled = field_lines::trace(&request).unwrap();
  assert_eq!(original[0].len(), scaled[0].len());
  assert!(original[0]
    .iter()
    .zip(&scaled[0])
    .all(|(a, b)| (a[0] - b[0]).abs() < 1e-10 && (a[1] - b[1]).abs() < 1e-10));
}

#[test]
fn curved_dipole_paths_converge_to_constant_axisymmetric_flux() {
  let mut request = request(1.0);
  request.sources = vec![
    Source::Point(PointCharge {
      position: [-0.7, 0.0, 0.0],
      charge: 1.0,
    }),
    Source::Point(PointCharge {
      position: [0.7, 0.0, 0.0],
      charge: -1.0,
    }),
  ];
  request.field.softening = 0.0;
  request.seeds = vec![Seeds::Points {
    points: vec![[-0.55, 0.2]],
  }];
  // For axial point sources, sum(q*cos(theta)) is constant along a field line.
  let flux = |p: [f64; 2]| (p[0] + 0.7) / (p[0] + 0.7).hypot(p[1]) - (p[0] - 0.7) / (p[0] - 0.7).hypot(p[1]);
  let initial = flux([-0.55, 0.2]);
  let deviation = |lines: Vec<Vec<[f64; 2]>>| {
    lines[0]
      .iter()
      .map(|&p| (flux(p) - initial).abs())
      .fold(0.0_f64, f64::max)
  };
  request.tracing.step = 0.04;
  let coarse = deviation(field_lines::trace(&request).unwrap());
  request.tracing.step = 0.02;
  let fine = deviation(field_lines::trace(&request).unwrap());
  assert!(
    fine < coarse / 4.0,
    "coarse flux error {coarse}, fine flux error {fine}"
  );
  assert!(fine < 1e-4, "coarse flux error {coarse}, fine flux error {fine}");
}

#[test]
fn nonplanar_fields_require_explicit_projection() {
  let mut request = request(1.0);
  request.sources = vec![Source::Point(PointCharge {
    position: [0.0, 0.0, 1.0],
    charge: 1.0,
  })];
  assert!(field_lines::trace(&request).is_err());
  request.tracing.mode = Mode::Projected;
  assert!(field_lines::trace(&request).unwrap()[0].len() > 1);
}

#[test]
fn zero_field_produces_no_spurious_curve() {
  let request = request(0.0);
  assert_eq!(field_lines::trace(&request).unwrap(), vec![vec![[0.3, 0.1]]]);
}

#[test]
fn zero_charge_geometry_does_not_terminate_a_nonzero_field_line() {
  let mut request = request(1.0);
  request.sources.push(Source::Point(PointCharge {
    position: [0.3, 0.1, 0.0],
    charge: 0.0,
  }));
  assert!(field_lines::trace(&request).unwrap()[0].len() > 10);
}

#[test]
fn seed_generators_and_svg_rendering_preserve_independent_configuration() {
  let mut request = request(1.0);
  request.seeds = vec![Seeds::Circle {
    center: [0.0; 2],
    radius: 0.2,
    count: 8,
    phase: 0.0,
  }];
  assert_eq!(field_lines::trace(&request).unwrap().len(), 8);
  let svg = String::from_utf8(field_lines::render(&request).unwrap()).unwrap();
  assert!(svg.contains("<path") && svg.contains("<polygon") && svg.contains("#123456"));
  request.style.arrow_spacing = None;
  assert!(!String::from_utf8(field_lines::render(&request).unwrap())
    .unwrap()
    .contains("<polygon"));
  request.seeds = vec![Seeds::Points {
    points: vec![[100.0, 0.0]],
  }];
  assert!(field_lines::trace(&request).is_err());
}
