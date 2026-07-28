///|
pub struct Position {
  priv offset : Int
  priv line : Int
  priv column : Int
}

///|
pub fn Position::offset(self : Position) -> Int {
  self.offset
}

///|
pub fn Position::line(self : Position) -> Int {
  self.line
}

///|
pub fn Position::column(self : Position) -> Int {
  self.column
}

///|
pub struct Span {
  priv start : Position
  priv end : Position
}

///|
pub fn Span::start(self : Span) -> Position {
  self.start
}

///|
pub fn Span::end(self : Span) -> Position {
  self.end
}

///|
pub fn Span::length(self : Span) -> Int {
  self.end.offset() - self.start.offset()
}

///|
pub struct Located[T] {
  priv value : T
  priv span : Span
}

///|
pub fn[T] Located::new(value : T, span : Span) -> Located[T] {
  { value, span }
}

///|
pub fn[T] Located::value(self : Located[T]) -> T {
  self.value
}

///|
pub fn[T] Located::span(self : Located[T]) -> Span {
  self.span
}

///|
pub fn[T, U] Located::map(
  self : Located[T],
  transform : (T) -> U,
) -> Located[U] {
  { value: transform(self.value), span: self.span }
}

///|
pub struct Source {
  priv text : String
  priv length : Int
  priv line_starts : Array[Int]
}

///|
pub fn Source::new(text : String) -> Source {
  let line_starts = [0]
  let mut length = 0
  for char in text {
    length = length + 1
    if char == '\n' {
      line_starts.push(length)
    }
  }
  { text, length, line_starts }
}

///|
pub fn Source::text(self : Source) -> String {
  self.text
}

///|
pub fn Source::length(self : Source) -> Int {
  self.length
}

///|
pub fn Source::line_count(self : Source) -> Int {
  self.line_starts.length()
}

///|
pub fn Source::position_at(self : Source, offset : Int) -> Position? {
  if offset < 0 || offset > self.length {
    None
  } else {
    let mut line_index = 0
    for index = 1; index < self.line_starts.length(); index = index + 1 {
      if self.line_starts[index] > offset {
        break
      }
      line_index = index
    }
    let line_start = self.line_starts[line_index]
    Some({ offset, line: line_index + 1, column: offset - line_start + 1 })
  }
}

///|
pub fn Source::span(self : Source, start : Int, end : Int) -> Span? {
  if end < start {
    None
  } else {
    match (self.position_at(start), self.position_at(end)) {
      (Some(start), Some(end)) => Some({ start, end })
      _ => None
    }
  }
}

///|
pub fn Source::error_position(
  self : Source,
  error : @parsec.ParseError,
) -> Position? {
  self.position_at(error.offset())
}
