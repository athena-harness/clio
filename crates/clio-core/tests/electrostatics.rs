use clio_core::{
  electrostatics::{
    continuous_charge::{Annulus, PlaneWithHole, Segment},
    point_charges::PointCharge,
    ElectricField, FieldOptions, Source,
  },
  geometry::Plane,
};

fn evaluate(source: Source, position: [f64; 3], softening: f64) -> [f64; 3] {
  ElectricField::new(
    &[source],
    FieldOptions {
      coulomb_constant: 1.0,
      softening,
    },
  )
  .unwrap()
  .at(position)
  .unwrap()
  .unwrap()
}

fn disk(radial_samples: u32) -> Annulus {
  Annulus {
    plane: Plane::default(),
    inner_radius: 0.0,
    outer_radius: 0.7,
    density: 1.0,
    radial_samples,
    angular_samples: 32,
  }
}

#[test]
fn point_charge_obeys_inverse_square_and_signed_direction() {
  let field = evaluate(
    Source::Point(PointCharge {
      position: [0.0; 3],
      charge: -2.0,
    }),
    [0.0, 0.0, 2.0],
    0.0,
  );
  assert_eq!(field, [0.0, 0.0, -0.5]);
}

#[test]
fn superposition_cancels_vectors_before_taking_magnitude() {
  let field = ElectricField::new(
    &[
      Source::Point(PointCharge {
        position: [-1.0, 0.0, 0.0],
        charge: 1.0,
      }),
      Source::Point(PointCharge {
        position: [1.0, 0.0, 0.0],
        charge: 1.0,
      }),
    ],
    FieldOptions {
      coulomb_constant: 1.0,
      softening: 0.0,
    },
  )
  .unwrap();
  assert_eq!(field.at([0.0; 3]).unwrap(), Some([0.0; 3]));
}

#[test]
fn disk_midpoint_quadrature_converges_to_analytic_axis_field() {
  let z: f64 = 0.8;
  let expected = std::f64::consts::TAU * (1.0 - z / z.hypot(0.7));
  let coarse = evaluate(Source::Annulus(disk(8)), [0.0, 0.0, z], 0.0)[2];
  let fine = evaluate(Source::Annulus(disk(128)), [0.0, 0.0, z], 0.0)[2];
  assert!((fine - expected).abs() < (coarse - expected).abs() / 100.0);
  assert!((fine - expected).abs() < 2e-5);
}

#[test]
fn annulus_matches_the_difference_of_two_axis_disk_fields() {
  let mut annulus = disk(128);
  annulus.inner_radius = 0.3;
  let z: f64 = -0.8;
  let expected = std::f64::consts::TAU * z * (1.0 / z.hypot(0.3) - 1.0 / z.hypot(0.7));
  let field = evaluate(Source::Annulus(annulus), [0.0, 0.0, z], 0.0);
  assert!((field[2] - expected).abs() < 1e-5);
}

#[test]
fn plane_with_hole_matches_softened_analytic_axis_field() {
  let source = PlaneWithHole {
    plane: Plane::default(),
    hole_radius: 0.7,
    density: -1.5,
    radial_samples: 128,
    angular_samples: 32,
  };
  let z: f64 = 0.8;
  let epsilon: f64 = 0.2;
  let expected = std::f64::consts::TAU * (-1.5) * z / z.hypot(epsilon).hypot(0.7);
  let field = evaluate(Source::PlaneWithHole(source), [0.0, 0.0, z], epsilon);
  assert!((field[2] - expected).abs() < 3e-5);
}

#[test]
fn line_segment_matches_analytic_perpendicular_bisector_field() {
  let source = Segment {
    start: [-1.0, 0.0, 0.0],
    end: [1.0, 0.0, 0.0],
    density: 2.0,
    samples: 256,
  };
  let field = evaluate(Source::Segment(source), [0.0, 1.0, 0.0], 0.0);
  assert!((field[1] - 4.0 / 2.0_f64.sqrt()).abs() < 1e-5);
}

#[test]
fn rotation_preserves_disk_field_and_coulomb_scaling() {
  let mut source = disk(128);
  source.plane = Plane {
    origin: [2.0, 3.0, 4.0],
    horizontal: [0.0, 1.0, 0.0],
    vertical: [0.0, 0.0, 1.0],
  };
  let expected = std::f64::consts::TAU * (1.0 - 0.8 / 0.8_f64.hypot(0.7));
  let field = ElectricField::new(
    &[Source::Annulus(source)],
    FieldOptions {
      coulomb_constant: 3.0,
      softening: 0.0,
    },
  )
  .unwrap()
  .at([2.8, 3.0, 4.0])
  .unwrap()
  .unwrap();
  assert!((field[0] - 3.0 * expected).abs() < 6e-5);
  assert!(field[1].abs() < 1e-12 && field[2].abs() < 1e-12);
}

#[test]
fn exact_point_singularity_is_missing_while_softening_remains_finite() {
  let source = Source::Point(PointCharge {
    position: [0.0; 3],
    charge: 1.0,
  });
  let exact = ElectricField::new(
    std::slice::from_ref(&source),
    FieldOptions {
      coulomb_constant: 1.0,
      softening: 0.0,
    },
  )
  .unwrap();
  assert_eq!(exact.at([0.0; 3]).unwrap(), None);
  assert_eq!(evaluate(source, [0.0; 3], 0.02), [0.0; 3]);
}

#[test]
fn uncharged_hole_interior_converges_without_virtual_source_singularities() {
  let source = PlaneWithHole {
    plane: Plane::default(),
    hole_radius: 0.7,
    density: 1.0,
    radial_samples: 32,
    angular_samples: 32,
  };
  let coarse = evaluate(Source::PlaneWithHole(source.clone()), [0.2, 0.1, 0.0], 0.0);
  let fine = evaluate(
    Source::PlaneWithHole(PlaneWithHole {
      radial_samples: 128,
      angular_samples: 64,
      ..source
    }),
    [0.2, 0.1, 0.0],
    0.0,
  );
  assert!((coarse[0] - fine[0]).abs() < 1e-4 && (coarse[1] - fine[1]).abs() < 1e-4);
  assert_eq!(fine[2], 0.0);
}
