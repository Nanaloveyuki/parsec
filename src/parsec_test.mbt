///|
fn nested_x() -> @parsec.Parser[Char, Char] {
  @parsec.Parser::token('x', expected="x").or_else(
    @parsec.Parser::between(
      @parsec.Parser::token('(', expected="opening parenthesis"),
      @parsec.Parser::delay(() => nested_x()),
      @parsec.Parser::token(')', expected="closing parenthesis"),
    ),
  )
}

///|
test "sequences matching tokens" {
  let parser = @parsec.Parser::token('a', expected="a").then_right(
    @parsec.Parser::token('b', expected="b"),
  )
  match parser.parse_all(['a', 'b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the sequence to parse")
  }
}

///|
test "choice backtracks only before consuming input" {
  let parser = @parsec.Parser::token('a', expected="a").or_else(
    @parsec.Parser::token('b', expected="b"),
  )
  match parser.parse_all(['b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the fallback to parse")
  }
}

///|
test "choice does not discard a consumed prefix" {
  let parser = @parsec.Parser::token('a', expected="a")
    .then_right(@parsec.Parser::token('b', expected="b"))
    .or_else(@parsec.Parser::token('a', expected="a"))
  match parser.parse_all(['a', 'c']) {
    Err(error) => inspect(error.offset(), content="1")
    Ok(_) => fail("expected the committed branch to fail")
  }
}

///|
test "attempt allows an explicitly retried consumed prefix" {
  let pair = @parsec.Parser::token('a', expected="a").then_right(
    @parsec.Parser::token('b', expected="b"),
  )
  let parser = pair.attempt().or_else(@parsec.Parser::token('a', expected="a"))
  match parser.parse_all(['a']) {
    Ok(value) => inspect(value, content="a")
    Err(_) => fail("expected attempt to restore the fallback")
  }
}

///|
test "attempt preserves the furthest failed expectation" {
  let pair = @parsec.Parser::token('a', expected="a").then_right(
    @parsec.Parser::token('b', expected="b"),
  )
  let parser = pair.attempt().or_else(@parsec.Parser::token('x', expected="x"))
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
  let parser = @parsec.Parser::choice([
    @parsec.Parser::token('a', expected="a"),
    @parsec.Parser::token('b', expected="b"),
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
  let pair = @parsec.Parser::token('a', expected="a")
    .then_right(@parsec.Parser::token('b', expected="b"))
    .attempt()
  let parser = @parsec.Parser::choice([
    pair,
    @parsec.Parser::token('x', expected="x"),
  ])
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
  let parser = @parsec.Parser::cut()
    .then_right(@parsec.Parser::token('a', expected="a"))
    .or_else(@parsec.Parser::token('b', expected="b"))
  match parser.parse_all(['b']) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected cut to block the fallback")
  }
}

///|
test "attempt cannot revoke a cut" {
  let parser = @parsec.Parser::cut()
    .then_right(@parsec.Parser::token('a', expected="a"))
    .attempt()
    .or_else(@parsec.Parser::token('b', expected="b"))
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
  match @parsec.Parser::token('a', expected="a").parse([]) {
    Err(Expected(label~, offset~)) => {
      inspect(label, content="a")
      inspect(offset, content="0")
    }
    _ => fail("expected an EOF expectation")
  }
}

///|
test "then retains both parser values" {
  let parser = @parsec.Parser::token('a', expected="a").then(
    @parsec.Parser::token('b', expected="b"),
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
  let parser = @parsec.Parser::item().flat_map(first => {
    @parsec.Parser::token(first, expected="repeated token")
  })
  match parser.parse_all(['x', 'x']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected the second token to match the first")
  }
}

///|
test "many stops at an unconsumed mismatch" {
  let parser = @parsec.Parser::token('a', expected="a").many()
  match parser.parse_all(['a', 'a', 'b']) {
    Err(error) => inspect(error.offset(), content="2")
    Ok(_) => fail("expected trailing input to fail parse_all")
  }
}

///|
test "many1 and sep_by collect one or more separated values" {
  let value = @parsec.Parser::token('a', expected="a")
  let parser = value.sep_by(@parsec.Parser::token(',', expected="comma"))
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
  let parser = @parsec.Parser::choice([
    @parsec.Parser::token('a', expected="a"),
    @parsec.Parser::token('b', expected="b"),
  ])
  match parser.parse_all(['b']) {
    Ok(value) => inspect(value, content="b")
    Err(_) => fail("expected the second alternative")
  }
}

///|
test "parsers are generic over token type" {
  let parser = @parsec.Parser::token(1, expected="one").many1()
  match parser.parse_all([1, 1, 1]) {
    Ok(values) => inspect(values.length(), content="3")
    Err(_) => fail("expected integer tokens to parse")
  }
}

///|
test "label and context enrich an unconsumed failure" {
  let parser = @parsec.Parser::token('a', expected="a")
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
  let parser = @parsec.Parser::token('a', expected="a")
    .look_ahead()
    .then_right(@parsec.Parser::token('a', expected="a"))
  match parser.parse_all(['a']) {
    Ok(value) => inspect(value, content="a")
    Err(_) => fail("expected look_ahead to preserve input")
  }
}

///|
test "not_followed_by rejects a matching parser" {
  let parser = @parsec.Parser::token('a', expected="a")
    .not_followed_by(expected="a")
    .then_right(@parsec.Parser::item())
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
  let parser : @parsec.Parser[Char, Array[Int]] = @parsec.Parser::pure(1).many()
  match parser.parse(input) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected a non-consuming parser to fail many")
  }
}

///|
test "between and optional compose" {
  let parser = @parsec.Parser::between(
    @parsec.Parser::token('(', expected="opening parenthesis"),
    @parsec.Parser::token('a', expected="a").optional(),
    @parsec.Parser::token(')', expected="closing parenthesis"),
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
test "position observes the current offset without consuming input" {
  let parser = @parsec.Parser::token('a', expected="a").then_right(
    @parsec.Parser::position(),
  )
  match parser.parse_all(['a']) {
    Ok(offset) => inspect(offset, content="1")
    Err(_) => fail("expected the position parser to succeed")
  }
}

///|
test "bounded repetition collects large inputs iteratively" {
  let input = []
  for _ in 0..<4096 {
    input.push('a')
  }
  let parser = @parsec.Parser::token('a', expected="a").repeat_0_to_n(4096)
  match parser.parse_all(input) {
    Ok(values) => inspect(values.length(), content="4096")
    Err(_) => fail("expected the bounded parser to collect every token")
  }
}

///|
test "sequence and lift2 preserve ordered values" {
  let sequence = @parsec.Parser::sequence([
    @parsec.Parser::token('a', expected="a"),
    @parsec.Parser::token('b', expected="b"),
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

  let combined = @parsec.Parser::lift2(
    @parsec.Parser::token(2, expected="two"),
    @parsec.Parser::token(3, expected="three"),
    (left, right) => left + right,
  )
  match combined.parse_all([2, 3]) {
    Ok(value) => inspect(value, content="5")
    Err(_) => fail("expected lift2 to combine values")
  }
}

///|
test "apply applies a parsed function" {
  let function : @parsec.Parser[Int, (Int) -> Int] = @parsec.Parser::token(
    0,
    expected="function marker",
  ).replace(value => value + 1)
  match
    function
    .apply(@parsec.Parser::token(4, expected="argument"))
    .parse_all([0, 4]) {
    Ok(value) => inspect(value, content="5")
    Err(_) => fail("expected apply to parse both operands")
  }
}

///|
test "count parses exactly its requested number of values" {
  let parser = @parsec.Parser::token('a', expected="a").count(3)
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
  let parser = @parsec.Parser::token('a', expected="a").repeat_0_to_n(2)
  match parser.run(@parsec.State::new(['a', 'a', 'b'])) {
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
  let values = @parsec.Parser::token('a', expected="a").sep_by1(
    @parsec.Parser::token(',', expected="comma"),
  )
  match values.parse_all(['a', ',', 'a']) {
    Ok(result) => inspect(result.length(), content="2")
    Err(_) => fail("expected a non-empty separated list")
  }
  match values.parse([]) {
    Err(error) => inspect(error.offset(), content="0")
    Ok(_) => fail("expected sep_by1 to reject an empty list")
  }

  match @parsec.Parser::token('a', expected="a").option('x').parse(['x']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected option to use its default")
  }
}

///|
test "parser references support recursive grammars and reject missing bindings" {
  let slot : @parsec.ParserRef[Char, Char] = @parsec.ParserRef::new()
  let nested = slot.parser()
  slot.set(
    @parsec.Parser::token('x', expected="x").or_else(
      @parsec.Parser::between(
        @parsec.Parser::token('(', expected="opening parenthesis"),
        nested,
        @parsec.Parser::token(')', expected="closing parenthesis"),
      ),
    ),
  )
  match nested.parse_all(['(', 'x', ')']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected the parser reference to recurse")
  }

  let unbound : @parsec.ParserRef[Char, Char] = @parsec.ParserRef::new()
  match unbound.parser().parse([]) {
    Err(UnboundReference(offset~)) => inspect(offset, content="0")
    _ => fail("expected an unbound parser reference error")
  }
}
