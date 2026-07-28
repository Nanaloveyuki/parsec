///|
pub fn[T, A] Parser::run(
  self : Parser[T, A],
  state : State[T],
) -> Result[(A, State[T]), ParseError] {
  (self.execute)(state).to_result()
}

///|
pub fn[T, A] Parser::parse(
  self : Parser[T, A],
  stream : Stream[T],
) -> Result[A, ParseError] {
  match (self.execute)(State::new(stream)) {
    Success(value, _, _, _) => Ok(value)
    Failure(error, _, _) => Err(error)
  }
}

///|
pub fn[T, A] Parser::parse_all(
  self : Parser[T, A],
  stream : Stream[T],
) -> Result[A, ParseError] {
  self.then_left(Parser::eof()).parse(stream)
}

///|
pub fn[T, A] Parser::pure(value : A) -> Parser[T, A] {
  { execute: state => Success(value, state, false, false) }
}

///|
pub fn[T, A] Parser::fail(error : ParseError) -> Parser[T, A] {
  { execute: _ => Failure(error, false, false) }
}

///|
pub fn[T] Parser::item() -> Parser[T, T] {
  {
    execute: state => {
      match state.next() {
        Some((token, next)) => Success(token, next, true, false)
        None => Failure(UnexpectedEnd(offset=state.offset()), false, false)
      }
    },
  }
}

///|
pub fn[T] Parser::satisfy(
  label : String,
  predicate : (T) -> Bool,
) -> Parser[T, T] {
  {
    execute: state => {
      match state.next() {
        Some((token, next)) if predicate(token) =>
          Success(token, next, true, false)
        Some(_) =>
          Failure(Expected(label~, offset=state.offset()), false, false)
        None => Failure(Expected(label~, offset=state.offset()), false, false)
      }
    },
  }
}

///|
pub fn[T : Eq] Parser::token(token : T, expected~ : String) -> Parser[T, T] {
  Parser::satisfy(expected, item => item == token)
}

///|
pub fn[T] Parser::eof() -> Parser[T, Unit] {
  {
    execute: state => {
      match state.next() {
        None => Success((), state, false, false)
        Some(_) =>
          Failure(
            Expected(label="end of input", offset=state.offset()),
            false,
            false,
          )
      }
    },
  }
}

///|
pub fn[T, A] Parser::delay(factory : () -> Parser[T, A]) -> Parser[T, A] {
  { execute: state => (factory().execute)(state) }
}
