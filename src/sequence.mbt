///|
/// Runs every parser in order and collects their values.
pub fn[T, A] Parser::sequence(
  parsers : Array[Parser[T, A]],
) -> Parser[T, Array[A]] {
  let mut result : Parser[T, Array[A]] = Parser::pure([])
  for parser in parsers {
    result = result
      .then(parser)
      .map(pair => {
        let values = pair.0.copy()
        values.push(pair.1)
        values
      })
  }
  result
}

///|
/// Combines the successful values of two parsers.
pub fn[T, A, B, C] Parser::lift2(
  left : Parser[T, A],
  right : Parser[T, B],
  combine : (A, B) -> C,
) -> Parser[T, C] {
  left.then(right).map(pair => combine(pair.0, pair.1))
}

///|
/// Applies a parsed function to the value parsed by `argument`.
pub fn[T, A, B] Parser::apply(
  self : Parser[T, (A) -> B],
  argument : Parser[T, A],
) -> Parser[T, B] {
  self.then(argument).map(pair => (pair.0)(pair.1))
}
