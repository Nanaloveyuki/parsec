///|
pub fn[T, A] Parser::or_else(
  self : Parser[T, A],
  fallback : Parser[T, A],
) -> Parser[T, A] {
  {
    execute: state => {
      match (self.execute)(state) {
        Failure(_, false, false) => (fallback.execute)(state)
        result => result
      }
    },
  }
}

///|
pub fn[T, A] Parser::attempt(self : Parser[T, A]) -> Parser[T, A] {
  {
    execute: state => {
      match (self.execute)(state) {
        Failure(error, _, _) => Failure(error, false, false)
        result => result
      }
    },
  }
}

///|
pub fn[T] Parser::cut() -> Parser[T, Unit] {
  { execute: state => Success((), state, false, true) }
}

///|
pub fn[T, A] Parser::label(self : Parser[T, A], label : String) -> Parser[T, A] {
  {
    execute: state => {
      match (self.execute)(state) {
        Failure(_, false, false) =>
          Failure(Expected(label~, offset=state.offset()), false, false)
        result => result
      }
    },
  }
}

///|
pub fn[T, A] Parser::context(
  self : Parser[T, A],
  label : String,
) -> Parser[T, A] {
  {
    execute: state => {
      match (self.execute)(state) {
        Failure(error, consumed, committed) =>
          Failure(Context(label~, cause=error), consumed, committed)
        result => result
      }
    },
  }
}

///|
pub fn[T, A] Parser::choice(parsers : Array[Parser[T, A]]) -> Parser[T, A] {
  {
    execute: state => {
      for index = 0, last_error = EmptyChoice(offset=state.offset()); index <
         parsers.length(); {
        match (parsers[index].execute)(state) {
          Failure(error, false, false) => continue index + 1, error
          result => break result
        }
      } nobreak {
        Failure(last_error, false, false)
      }
    },
  }
}
