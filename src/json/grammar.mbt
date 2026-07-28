///|
fn depth_limit() -> @parsec.Parser[Char, RawJson] {
  @parsec.Parser::choice([
    raw_char('[', expected="JSON nesting depth limit"),
    raw_char('{', expected="JSON nesting depth limit"),
  ])
  .look_ahead()
  .then_right(@parsec.Parser::cut())
  .then_right(fail_at(depth_limit_label))
}

///|
fn array_items(
  limits : JsonLimits,
  depth : Int,
) -> @parsec.Parser[Char, Array[RawJson]] {
  let item = @parsec.Parser::delay(() => value(limits, depth + 1))
  if limits.max_array_items <= 0 {
    item
    .look_ahead()
    .not_followed_by(expected=array_limit_label)
    .then_right(@parsec.Parser::pure([]))
  } else {
    let nonempty = item.flat_map(first => {
      token(',', expected="comma")
      .then_right(item)
      .repeat_0_to_n(limits.max_array_items - 1)
      .map(rest => {
        let items = [first]
        for item in rest {
          items.push(item)
        }
        items
      })
    })
    let over_limit = token(',', expected="comma")
      .then_right(item.look_ahead().then_right(fail_at(array_limit_label)))
      .or_else(@parsec.Parser::pure(()))
    nonempty.or_else(@parsec.Parser::pure([])).then_left(over_limit)
  }
}

///|
fn array(limits : JsonLimits, depth : Int) -> @parsec.Parser[Char, RawJson] {
  token('[', expected="opening bracket")
  .then_right(array_items(limits, depth))
  .then_left(token(']', expected="closing bracket"))
  .map(items => Array(items))
}

///|
fn property(
  limits : JsonLimits,
  depth : Int,
) -> @parsec.Parser[Char, RawMember] {
  @parsec.Parser::position()
  .then(string(limits))
  .flat_map(key => {
    token(':', expected="colon")
    .then_right(@parsec.Parser::delay(() => value(limits, depth + 1)))
    .map(value => { key: key.1, key_offset: key.0, value })
  })
}

///|
fn object_members(
  limits : JsonLimits,
  depth : Int,
) -> @parsec.Parser[Char, Array[RawMember]] {
  let current_property = property(limits, depth)
  if limits.max_object_members <= 0 {
    current_property
    .look_ahead()
    .not_followed_by(expected=object_limit_label)
    .then_right(@parsec.Parser::pure([]))
  } else {
    let nonempty = current_property.flat_map(first => {
      token(',', expected="comma")
      .then_right(current_property)
      .repeat_0_to_n(limits.max_object_members - 1)
      .map(rest => {
        let properties = [first]
        for property in rest {
          properties.push(property)
        }
        properties
      })
    })
    let over_limit = token(',', expected="comma")
      .then_right(
        current_property.look_ahead().then_right(fail_at(object_limit_label)),
      )
      .or_else(@parsec.Parser::pure(()))
    nonempty.or_else(@parsec.Parser::pure([])).then_left(over_limit)
  }
}

///|
fn object(limits : JsonLimits, depth : Int) -> @parsec.Parser[Char, RawJson] {
  token('{', expected="opening brace")
  .then_right(object_members(limits, depth))
  .then_left(token('}', expected="closing brace"))
  .map(members => Object(members))
}

///|
fn scalar(limits : JsonLimits) -> @parsec.Parser[Char, RawJson] {
  @parsec.Parser::choice([
    text("null", expected="null").replace(Null),
    text("true", expected="true").replace(Bool(true)),
    text("false", expected="false").replace(Bool(false)),
    string(limits).map(value => Text(value)),
    number().map(raw => Number(raw)),
  ])
}

///|
fn value(limits : JsonLimits, depth : Int) -> @parsec.Parser[Char, RawJson] {
  let scalar = scalar(limits)
  if depth >= limits.max_depth {
    scalar.or_else(depth_limit())
  } else {
    scalar
    .or_else(@parsec.Parser::delay(() => array(limits, depth)))
    .or_else(@parsec.Parser::delay(() => object(limits, depth)))
  }
}
