///|
test "source maps character offsets to one-based line and column" {
  let source = Source::new("a\nbc")
  inspect(source.length(), content="4")
  inspect(source.line_count(), content="2")
  match source.position_at(3) {
    Some(position) => {
      inspect(position.offset(), content="3")
      inspect(position.line(), content="2")
      inspect(position.column(), content="2")
    }
    None => fail("expected a valid source position")
  }
}

///|
test "spans are end-exclusive source ranges" {
  let source = Source::new("a\nbc")
  match source.span(2, 4) {
    Some(span) => {
      inspect(span.length(), content="2")
      inspect(span.start().line(), content="2")
      inspect(span.start().column(), content="1")
      inspect(span.end().line(), content="2")
      inspect(span.end().column(), content="3")
      let token = Located::new("bc", span).map(value => value.length())
      inspect(token.value(), content="2")
    }
    None => fail("expected a valid span")
  }
}

///|
test "source maps root parse errors back to positions" {
  let source = Source::new("ac")
  let parser = @parsec.Parser::token('a', expected="a").then_right(
    @parsec.Parser::token('b', expected="b"),
  )
  match parser.parse(['a', 'c']) {
    Err(error) =>
      match source.error_position(error) {
        Some(position) => {
          inspect(position.line(), content="1")
          inspect(position.column(), content="2")
        }
        None => fail("expected the parser offset to map to source")
      }
    Ok(_) => fail("expected a parse error")
  }
}
