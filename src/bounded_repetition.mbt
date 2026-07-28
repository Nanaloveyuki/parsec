///|
fn[T, A] bounded_repeat(
  parser : Parser[T, A],
  max_count : Int,
  stop_on_unconsumed_failure : Bool,
) -> Parser[T, Array[A]] {
  {
    execute: initial => {
      let values = []
      let mut current = initial
      let mut consumed = false
      let mut committed = false
      for index = 0; index < max_count; index = index + 1 {
        match (parser.execute)(current) {
          Success(value, next, child_consumed, child_committed) => {
            values.push(value)
            current = next
            consumed = consumed || child_consumed
            committed = committed || child_committed
          }
          Failure(error, false, false) =>
            if stop_on_unconsumed_failure {
              break Success(values, current, consumed, committed)
            } else {
              break Failure(error, consumed, committed)
            }
          Failure(error, child_consumed, child_committed) =>
            break Failure(
              error,
              consumed || child_consumed,
              committed || child_committed,
            )
        }
      } nobreak {
        Success(values, current, consumed, committed)
      }
    },
  }
}

///|
/// Parses exactly `count` occurrences. Non-positive counts succeed with no
/// values and consume no input.
pub fn[T, A] Parser::count(
  self : Parser[T, A],
  count : Int,
) -> Parser[T, Array[A]] {
  bounded_repeat(self, count, false)
}

///|
/// Parses at most `max_count` occurrences. It stops at an unconsumed failure.
/// Non-positive bounds succeed with no values and consume no input.
pub fn[T, A] Parser::repeat_0_to_n(
  self : Parser[T, A],
  max_count : Int,
) -> Parser[T, Array[A]] {
  bounded_repeat(self, max_count, true)
}
