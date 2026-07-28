///|
pub fn satisfy(
  label : String,
  predicate : (Char) -> Bool,
) -> @parsec.Parser[Char, Char] {
  @parsec.Parser::satisfy(label, predicate)
}

///|
pub fn char(expected : Char) -> @parsec.Parser[Char, Char] {
  @parsec.Parser::token(expected, expected="character")
}

///|
pub fn one_of(
  chars : ArrayView[Char],
  expected~ : String,
) -> @parsec.Parser[Char, Char] {
  satisfy(expected, char => chars.contains(char))
}

///|
pub fn digit() -> @parsec.Parser[Char, Char] {
  satisfy("digit", char => char.is_ascii_digit())
}

///|
pub fn digits() -> @parsec.Parser[Char, String] {
  digit().many1().map(chars => String::from_array(chars[:]))
}

///|
pub fn string(expected : String) -> @parsec.Parser[Char, String] {
  let mut parser : @parsec.Parser[Char, Unit] = @parsec.Parser::pure(())
  for input_char in expected {
    parser = parser.then_right(char(input_char).ignore())
  }
  parser.replace(expected)
}

///|
pub fn whitespace() -> @parsec.Parser[Char, Char] {
  satisfy("whitespace", char => char.is_whitespace())
}

///|
pub fn spaces() -> @parsec.Parser[Char, Unit] {
  whitespace().many().ignore()
}

///|
pub fn letter() -> @parsec.Parser[Char, Char] {
  satisfy("letter", char => char.is_ascii_alphabetic())
}

///|
pub fn alpha_num() -> @parsec.Parser[Char, Char] {
  satisfy("letter or digit", char => {
    char.is_ascii_alphabetic() || char.is_ascii_digit()
  })
}

///|
pub fn identifier() -> @parsec.Parser[Char, String] {
  let identifier_start = letter().or_else(char('_'))
  let identifier_continue = alpha_num().or_else(char('_'))
  identifier_start
  .then(identifier_continue.many())
  .map(pair => {
    let chars = [pair.0]
    for char in pair.1 {
      chars.push(char)
    }
    String::from_array(chars[:])
  })
  .label("identifier")
}

///|
fn decimal_value(chars : Array[Char]) -> Int {
  let mut value = 0
  for char in chars {
    value = value * 10 + char.to_int() - '0'.to_int()
  }
  value
}

///|
pub fn integer() -> @parsec.Parser[Char, Int] {
  let sign = char('-')
    .replace(-1)
    .or_else(char('+').replace(1))
    .or_else(@parsec.Parser::pure(1))
  sign
  .then(digits())
  .map(pair => pair.0 * decimal_value(pair.1.to_array()))
  .label("integer")
}

///|
pub fn symbol(value : String) -> @parsec.Parser[Char, String] {
  string(value).then_left(spaces())
}
