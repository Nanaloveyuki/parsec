///|
pub fn[T, A] Parser::look_ahead(self : Parser[T, A]) -> Parser[T, A] {
  {
    execute: state => {
      match (self.execute)(state) {
        Success(value, _, _, _) => Success(value, state, false, false)
        Failure(error, _, _) => Failure(error, false, false)
      }
    },
  }
}

///|
pub fn[T, A] Parser::not_followed_by(
  self : Parser[T, A],
  expected~ : String,
) -> Parser[T, Unit] {
  {
    execute: state => {
      match (self.execute)(state) {
        Success(_, _, _, _) =>
          Failure(
            NotFollowedBy(label=expected, offset=state.offset()),
            false,
            false,
          )
        Failure(_, _, _) => Success((), state, false, false)
      }
    },
  }
}
