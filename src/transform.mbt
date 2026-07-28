///|
pub fn[T, A, B] Parser::map(
  self : Parser[T, A],
  transform : (A) -> B,
) -> Parser[T, B] {
  {
    execute: state => {
      match (self.execute)(state) {
        Success(value, next, consumed, committed) =>
          Success(transform(value), next, consumed, committed)
        Failure(error, consumed, committed) =>
          Failure(error, consumed, committed)
      }
    },
  }
}

///|
pub fn[T, A, B] Parser::flat_map(
  self : Parser[T, A],
  next : (A) -> Parser[T, B],
) -> Parser[T, B] {
  {
    execute: state => {
      match (self.execute)(state) {
        Success(value, next_state, consumed, committed) => {
          let parser = next(value)
          (parser.execute)(next_state).with_prefix(consumed, committed)
        }
        Failure(error, consumed, committed) =>
          Failure(error, consumed, committed)
      }
    },
  }
}

///|
pub fn[T, A, B] Parser::and_then(
  self : Parser[T, A],
  next : (A) -> Parser[T, B],
) -> Parser[T, B] {
  self.flat_map(next)
}

///|
pub fn[T, A, B] Parser::then(
  self : Parser[T, A],
  next : Parser[T, B],
) -> Parser[T, (A, B)] {
  self.flat_map(left => next.map(right => (left, right)))
}

///|
pub fn[T, A, B] Parser::then_right(
  self : Parser[T, A],
  next : Parser[T, B],
) -> Parser[T, B] {
  self.then(next).map(pair => pair.1)
}

///|
pub fn[T, A, B] Parser::then_left(
  self : Parser[T, A],
  next : Parser[T, B],
) -> Parser[T, A] {
  self.then(next).map(pair => pair.0)
}

///|
pub fn[T, A, B] Parser::replace(self : Parser[T, A], value : B) -> Parser[T, B] {
  self.map(_ => value)
}

///|
pub fn[T, A] Parser::ignore(self : Parser[T, A]) -> Parser[T, Unit] {
  self.replace(())
}
