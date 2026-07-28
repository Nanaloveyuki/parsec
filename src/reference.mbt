///|
/// A mutable parser slot for recursive grammars assembled in multiple steps.
pub struct ParserRef[T, A] {
  priv target : @ref.Ref[Parser[T, A]?]
}

///|
/// Creates an unbound recursive parser slot.
pub fn[T, A] ParserRef::new() -> ParserRef[T, A] {
  { target: @ref.new(None) }
}

///|
/// Binds subsequent executions of this slot to `parser`.
pub fn[T, A] ParserRef::set(
  self : ParserRef[T, A],
  parser : Parser[T, A],
) -> Unit {
  self.target.val = Some(parser)
}

///|
/// Returns a parser that delegates to the slot's current binding at run time.
pub fn[T, A] ParserRef::parser(self : ParserRef[T, A]) -> Parser[T, A] {
  {
    execute: state => {
      match self.target.val {
        Some(parser) => (parser.execute)(state)
        None => Failure(UnboundReference(offset=state.offset()), false, false)
      }
    },
  }
}
