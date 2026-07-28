///|
fn nested_x() -> Parser[Char, Char] {
  Parser::token('x', expected="x").or_else(
    Parser::between(
      Parser::token('(', expected="opening parenthesis"),
      Parser::delay(() => nested_x()),
      Parser::token(')', expected="closing parenthesis"),
    ),
  )
}

///|
test "sequences matching tokens" {
  let parser = Parser::token('a', expected="a").then_right(
    Parser::token('b', expected="b"),
  )
  match parser.parse_all(['a', 'b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the sequence to parse")
  }
}

///|
test "choice backtracks only before consuming input" {
  let parser = Parser::token('a', expected="a").or_else(
    Parser::token('b', expected="b"),
  )
  match parser.parse_all(['b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the fallback to parse")
  }
}

///|
test "choice does not discard a consumed prefix" {
  let parser = Parser::token('a', expected="a")
    .then_right(Parser::token('b', expected="b"))
    .or_else(Parser::token('a', expected="a"))
  match parser.parse_all(['a', 'c']) {
    Err(error) => inspect(error.offset(), content="1")
    Ok(_) => fail("expected the committed branch to fail")
  }
}

///|
test "attempt allows an explicitly retried consumed prefix" {
  let pair = Parser::token('a', expected="a").then_right(
    Parser::token('b', expected="b"),
  )
  let parser = pair.attempt().or_else(Parser::token('a', expected="a"))
  match parser.parse_all(['a']) {
    Ok(value) => inspect(value, content="a")
    Err(_) => fail("expected attempt to restore the fallback")
  }
}

///|
test "attempt preserves the furthest failed expectation" {
  let pair = Parser::token('a', expected="a").then_right(
    Parser::token('b', expected="b"),
  )
  let parser = pair.attempt().or_else(Parser::token('x', expected="x"))
  match parser.parse(['a', 'c']) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="b")
      inspect(offset, content="1")
    }
    _ => fail("expected the deepest failed branch")
  }
}

///|
test "choice merges expectations at the same offset" {
  let parser = Parser::choice([
    Parser::token('a', expected="a"),
    Parser::token('b', expected="b"),
  ])
  match parser.parse(['c']) {
    Err(ExpectedAny(labels~, offset~)) => {
      inspect(labels.length(), content="2")
      inspect(labels[0], content="a")
      inspect(labels[1], content="b")
      inspect(offset, content="0")
    }
    _ => fail("expected merged alternatives")
  }
}

///|
test "choice preserves the furthest retried failure" {
  let pair = Parser::token('a', expected="a")
    .then_right(Parser::token('b', expected="b"))
    .attempt()
  let parser = Parser::choice([pair, Parser::token('x', expected="x")])
  match parser.parse(['a', 'c']) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="b")
      inspect(offset, content="1")
    }
    _ => fail("expected the deepest choice failure")
  }
}

///|
test "cut commits a branch without consuming input" {
  let parser = Parser::cut()
    .then_right(Parser::token('a', expected="a"))
    .or_else(Parser::token('b', expected="b"))
  match parser.parse_all(['b']) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected cut to block the fallback")
  }
}

///|
test "attempt cannot revoke a cut" {
  let parser = Parser::cut()
    .then_right(Parser::token('a', expected="a"))
    .attempt()
    .or_else(Parser::token('b', expected="b"))
  match parser.parse(['b']) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="a")
      inspect(offset, content="0")
    }
    _ => fail("expected the hard cut to block fallback")
  }
}

///|
test "satisfy keeps its expectation at end of input" {
  match Parser::token('a', expected="a").parse([]) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="a")
      inspect(offset, content="0")
    }
    _ => fail("expected an EOF expectation")
  }
}

///|
test "then retains both parser values" {
  let parser = Parser::token('a', expected="a").then(
    Parser::token('b', expected="b"),
  )
  match parser.parse_all(['a', 'b']) {
    Ok((left, right)) => {
      inspect(left, content="a")
      inspect(right, content="b")
    }
    Err(_) => fail("expected both values")
  }
}

///|
test "flat_map can choose the following parser" {
  let parser = Parser::item().flat_map(first => {
    Parser::token(first, expected="repeated token")
  })
  match parser.parse_all(['x', 'x']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected the second token to match the first")
  }
}

///|
test "many stops at an unconsumed mismatch" {
  let parser = Parser::token('a', expected="a").many()
  match parser.parse_all(['a', 'a', 'b']) {
    Err(error) => inspect(error.offset(), content="2")
    Ok(_) => fail("expected trailing input to fail parse_all")
  }
}

///|
test "many1 and sep_by collect one or more separated values" {
  let value = Parser::token('a', expected="a")
  let parser = value.sep_by(Parser::token(',', expected="comma"))
  match parser.parse_all(['a', ',', 'a', ',', 'a']) {
    Ok(values) => inspect(values.length(), content="3")
    Err(_) => fail("expected separated values")
  }
  match value.many1().parse_all(['a', 'a']) {
    Ok(values) => inspect(values.length(), content="2")
    Err(_) => fail("expected one or more values")
  }
}

///|
test "choice selects the first successful alternative" {
  let parser = Parser::choice([
    Parser::token('a', expected="a"),
    Parser::token('b', expected="b"),
  ])
  match parser.parse_all(['b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the second alternative")
  }
}

///|
test "parsers are generic over token type" {
  let parser = Parser::token(1, expected="one").many1()
  match parser.parse_all([1, 1, 1]) {
    Ok(values) => inspect(values.length(), content="3")
    Err(_) => fail("expected integer tokens to parse")
  }
}

///|
test "label and context enrich an unconsumed failure" {
  let parser = Parser::token('a', expected="a")
    .label("identifier")
    .context("binding")
  match parser.parse(['b']) {
    Err(Context(label~, cause=Expected(label=expected, offset~))) => {
      inspect(label, content="binding")
      inspect(expected, content="identifier")
      inspect(offset, content="0")
    }
    _ => fail("expected contextualized label")
  }
}

///|
test "look_ahead observes without consuming input" {
  let parser = Parser::token('a', expected="a")
    .look_ahead()
    .then_right(Parser::token('a', expected="a"))
  match parser.parse_all(['a']) {
    Ok(value) => inspect(value, content="a")
    Err(_) => fail("expected look_ahead to preserve input")
  }
}

///|
test "not_followed_by rejects a matching parser" {
  let parser = Parser::token('a', expected="a")
    .not_followed_by(expected="a")
    .then_right(Parser::item())
  match parser.parse_all(['b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected a different token")
  }
  match parser.parse(['a']) {
    Err(NotFollowedBy(label~, offset~)) => {
      inspect(label, content="a")
      inspect(offset, content="0")
    }
    _ => fail("expected the forbidden token to fail")
  }
}

///|
test "many rejects a successful parser that does not consume input" {
  let input : Array[Char] = []
  let parser : Parser[Char, Array[Int]] = Parser::pure(1).many()
  match parser.parse(input) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected a non-consuming parser to fail many")
  }
}

///|
test "between and optional compose" {
  let parser = Parser::between(
    Parser::token('(', expected="opening parenthesis"),
    Parser::token('a', expected="a").optional(),
    Parser::token(')', expected="closing parenthesis"),
  )
  match parser.parse_all(['(', ')']) {
    Ok(None) => ()
    _ => fail("expected an absent optional token")
  }
}

///|
test "delay supports recursive grammars" {
  match nested_x().parse_all(['(', '(', 'x', ')', ')']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected nested delimiters to parse")
  }
}

///|
test "sequence and lift2 preserve ordered values" {
  let sequence = Parser::sequence([
    Parser::token('a', expected="a"),
    Parser::token('b', expected="b"),
  ])
  match sequence.parse_all(['a', 'b']) {
    Ok(values) => {
      inspect(values.length(), content="2")
      inspect(values[0], content="a")
      inspect(values[1], content="b")
    }
    Err(_) => fail("expected sequence to parse")
  }
  match sequence.parse_all(['a', 'b']) {
    Ok(values) => inspect(values.length(), content="2")
    Err(_) => fail("expected a sequence parser to be reusable")
  }

  let combined = Parser::lift2(
    Parser::token(2, expected="two"),
    Parser::token(3, expected="three"),
    (left, right) => left + right,
  )
  match combined.parse_all([2, 3]) {
    Ok(value) => inspect(value, content="5")
    Err(_) => fail("expected lift2 to combine values")
  }
}

///|
test "apply applies a parsed function" {
  let function : Parser[Int, (Int) -> Int] = Parser::token(
    0,
    expected="function marker",
  ).replace(value => value + 1)
  match
    function.apply(Parser::token(4, expected="argument")).parse_all([0, 4]) {
    Ok(value) => inspect(value, content="5")
    Err(_) => fail("expected apply to parse both operands")
  }
}

///|
test "count parses exactly its requested number of values" {
  let parser = Parser::token('a', expected="a").count(3)
  match parser.parse_all(['a', 'a', 'a']) {
    Ok(values) => inspect(values.length(), content="3")
    Err(_) => fail("expected exact repetition to parse")
  }
  match parser.parse(['a', 'a', 'x']) {
    Err(error) => inspect(error.offset(), content="2")
    Ok(_) => fail("expected exact repetition to reject a missing value")
  }
}

///|
test "repeat_0_to_n stops before an unconsumed mismatch" {
  let parser = Parser::token('a', expected="a").repeat_0_to_n(2)
  match parser.run(State::new(['a', 'a', 'b'])) {
    Ok((values, state)) => {
      inspect(values.length(), content="2")
      inspect(state.offset(), content="2")
    }
    Err(_) => fail("expected bounded repetition to stop at its bound")
  }
  match parser.parse(['b']) {
    Ok(values) => inspect(values.length(), content="0")
    Err(_) => fail("expected bounded repetition to accept zero values")
  }
}

///|
test "sep_by1 requires its first value and option supplies a default" {
  let values = Parser::token('a', expected="a").sep_by1(
    Parser::token(',', expected="comma"),
  )
  match values.parse_all(['a', ',', 'a']) {
    Ok(result) => inspect(result.length(), content="2")
    Err(_) => fail("expected a non-empty separated list")
  }
  match values.parse([]) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected sep_by1 to reject an empty list")
  }

  match Parser::token('a', expected="a").option('x').parse(['x']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected option to use its default")
  }
}

///|
test "parser references support recursive grammars and reject missing bindings" {
  let slot : ParserRef[Char, Char] = ParserRef::new()
  let nested = slot.parser()
  slot.set(
    Parser::token('x', expected="x").or_else(
      Parser::between(
        Parser::token('(', expected="opening parenthesis"),
        nested,
        Parser::token(')', expected="closing parenthesis"),
      ),
    ),
  )
  match nested.parse_all(['(', 'x', ')']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected the parser reference to recurse")
  }

  let unbound : ParserRef[Char, Char] = ParserRef::new()
  match unbound.parser().parse([]) {
    Err(UnboundReference(offset~)) => inspect(offset, content="0")
    _ => fail("expected an unbound parser reference error")
  }
}
