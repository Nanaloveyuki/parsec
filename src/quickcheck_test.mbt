// These properties exercise the parser control-flow contract with small,
// deliberately biased token inputs. The raw Int arrays keep the standard
// shrinker while alphabetize concentrates cases on matching, mismatch, and
// end-of-input branches.

///|
fn alphabetize(raw : Array[Int]) -> Array[Char] {
  raw.map(value => {
    match value & 3 {
      0 => 'a'
      1 => 'b'
      2 => 'c'
      _ => 'x'
    }
  })
}

///|
fn leading_a(input : Array[Char]) -> Int {
  for index = 0, count = 0; index < input.length() && input[index] == 'a'; {
    continue index + 1, count + 1
  } nobreak {
    count
  }
}

///|
fn run_success_matches(
  result : Result[(Array[Char], State[Char]), ParseError],
  expected : Array[Char],
  expected_offset : Int,
) -> Bool {
  match result {
    Ok((values, state)) =>
      values == expected && state.offset() == expected_offset
    Err(_) => false
  }
}

///|
fn run_failure_matches(
  result : Result[(Array[Char], State[Char]), ParseError],
  expected_offset : Int,
) -> Bool {
  match result {
    Err(error) => error.offset() == expected_offset
    Ok(_) => false
  }
}

///|
fn[A] parse_failure_matches(
  result : Result[A, ParseError],
  expected_offset : Int,
) -> Bool {
  match result {
    Err(error) => error.offset() == expected_offset
    Ok(_) => false
  }
}

///|
fn sep_by_model(
  input : Array[Char],
  require_first : Bool,
) -> (Bool, Array[Char], Int) {
  let values : Array[Char] = []
  if input.length() == 0 || input[0] != 'a' {
    if require_first {
      return (false, values, 0)
    }
    return (true, values, 0)
  }
  values.push('a')
  let mut offset = 1
  while offset < input.length() && input[offset] == ',' {
    offset = offset + 1
    if offset == input.length() || input[offset] != 'a' {
      return (false, values, offset)
    }
    values.push('a')
    offset = offset + 1
  }
  (true, values, offset)
}

///|
fn separated_run_matches(
  result : Result[(Array[Char], State[Char]), ParseError],
  model : (Bool, Array[Char], Int),
) -> Bool {
  let (succeeds, values, offset) = model
  match (succeeds, result) {
    (true, Ok((actual, state))) => actual == values && state.offset() == offset
    (false, Err(error)) => error.offset() == offset
    _ => false
  }
}

///|
test "quickcheck: parse_all matches the single-token model" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = alphabetize(raw)
      let parser = Parser::token('b', expected="b")
      match parser.parse_all(input) {
        Ok(value) => input.length() == 1 && input[0] == 'b' && value == 'b'
        Err(error) => {
          let expected_offset = if input.length() > 0 && input[0] == 'b' {
            1
          } else {
            0
          }
          error.offset() == expected_offset
        }
      }
    },
    count=250,
    max_size=64,
    max_shrinks=100,
    seed=2026082501,
  )
}

///|
test "quickcheck: flat_map uses the parsed token and preserves its offset" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = alphabetize(raw)
      let parser = Parser::item().flat_map(expected => {
        Parser::token(expected, expected="repeated token")
      })
      match parser.parse(input) {
        Ok(value) =>
          input.length() >= 2 && input[0] == input[1] && value == input[1]
        Err(error) => {
          let expected_offset = if input.length() == 0 { 0 } else { 1 }
          error.offset() == expected_offset
        }
      }
    },
    count=250,
    max_size=64,
    max_shrinks=100,
    seed=2026082502,
  )
}

///|
test "quickcheck: many agrees with the leading-token model" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = alphabetize(raw)
      let count = leading_a(input)
      let parser = Parser::token('a', expected="a").many()
      let expected = Array::makei(count, _ => 'a')
      let prefix_ok = run_success_matches(
        parser.run(State::new(input)),
        expected,
        count,
      )
      let complete_ok = if count == input.length() {
        match parser.parse_all(input) {
          Ok(values) => values == expected
          Err(_) => false
        }
      } else {
        parse_failure_matches(parser.parse_all(input), count)
      }
      prefix_ok && complete_ok
    },
    count=250,
    max_size=80,
    max_shrinks=100,
    seed=2026082503,
  )
}

///|
test "quickcheck: bounded repetition agrees with a bounded prefix model" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let tokens = alphabetize(input.0)
      let limit = input.1 & 15
      let prefix = leading_a(tokens)
      let count = if prefix < limit { prefix } else { limit }
      let parser = Parser::token('a', expected="a").repeat_0_to_n(limit)
      run_success_matches(
        parser.run(State::new(tokens)),
        Array::makei(count, _ => 'a'),
        count,
      )
    },
    count=250,
    max_size=80,
    max_shrinks=100,
    seed=2026082504,
  )
}

///|
test "quickcheck: exact repetition rejects the first missing token" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let tokens = alphabetize(input.0)
      let requested = (input.1 & 7) - 2
      let prefix = leading_a(tokens)
      let parser = Parser::token('a', expected="a").count(requested)
      if requested <= 0 || prefix >= requested {
        run_success_matches(
          parser.run(State::new(tokens)),
          Array::makei(if requested > 0 { requested } else { 0 }, _ => 'a'),
          if requested > 0 {
            requested
          } else {
            0
          },
        )
      } else {
        run_failure_matches(parser.run(State::new(tokens)), prefix)
      }
    },
    count=250,
    max_size=80,
    max_shrinks=100,
    seed=2026082505,
  )
}

///|
test "quickcheck: separated repetition matches an independent scanner" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = raw.map(value => {
        match value & 3 {
          0 => 'a'
          1 => ','
          2 => 'b'
          _ => 'x'
        }
      })
      let value = Parser::token('a', expected="value")
      let separator = Parser::token(',', expected="separator")
      let zero_or_more = value.sep_by(separator)
      let one_or_more = value.sep_by1(separator)
      separated_run_matches(
        zero_or_more.run(State::new(input)),
        sep_by_model(input, false),
      ) &&
      separated_run_matches(
        one_or_more.run(State::new(input)),
        sep_by_model(input, true),
      )
    },
    count=300,
    max_size=72,
    max_shrinks=100,
    seed=2026082506,
  )
}

///|
test "quickcheck: choice keeps the furthest retryable failure" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = alphabetize(raw)
      let pair = Parser::token('a', expected="a").then_right(
        Parser::token('b', expected="b"),
      )
      let parser = Parser::choice([
        pair.attempt(),
        Parser::token('x', expected="x"),
      ])
      match parser.parse(input) {
        Ok(value) =>
          if input.length() > 0 && input[0] == 'x' {
            value == 'x'
          } else {
            input.length() >= 2 &&
            input[0] == 'a' &&
            input[1] == 'b' &&
            value == 'b'
          }
        Err(Expected(label~, offset~)) =>
          input.length() > 0 &&
          input[0] == 'a' &&
          (input.length() == 1 || input[1] != 'b') &&
          label == "b" &&
          offset == 1
        Err(ExpectedAny(labels~, offset~)) =>
          (input.length() == 0 || (input[0] != 'a' && input[0] != 'x')) &&
          labels == ["a", "x"] &&
          offset == 0
        Err(_) => false
      }
    },
    count=300,
    max_size=72,
    max_shrinks=100,
    seed=2026082507,
  )
}

///|
test "quickcheck: lookahead and negative lookahead preserve the caller state" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let input = alphabetize(raw)
      let positive = Parser::token('a', expected="a")
        .look_ahead()
        .then_right(Parser::position())
      let negative = Parser::token('a', expected="a")
        .not_followed_by(expected="a")
        .then_right(Parser::item())
      let positive_ok = match positive.parse(input) {
        Ok(offset) => input.length() > 0 && input[0] == 'a' && offset == 0
        Err(error) =>
          input.length() == 0 || (input[0] != 'a' && error.offset() == 0)
      }
      let negative_ok = match negative.parse(input) {
        Ok(value) => input.length() > 0 && input[0] != 'a' && value == input[0]
        Err(error) =>
          error.offset() == 0 && (input.length() == 0 || input[0] == 'a')
      }
      positive_ok && negative_ok
    },
    count=250,
    max_size=64,
    max_shrinks=100,
    seed=2026082508,
  )
}
