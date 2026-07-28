///|
fn[T, A] count_impl(
  parser : Parser[T, A],
  remaining : Int,
) -> Parser[T, Array[A]] {
  if remaining <= 0 {
    Parser::pure([])
  } else {
    parser.flat_map(first => {
      count_impl(parser, remaining - 1).map(rest => {
        let values = [first]
        for value in rest {
          values.push(value)
        }
        values
      })
    })
  }
}

///|
/// Parses exactly `count` occurrences. Non-positive counts succeed with no
/// values and consume no input.
pub fn[T, A] Parser::count(
  self : Parser[T, A],
  count : Int,
) -> Parser[T, Array[A]] {
  count_impl(self, count)
}

///|
fn[T, A] repeat_0_to_n_impl(
  parser : Parser[T, A],
  remaining : Int,
) -> Parser[T, Array[A]] {
  if remaining <= 0 {
    Parser::pure([])
  } else {
    parser
    .flat_map(first => {
      repeat_0_to_n_impl(parser, remaining - 1).map(rest => {
        let values = [first]
        for value in rest {
          values.push(value)
        }
        values
      })
    })
    .or_else(Parser::pure([]))
  }
}

///|
/// Parses at most `max_count` occurrences. It stops at an unconsumed failure.
/// Non-positive bounds succeed with no values and consume no input.
pub fn[T, A] Parser::repeat_0_to_n(
  self : Parser[T, A],
  max_count : Int,
) -> Parser[T, Array[A]] {
  repeat_0_to_n_impl(self, max_count)
}
