///|
pub fn[T, A] Parser::optional(self : Parser[T, A]) -> Parser[T, A?] {
  self.map(value => Some(value)).or_else(Parser::pure(None))
}

///|
pub fn[T, A] Parser::many(self : Parser[T, A]) -> Parser[T, Array[A]] {
  {
    execute: initial => {
      let values = []
      for current = initial, consumed = false, committed = false; true; {
        match (self.execute)(current) {
          Success(_, _, false, _) =>
            break Failure(
              EmptyMatchInMany(offset=current.offset()),
              consumed,
              true,
            )
          Success(value, next, child_consumed, child_committed) => {
            values.push(value)
            continue next,
              consumed || child_consumed,
              committed || child_committed
          }
          Failure(_, false, false) =>
            break Success(values, current, consumed, committed)
          Failure(error, child_consumed, child_committed) =>
            break Failure(
              error,
              consumed || child_consumed,
              committed || child_committed,
            )
        }
      } nobreak {
        Failure(EmptyMatchInMany(offset=initial.offset()), false, true)
      }
    },
  }
}

///|
pub fn[T, A] Parser::many1(self : Parser[T, A]) -> Parser[T, Array[A]] {
  self.flat_map(first => {
    self
    .many()
    .map(rest => {
      let values = [first]
      for value in rest {
        values.push(value)
      }
      values
    })
  })
}

///|
pub fn[T, A, S] Parser::sep_by(
  self : Parser[T, A],
  separator : Parser[T, S],
) -> Parser[T, Array[A]] {
  self
  .flat_map(first => {
    separator
    .then_right(self)
    .many()
    .map(rest => {
      let values = [first]
      for value in rest {
        values.push(value)
      }
      values
    })
  })
  .or_else(Parser::pure([]))
}

///|
pub fn[T, Open, A, Close] Parser::between(
  open : Parser[T, Open],
  parser : Parser[T, A],
  close : Parser[T, Close],
) -> Parser[T, A] {
  open.then_right(parser).then_left(close)
}
