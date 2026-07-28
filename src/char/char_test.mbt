///|
test "string parses complete character input" {
  match string("moon").parse_all(['m', 'o', 'o', 'n']) {
    Ok(value) => inspect(value, content="moon")
    Err(_) => fail("expected string parser to succeed")
  }
}

///|
test "digits and one_of use root parser combinators" {
  match digits().parse_all(['4', '2']) {
    Ok(value) => inspect(value, content="42")
    Err(_) => fail("expected digits parser to succeed")
  }
  match one_of(['x', 'y'], expected="x or y").parse_all(['y']) {
    Ok(value) => inspect(value, content="y")
    Err(_) => fail("expected one_of parser to succeed")
  }
}

///|
test "character classes recognize whitespace and ASCII word characters" {
  match whitespace().parse_all(['\n']) {
    Ok(value) => inspect(value == '\n', content="true")
    Err(_) => fail("expected whitespace")
  }
  match spaces().parse_all([' ', '\t', '\n']) {
    Ok(_) => ()
    Err(_) => fail("expected spaces")
  }
  match letter().parse_all(['Z']) {
    Ok(value) => inspect(value == 'Z', content="true")
    Err(_) => fail("expected letter")
  }
  match alpha_num().parse_all(['7']) {
    Ok(value) => inspect(value == '7', content="true")
    Err(_) => fail("expected alpha_num")
  }
}

///|
test "identifier uses ASCII start and continuation rules" {
  match identifier().parse_all(['_', 'm', 'o', 'o', 'n', '2']) {
    Ok(value) => inspect(value, content="_moon2")
    Err(_) => fail("expected identifier")
  }
  match identifier().parse_all(['2', 'm']) {
    Ok(_) => fail("identifier must not start with a digit")
    Err(error) => inspect(error.offset(), content="0")
  }
  match identifier().parse_all(['m', '-']) {
    Ok(_) =>
      fail("identifier parser must leave invalid continuations unconsumed")
    Err(error) => inspect(error.offset(), content="1")
  }
}

///|
test "integer parses signed decimal values" {
  match integer().parse_all(['+', '4', '2']) {
    Ok(value) => inspect(value, content="42")
    Err(_) => fail("expected positive integer")
  }
  match integer().parse_all(['-', '1', '7']) {
    Ok(value) => inspect(value, content="-17")
    Err(_) => fail("expected negative integer")
  }
  match integer().parse_all(['-']) {
    Ok(_) => fail("sign without digits must fail")
    Err(error) => inspect(error.offset(), content="1")
  }
}

///|
test "symbol consumes trailing whitespace" {
  match
    symbol("=>").then_right(identifier()).parse_all(['=', '>', ' ', '\n', 'x']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected symbol followed by identifier")
  }
}
