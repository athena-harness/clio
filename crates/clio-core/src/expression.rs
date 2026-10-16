//! Bounded scalar expressions with forward derivatives for parametric geometry.

use crate::{require, Error};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// A constant or a mathematical expression evaluated by the Rust backend.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum Expression {
  /// A finite numerical constant.
  Constant(f64),
  /// Arithmetic in the model parameters and named constants.
  Formula(String),
}

#[derive(Clone, Copy, Default)]
pub(crate) struct Dual {
  pub value: f64,
  pub gradient: [f64; 3],
}

impl Dual {
  fn constant(value: f64) -> Self {
    Self {
      value,
      gradient: [0.0; 3],
    }
  }

  fn chain(self, value: f64, derivative: f64) -> Self {
    Self {
      value,
      // A constant subexpression has zero derivative even at sqrt(0).
      gradient: self.gradient.map(|d| if d == 0.0 { 0.0 } else { d * derivative }),
    }
  }
}

#[derive(Clone, Copy)]
enum Function {
  Sin,
  Cos,
  Tan,
  Sqrt,
  Exp,
  Ln,
  Abs,
  Sinh,
  Cosh,
  Atan,
}

impl Function {
  fn apply(self, x: Dual) -> Dual {
    let v = x.value;
    match self {
      Self::Sin => x.chain(v.sin(), v.cos()),
      Self::Cos => x.chain(v.cos(), -v.sin()),
      Self::Tan => x.chain(v.tan(), 1.0 / v.cos().powi(2)),
      Self::Sqrt => x.chain(v.sqrt(), 0.5 / v.sqrt()),
      Self::Exp => x.chain(v.exp(), v.exp()),
      Self::Ln => x.chain(v.ln(), 1.0 / v),
      Self::Abs => x.chain(v.abs(), if v == 0.0 { f64::NAN } else { v.signum() }),
      Self::Sinh => x.chain(v.sinh(), v.cosh()),
      Self::Cosh => x.chain(v.cosh(), v.sinh()),
      Self::Atan => x.chain(v.atan(), 1.0 / (1.0 + v * v)),
    }
  }
}

#[derive(Clone, Copy)]
enum Op {
  Constant(f64),
  Parameter(usize),
  Negate,
  Function(Function),
  Binary(u8),
}

pub(crate) struct Compiled {
  code: Vec<Op>,
}

impl Compiled {
  pub fn new(expression: &Expression, names: &[&str], constants: &BTreeMap<String, f64>) -> Result<Self, Error> {
    let code = match expression {
      Expression::Constant(value) => {
        require(value.is_finite(), "expression constants must be finite")?;
        vec![Op::Constant(*value)]
      }
      Expression::Formula(formula) => {
        require(formula.len() <= 4096, "expressions must not exceed 4096 bytes")?;
        let mut parser = Parser {
          input: formula.as_bytes(),
          offset: 0,
          code: Vec::new(),
          names,
          constants,
        };
        parser.expression(0, 0)?;
        parser.space();
        require(
          parser.offset == parser.input.len(),
          "unexpected trailing expression input",
        )?;
        parser.code
      }
    };
    Ok(Self { code })
  }

  pub fn cost(&self) -> usize {
    self.code.len()
  }

  pub fn at(&self, parameters: [f64; 3]) -> Result<Dual, Error> {
    let mut stack = [Dual::default(); 256];
    let mut length = 0;
    for op in &self.code {
      let value = match *op {
        Op::Constant(value) => Dual::constant(value),
        Op::Parameter(axis) => {
          let mut value = Dual::constant(parameters[axis]);
          value.gradient[axis] = 1.0;
          value
        }
        Op::Negate => {
          length -= 1;
          let x = stack[length];
          x.chain(-x.value, -1.0)
        }
        Op::Function(function) => {
          length -= 1;
          function.apply(stack[length])
        }
        Op::Binary(operator) => {
          length -= 2;
          let (a, b) = (stack[length], stack[length + 1]);
          match operator {
            b'+' => Dual {
              value: a.value + b.value,
              gradient: std::array::from_fn(|i| a.gradient[i] + b.gradient[i]),
            },
            b'-' => Dual {
              value: a.value - b.value,
              gradient: std::array::from_fn(|i| a.gradient[i] - b.gradient[i]),
            },
            b'*' => Dual {
              value: a.value * b.value,
              gradient: std::array::from_fn(|i| a.gradient[i] * b.value + a.value * b.gradient[i]),
            },
            b'/' => Dual {
              value: a.value / b.value,
              gradient: std::array::from_fn(|i| (a.gradient[i] - a.value / b.value * b.gradient[i]) / b.value),
            },
            b'^' => {
              let value = a.value.powf(b.value);
              if b.gradient == [0.0; 3] {
                let derivative = if b.value == 0.0 {
                  0.0
                } else {
                  b.value * a.value.powf(b.value - 1.0)
                };
                a.chain(value, derivative)
              } else {
                Dual {
                  value,
                  gradient: std::array::from_fn(|i| {
                    value * (b.gradient[i] * a.value.ln() + b.value * a.gradient[i] / a.value)
                  }),
                }
              }
            }
            _ => return Err(Error::Invalid("unsupported expression operator".into())),
          }
        }
      };
      require(
        value.value.is_finite(),
        "expression is undefined or non-finite at a sampled parameter",
      )?;
      stack[length] = value;
      length += 1;
    }
    Ok(stack[0])
  }
}

struct Parser<'a> {
  input: &'a [u8],
  offset: usize,
  code: Vec<Op>,
  names: &'a [&'a str],
  constants: &'a BTreeMap<String, f64>,
}

impl Parser<'_> {
  fn space(&mut self) {
    while self.input.get(self.offset).is_some_and(u8::is_ascii_whitespace) {
      self.offset += 1;
    }
  }

  fn take(&mut self, token: u8) -> bool {
    self.space();
    if self.input.get(self.offset) == Some(&token) {
      self.offset += 1;
      true
    } else {
      false
    }
  }

  fn push(&mut self, op: Op) -> Result<(), Error> {
    require(self.code.len() < 256, "expressions must not exceed 256 instructions")?;
    self.code.push(op);
    Ok(())
  }

  fn expression(&mut self, minimum: u8, depth: usize) -> Result<(), Error> {
    require(depth < 32, "expression nesting must be less than 32")?;
    self.space();
    if self.take(b'-') {
      self.expression(5, depth + 1)?;
      self.push(Op::Negate)?;
    } else if self.take(b'+') {
      self.expression(5, depth + 1)?;
    } else if self.take(b'(') {
      self.expression(0, depth + 1)?;
      require(self.take(b')'), "missing closing expression parenthesis")?;
    } else if self
      .input
      .get(self.offset)
      .is_some_and(|b| b.is_ascii_digit() || *b == b'.')
    {
      let start = self.offset;
      while self
        .input
        .get(self.offset)
        .is_some_and(|b| b.is_ascii_digit() || *b == b'.')
      {
        self.offset += 1;
      }
      if self.input.get(self.offset).is_some_and(|b| *b == b'e' || *b == b'E') {
        self.offset += 1;
        if self.input.get(self.offset).is_some_and(|b| *b == b'+' || *b == b'-') {
          self.offset += 1;
        }
        while self.input.get(self.offset).is_some_and(u8::is_ascii_digit) {
          self.offset += 1;
        }
      }
      let value = std::str::from_utf8(&self.input[start..self.offset])
        .ok()
        .and_then(|s| s.parse::<f64>().ok())
        .ok_or_else(|| Error::Invalid("invalid expression number".into()))?;
      require(value.is_finite(), "expression numbers must be finite")?;
      self.push(Op::Constant(value))?;
    } else {
      let start = self.offset;
      while self
        .input
        .get(self.offset)
        .is_some_and(|b| b.is_ascii_alphanumeric() || *b == b'_')
      {
        self.offset += 1;
      }
      require(self.offset > start, "expected a number, parameter, or function")?;
      let name = std::str::from_utf8(&self.input[start..self.offset])
        .map_err(|_| Error::Invalid("expression identifiers must be ASCII".into()))?;
      if self.take(b'(') {
        let function = match name {
          "sin" => Function::Sin,
          "cos" => Function::Cos,
          "tan" => Function::Tan,
          "sqrt" => Function::Sqrt,
          "exp" => Function::Exp,
          "ln" => Function::Ln,
          "abs" => Function::Abs,
          "sinh" => Function::Sinh,
          "cosh" => Function::Cosh,
          "atan" => Function::Atan,
          _ => return Err(Error::Invalid(format!("unknown expression function: {name}"))),
        };
        self.expression(0, depth + 1)?;
        require(self.take(b')'), "missing closing function parenthesis")?;
        self.push(Op::Function(function))?;
      } else if let Some(axis) = self.names.iter().position(|variable| *variable == name) {
        self.push(Op::Parameter(axis))?;
      } else {
        let value = match name {
          "pi" => Some(std::f64::consts::PI),
          "e" => Some(std::f64::consts::E),
          _ => self.constants.get(name).copied(),
        }
        .ok_or_else(|| Error::Invalid(format!("unknown expression variable: {name}")))?;
        self.push(Op::Constant(value))?;
      }
    }
    loop {
      self.space();
      let Some(&operator) = self.input.get(self.offset) else {
        break;
      };
      let (left, right) = match operator {
        b'+' | b'-' => (1, 2),
        b'*' | b'/' => (3, 4),
        b'^' => (6, 5),
        _ => break,
      };
      if left < minimum {
        break;
      }
      self.offset += 1;
      self.expression(right, depth + 1)?;
      self.push(Op::Binary(operator))?;
    }
    Ok(())
  }
}
