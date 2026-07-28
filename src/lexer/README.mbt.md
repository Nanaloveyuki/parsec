# Nanaloveyuki/parsec/lexer

`lexer` provides source-location data for tokenizers and parser diagnostics.
Offsets are character offsets, lines and columns are one-based, and spans are
half-open ranges: `[start, end)`.

```mbt check
///|
test "locate a parser error" {
  let source = Source::new("ab\ncd")
  match source.position_at(3) {
    Some(position) => {
      inspect(position.line(), content="2")
      inspect(position.column(), content="1")
    }
    None => fail("expected source position")
  }
}
```

Use `Source::error_position` to map a root `@parsec.ParseError` to text. This
package does not own token trivia, recovery, CST construction, or AST lowering.
