///|
/// Parses one or more values separated by `separator`.
pub fn[T, A, S] Parser::sep_by1(
  self : Parser[T, A],
  separator : Parser[T, S],
) -> Parser[T, Array[A]] {
  self.flat_map(first => {
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
}
