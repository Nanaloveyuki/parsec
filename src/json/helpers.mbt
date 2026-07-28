///|
let depth_limit_label = "JSON nesting depth limit"

///|
let string_limit_label = "JSON string character limit"

///|
let array_limit_label = "JSON array item limit"

///|
let object_limit_label = "JSON object member limit"

///|
fn join(parts : Array[String]) -> String {
  let chars = []
  for part in parts {
    for char in part {
      chars.push(char)
    }
  }
  String::from_array(chars[:])
}

///|
fn raw_char(character : Char, expected~ : String) -> @parsec.Parser[Char, Char] {
  @parsec.Parser::token(character, expected~)
}

///|
fn json_whitespace() -> @parsec.Parser[Char, Unit] {
  @parsec.Parser::satisfy("JSON whitespace", char => {
    char == ' ' || char == '\t' || char == '\n' || char == '\r'
  })
  .many()
  .ignore()
}

///|
fn token(character : Char, expected~ : String) -> @parsec.Parser[Char, Char] {
  raw_char(character, expected~).then_left(json_whitespace())
}

///|
fn text(value : String, expected~ : String) -> @parsec.Parser[Char, Unit] {
  let mut parser : @parsec.Parser[Char, Unit] = @parsec.Parser::pure(())
  for character in value {
    parser = parser.then_right(raw_char(character, expected~).ignore())
  }
  parser.then_left(json_whitespace())
}

///|
fn[T, A] fail_at(label : String) -> @parsec.Parser[T, A] {
  @parsec.Parser::position().flat_map(offset => {
    @parsec.Parser::fail(Expected(label~, offset~))
  })
}

///|
fn hex_digit() -> @parsec.Parser[Char, Int] {
  @parsec.Parser::satisfy("hexadecimal digit", char => {
    (char >= '0' && char <= '9') ||
    (char >= 'a' && char <= 'f') ||
    (char >= 'A' && char <= 'F')
  }).map(char => {
    if char >= '0' && char <= '9' {
      char.to_int() - '0'.to_int()
    } else if char >= 'a' && char <= 'f' {
      char.to_int() - 'a'.to_int() + 10
    } else {
      char.to_int() - 'A'.to_int() + 10
    }
  })
}

///|
fn code_unit() -> @parsec.Parser[Char, Int] {
  hex_digit()
  .count(4)
  .map(digits => digits[0] * 4096 + digits[1] * 256 + digits[2] * 16 + digits[3])
}
