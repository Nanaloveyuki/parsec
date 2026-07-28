///|
test "strict JSON parses nested values and preserves number text" {
  match
    parse(
      " { \"enabled\" : true, \"ratio\" : -12.5E+2, \"items\" : [null, \"x\"] } ",
    ) {
    Ok(Object(members~)) => {
      inspect(members.length(), content="3")
      inspect(members[0].0, content="enabled")
      match members[1].1 {
        Number(raw~) => inspect(raw, content="-12.5E+2")
        _ => fail("expected preserved JSON number text")
      }
      match members[2].1 {
        Array(items~) => inspect(items.length(), content="2")
        _ => fail("expected a JSON array")
      }
    }
    Err(_) => fail("expected strict JSON input to parse")
    _ => fail("expected a JSON object")
  }
}

///|
test "strict JSON rejects JSON5-style numbers and non-JSON whitespace" {
  for input in ["+1", "01", "1."] {
    match parse(input) {
      Err(_) => ()
      Ok(_) => fail("expected invalid JSON number to fail")
    }
  }
  let non_json_space = String::from_array([
    (0xA0).unsafe_to_char(),
    'n',
    'u',
    'l',
    'l',
  ])
  match parse(non_json_space) {
    Err(_) => ()
    Ok(_) => fail("expected non-JSON whitespace to fail")
  }
}

///|
test "JSON strings decode surrogate pairs and reject malformed escapes" {
  let musical_symbol = String::from_array([(0x1D11E).unsafe_to_char()])
  match parse("\"\\uD834\\uDD1E\"") {
    Ok(Text(value~)) => inspect(value, content=musical_symbol)
    _ => fail("expected a valid surrogate pair")
  }
  for input in ["\"\\uD834\"", "\"\\uDD1E\"", "\"\\x\""] {
    match parse(input) {
      Err(_) => ()
      Ok(_) => fail("expected malformed JSON string escape to fail")
    }
  }
}

///|
test "JSON rejects duplicate object keys with source positions" {
  let input = "{\"a\":1,\"a\":2}"
  match parse(input) {
    Err(DuplicateKey(key~, first_offset~, duplicate_offset~)) => {
      inspect(key, content="a")
      inspect(first_offset, content="1")
      inspect(duplicate_offset, content="7")
      let source = @lexer.Source::new(input)
      match
        JsonError::DuplicateKey(key~, first_offset~, duplicate_offset~).position(
          source,
        ) {
        Some(position) => {
          inspect(position.line(), content="1")
          inspect(position.column(), content="8")
        }
        None => fail("expected duplicate key position")
      }
    }
    _ => fail("expected duplicate object key error")
  }
}

///|
test "JSON limits stop input before unbounded structures are accepted" {
  let input_limit = JsonLimits::new(
    max_input_chars=3,
    max_depth=8,
    max_string_chars=8,
    max_array_items=8,
    max_object_members=8,
  )
  match parse_with_limits("null", input_limit) {
    Err(Limit(kind=InputChars, offset~, limit~)) => {
      inspect(offset, content="3")
      inspect(limit, content="3")
    }
    _ => fail("expected input character limit")
  }

  let depth_limit = JsonLimits::new(
    max_input_chars=64,
    max_depth=1,
    max_string_chars=8,
    max_array_items=8,
    max_object_members=8,
  )
  match parse_with_limits("[[]]", depth_limit) {
    Err(Limit(kind=NestingDepth, offset~, ..)) => inspect(offset, content="1")
    _ => fail("expected nesting depth limit")
  }

  let collection_limit = JsonLimits::new(
    max_input_chars=64,
    max_depth=8,
    max_string_chars=1,
    max_array_items=1,
    max_object_members=1,
  )
  match parse_with_limits("\"ab\"", collection_limit) {
    Err(Limit(kind=StringChars, offset~, ..)) => inspect(offset, content="2")
    _ => fail("expected string character limit")
  }
  match parse_with_limits("[1,2]", collection_limit) {
    Err(Limit(kind=ArrayItems, offset~, ..)) => inspect(offset, content="3")
    _ => fail("expected array item limit")
  }
  match parse_with_limits("[1,]", collection_limit) {
    Err(Syntax(..)) => ()
    _ => fail("expected trailing array comma to remain invalid at the limit")
  }
  match parse_with_limits("{\"a\":1,\"b\":2}", collection_limit) {
    Err(Limit(kind=ObjectMembers, offset~, ..)) => inspect(offset, content="7")
    _ => fail("expected object member limit")
  }
  match parse_with_limits("{\"a\":1,}", collection_limit) {
    Err(Syntax(..)) => ()
    _ => fail("expected trailing object comma to remain invalid at the limit")
  }
}
