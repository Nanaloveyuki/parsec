///|
fn countdown(start : Int) -> Stream[Int] {
  Stream::from_fn(() => {
    if start > 0 {
      Some((start, countdown(start - 1)))
    } else {
      None
    }
  })
}

///|
test "lazy parsers consume complete string streams" {
  let parser = Parser::token('m', expected="m").then_right(
    Parser::token('b', expected="b"),
  )
  match parser.parse_all(Stream::from_string("mb")) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the stream to parse")
  }
}

///|
test "attempt replays a persistent custom stream" {
  let pair = Parser::token(3, expected="three").then_right(
    Parser::token(1, expected="one"),
  )
  let parser = pair.attempt().or_else(Parser::token(3, expected="three"))
  match parser.parse(countdown(3)) {
    Ok(value) => inspect(value, content="3")
    Err(_) => fail("expected the fallback to reread the stream")
  }
}

///|
test "many works with array-backed lazy streams" {
  let parser = Parser::token(1, expected="one").many()
  match parser.parse_all(Stream::from_array([1, 1, 1])) {
    Ok(values) => inspect(values.length(), content="3")
    Err(_) => fail("expected repeated integer tokens")
  }
}

///|
test "cut remains committed after attempt" {
  let parser = Parser::cut()
    .then_right(Parser::token('a', expected="a"))
    .attempt()
    .or_else(Parser::token('b', expected="b"))
  match parser.parse(Stream::from_string("b")) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="a")
      inspect(offset, content="0")
    }
    _ => fail("expected the hard cut to prevent fallback")
  }
}
