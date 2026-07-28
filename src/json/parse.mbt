///|
using @hashmap {type HashMap}

///|
fn parse_error_has_label(error : @parsec.ParseError, label : String) -> Bool {
  match error {
    Expected(label=actual, ..) => actual == label
    ExpectedAny(labels~, ..) => labels.contains(label)
    NotFollowedBy(label=actual, ..) => actual == label
    Context(cause~, ..) => parse_error_has_label(cause, label)
    _ => false
  }
}

///|
fn error_from_parse(
  error : @parsec.ParseError,
  limits : JsonLimits,
) -> JsonError {
  let offset = error.offset()
  if parse_error_has_label(error, depth_limit_label) {
    Limit(kind=NestingDepth, offset~, limit=limits.max_depth)
  } else if parse_error_has_label(error, string_limit_label) {
    Limit(kind=StringChars, offset~, limit=limits.max_string_chars)
  } else if parse_error_has_label(error, array_limit_label) {
    Limit(kind=ArrayItems, offset~, limit=limits.max_array_items)
  } else if parse_error_has_label(error, object_limit_label) {
    Limit(kind=ObjectMembers, offset~, limit=limits.max_object_members)
  } else {
    Syntax(error~)
  }
}

///|
fn validate_items(items : Array[RawJson]) -> Result[Array[Json], JsonError] {
  let values = []
  let mut failure : JsonError? = None
  for item in items {
    match failure {
      Some(_) => ()
      None =>
        match validate(item) {
          Ok(value) => values.push(value)
          Err(error) => failure = Some(error)
        }
    }
  }
  match failure {
    Some(error) => Err(error)
    None => Ok(values)
  }
}

///|
fn validate_members(
  members : Array[RawMember],
  seen : @hashmap.HashMap[String, Int],
) -> Result[Array[(String, Json)], JsonError] {
  let values = []
  let mut failure : JsonError? = None
  for property in members {
    match failure {
      Some(_) => ()
      None =>
        match seen.get(property.key) {
          Some(first_offset) =>
            failure = Some(
              DuplicateKey(
                key=property.key,
                first_offset~,
                duplicate_offset=property.key_offset,
              ),
            )
          None =>
            match validate(property.value) {
              Ok(value) => {
                seen.set(property.key, property.key_offset)
                values.push((property.key, value))
              }
              Err(error) => failure = Some(error)
            }
        }
    }
  }
  match failure {
    Some(error) => Err(error)
    None => Ok(values)
  }
}

///|
fn validate(raw : RawJson) -> Result[Json, JsonError] {
  match raw {
    Null => Ok(Null)
    Bool(value) => Ok(Bool(value~))
    Number(raw) => Ok(Number(raw~))
    Text(value) => Ok(Text(value~))
    Array(items) =>
      match validate_items(items) {
        Ok(values) => Ok(Array(items=values))
        Err(error) => Err(error)
      }
    Object(members) => {
      let seen : HashMap[String, Int] = HashMap([], capacity=members.length())
      match validate_members(members, seen) {
        Ok(values) => Ok(Object(members=values))
        Err(error) => Err(error)
      }
    }
  }
}

///|
pub fn parse_with_limits(
  input : String,
  limits : JsonLimits,
) -> Result[Json, JsonError] {
  let chars = input.to_array()
  if chars.length() > limits.max_input_chars {
    Err(
      Limit(
        kind=InputChars,
        offset=limits.max_input_chars,
        limit=limits.max_input_chars,
      ),
    )
  } else {
    let parser = json_whitespace()
      .then_right(value(limits, 0))
      .then_left(@parsec.Parser::eof())
    match parser.parse(chars) {
      Ok(raw) => validate(raw)
      Err(error) => Err(error_from_parse(error, limits))
    }
  }
}

///|
pub fn parse(input : String) -> Result[Json, JsonError] {
  parse_with_limits(input, JsonLimits::standard())
}
