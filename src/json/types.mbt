///|
pub(all) enum Json {
  Null
  Bool(value~ : Bool)
  Number(raw~ : String)
  Text(value~ : String)
  Array(items~ : Array[Json])
  Object(members~ : Array[(String, Json)])
}

///|
pub(all) enum JsonLimitKind {
  InputChars
  NestingDepth
  StringChars
  ArrayItems
  ObjectMembers
}

///|
pub struct JsonLimits {
  priv max_input_chars : Int
  priv max_depth : Int
  priv max_string_chars : Int
  priv max_array_items : Int
  priv max_object_members : Int
}

///|
pub fn JsonLimits::new(
  max_input_chars~ : Int,
  max_depth~ : Int,
  max_string_chars~ : Int,
  max_array_items~ : Int,
  max_object_members~ : Int,
) -> JsonLimits {
  {
    max_input_chars,
    max_depth,
    max_string_chars,
    max_array_items,
    max_object_members,
  }
}

///|
pub fn JsonLimits::standard() -> JsonLimits {
  JsonLimits::new(
    max_input_chars=1_048_576,
    max_depth=128,
    max_string_chars=262_144,
    max_array_items=65_536,
    max_object_members=65_536,
  )
}

///|
pub(all) enum JsonError {
  Syntax(error~ : @parsec.ParseError)
  DuplicateKey(key~ : String, first_offset~ : Int, duplicate_offset~ : Int)
  Limit(kind~ : JsonLimitKind, offset~ : Int, limit~ : Int)
}

///|
pub fn JsonError::offset(self : JsonError) -> Int {
  match self {
    Syntax(error~) => error.offset()
    DuplicateKey(duplicate_offset~, ..) => duplicate_offset
    Limit(offset~, ..) => offset
  }
}

///|
pub fn JsonError::position(
  self : JsonError,
  source : @lexer.Source,
) -> @lexer.Position? {
  source.position_at(self.offset())
}

///|
priv enum RawJson {
  Null
  Bool(Bool)
  Number(String)
  Text(String)
  Array(Array[RawJson])
  Object(Array[RawMember])
}

///|
priv struct RawMember {
  key : String
  key_offset : Int
  value : RawJson
}
