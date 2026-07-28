///|
fn digit() -> @parsec.Parser[Char, Char] {
  @parsec.Parser::satisfy("digit", char => char >= '0' && char <= '9')
}

///|
fn digits() -> @parsec.Parser[Char, String] {
  digit().many1().map(chars => String::from_array(chars[:]))
}

///|
fn integer_part() -> @parsec.Parser[Char, String] {
  raw_char('0', expected="JSON integer")
  .replace("0")
  .or_else(
    @parsec.Parser::satisfy("non-zero JSON digit", char => {
      char >= '1' && char <= '9'
    })
    .then(digit().many())
    .map(pair => {
      let chars = [pair.0]
      for char in pair.1 {
        chars.push(char)
      }
      String::from_array(chars[:])
    }),
  )
}

///|
fn number() -> @parsec.Parser[Char, String] {
  let sign = raw_char('-', expected="JSON number").replace("-").option("")
  let fraction = raw_char('.', expected="fraction")
    .then_right(digits())
    .map(value => join([".", value]))
    .option("")
  let exponent_marker = raw_char('e', expected="exponent")
    .or_else(raw_char('E', expected="exponent"))
    .map(character => String::from_array([character]))
  let exponent = exponent_marker
    .then(
      raw_char('+', expected="exponent sign")
      .replace("+")
      .or_else(raw_char('-', expected="exponent sign").replace("-"))
      .option("")
      .then(digits()),
    )
    .map(pair => join([pair.0, pair.1.0, pair.1.1]))
    .option("")
  sign
  .then(integer_part())
  .then(fraction)
  .then(exponent)
  .map(parts => join([parts.0.0.0, parts.0.0.1, parts.0.1, parts.1]))
  .then_left(json_whitespace())
}
