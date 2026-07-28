///|
/// Succeeds without consuming input and returns the current token offset.
pub fn[T] Parser::position() -> Parser[T, Int] {
  { execute: state => Success(state.offset(), state, false, false) }
}
