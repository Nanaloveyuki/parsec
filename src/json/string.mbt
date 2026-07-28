///|
fn unicode_character(code : Int) -> @parsec.Parser[Char, Char] {
  if code >= 0xD800 && code <= 0xDBFF {
    raw_char('\\', expected="low surrogate escape")
    .then_right(raw_char('u', expected="low surrogate escape"))
    .then_right(code_unit())
    .flat_map(low => {
      if low >= 0xDC00 && low <= 0xDFFF {
        @parsec.Parser::pure(
          (0x10000 + (code - 0xD800) * 1024 + (low - 0xDC00)).unsafe_to_char(),
        )
      } else {
        fail_at("low surrogate")
      }
    })
  } else if code >= 0xDC00 && code <= 0xDFFF {
    fail_at("non-surrogate Unicode escape")
  } else {
    @parsec.Parser::pure(code.unsafe_to_char())
  }
}

///|
fn escaped_character() -> @parsec.Parser[Char, Char] {
  raw_char('\\', expected="escape sequence").then_right(
    @parsec.Parser::choice([
      raw_char('"', expected="escape sequence").replace('"'),
      raw_char('\\', expected="escape sequence").replace('\\'),
      raw_char('/', expected="escape sequence").replace('/'),
      raw_char('b', expected="escape sequence").replace('\b'),
      raw_char('f', expected="escape sequence").replace('\f'),
      raw_char('n', expected="escape sequence").replace('\n'),
      raw_char('r', expected="escape sequence").replace('\r'),
      raw_char('t', expected="escape sequence").replace('\t'),
      raw_char('u', expected="Unicode escape")
      .then_right(code_unit())
      .flat_map(unicode_character),
    ]),
  )
}

///|
fn unescaped_character() -> @parsec.Parser[Char, Char] {
  @parsec.Parser::satisfy("unescaped string character", char => {
    char != '"' && char != '\\' && char.to_int() >= 0x20
  })
}

///|
fn string_character() -> @parsec.Parser[Char, Char] {
  unescaped_character().or_else(escaped_character())
}

///|
fn string(limits : JsonLimits) -> @parsec.Parser[Char, String] {
  raw_char('"', expected="opening quote")
  .then_right(
    string_character()
    .repeat_0_to_n(limits.max_string_chars)
    .then_left(string_character().not_followed_by(expected=string_limit_label))
    .map(chars => String::from_array(chars[:])),
  )
  .then_left(raw_char('"', expected="closing quote"))
  .then_left(json_whitespace())
}
