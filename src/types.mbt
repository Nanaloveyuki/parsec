///|
pub(all) enum ParseError {
  UnexpectedEnd(offset~ : Int)
  Expected(label~ : String, offset~ : Int)
  ExpectedAny(labels~ : Array[String], offset~ : Int)
  EmptyMatchInMany(offset~ : Int)
  EmptyChoice(offset~ : Int)
  NotFollowedBy(label~ : String, offset~ : Int)
  Context(label~ : String, cause~ : ParseError)
}

///|
pub fn ParseError::offset(self : ParseError) -> Int {
  match self {
    UnexpectedEnd(offset~) => offset
    Expected(offset~, ..) => offset
    ExpectedAny(offset~, ..) => offset
    EmptyMatchInMany(offset~) => offset
    EmptyChoice(offset~) => offset
    NotFollowedBy(offset~, ..) => offset
    Context(cause~, ..) => cause.offset()
  }
}

///|
fn append_unique_label(labels : Array[String], label : String) -> Array[String] {
  let merged = labels.copy()
  if !merged.contains(label) {
    merged.push(label)
  }
  merged
}

///|
fn ParseError::merge_at_same_offset(
  self : ParseError,
  other : ParseError,
) -> ParseError {
  match (self, other) {
    (Expected(label=left, offset~), Expected(label=right, ..)) =>
      if left == right {
        self
      } else {
        ExpectedAny(labels=[left, right], offset~)
      }
    (ExpectedAny(labels=left, offset~), Expected(label=right, ..)) =>
      ExpectedAny(labels=append_unique_label(left, right), offset~)
    (Expected(label=left, offset~), ExpectedAny(labels=right, ..)) =>
      ExpectedAny(labels=append_unique_label(right, left), offset~)
    (ExpectedAny(labels=left, offset~), ExpectedAny(labels=right, ..)) => {
      let merged = left.copy()
      for label in right {
        if !merged.contains(label) {
          merged.push(label)
        }
      }
      ExpectedAny(labels=merged, offset~)
    }
    _ => other
  }
}

///|
fn ParseError::furthest(self : ParseError, other : ParseError) -> ParseError {
  if self.offset() > other.offset() {
    self
  } else if self.offset() < other.offset() {
    other
  } else {
    self.merge_at_same_offset(other)
  }
}

///|
pub struct State[T] {
  priv input : Array[T]
  priv offset : Int
}

///|
pub fn[T] State::new(input : Array[T]) -> State[T] {
  { input, offset: 0 }
}

///|
pub fn[T] State::offset(self : State[T]) -> Int {
  self.offset
}

///|
pub fn[T] State::is_at_end(self : State[T]) -> Bool {
  self.offset == self.input.length()
}

///|
fn[T] State::next(self : State[T]) -> (T, State[T])? {
  match self.input.get(self.offset) {
    Some(token) => Some((token, { input: self.input, offset: self.offset + 1 }))
    None => None
  }
}

///|
pub struct Parser[T, A] {
  priv execute : (State[T]) -> Reply[T, A]
}

///|
enum Reply[T, A] {
  Success(A, State[T], Bool, Bool)
  Failure(ParseError, Bool, Bool)
}

///|
fn[T, A] Reply::to_result(
  self : Reply[T, A],
) -> Result[(A, State[T]), ParseError] {
  match self {
    Success(value, state, _, _) => Ok((value, state))
    Failure(error, _, _) => Err(error)
  }
}

///|
fn[T, A] Reply::with_prefix(
  self : Reply[T, A],
  consumed : Bool,
  committed : Bool,
) -> Reply[T, A] {
  match self {
    Success(value, state, next_consumed, next_committed) =>
      Success(
        value,
        state,
        consumed || next_consumed,
        committed || next_committed,
      )
    Failure(error, next_consumed, next_committed) =>
      Failure(error, consumed || next_consumed, committed || next_committed)
  }
}
