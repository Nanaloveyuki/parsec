# Using parsec

## Input And Results

`Parser[T, A]` consumes an `Array[T]` and returns either `Ok(A)` or a
`ParseError`. `T` is an application-defined token type, so the same library
works for character streams, lexer tokens, bytes, and structured token arrays.

Use `parse` when trailing input is allowed. Use `parse_all` when the grammar
must consume the complete input.

```mbt nocheck
let digit = @parsec.Parser::satisfy("digit", char => char >= '0' && char <= '9')

match digit.parse_all(['7']) {
  Ok(value) => println(value)
  Err(error) => println("parse failed at \{error.offset()}")
}
```

## Core Combinators

| Combinator | Behavior |
| --- | --- |
| `pure(value)` | Succeeds without consuming input. |
| `fail(error)` | Fails at a caller-provided error. |
| `item()` | Consumes one token. |
| `satisfy(label, predicate)` | Consumes one token only when `predicate` accepts it. |
| `token(value, expected=...)` | Matches an equality-comparable token. |
| `end()` | Succeeds only at end of input. |
| `map(f)` | Transforms a successful result. |
| `flat_map(f)` | Chooses the next parser from the previous result. |
| `and_then(f)` | Compatibility spelling of `flat_map`. |
| `then(next)` | Sequences two parsers and keeps both results as a pair. |
| `then_right(next)` | Sequences two parsers and keeps the right result. |
| `then_left(next)` | Sequences two parsers and keeps the left result. |
| `replace(value)` / `ignore()` | Replaces a parsed value or discards it as `Unit`. |
| `optional()` | Produces `Some(value)` or `None`. |
| `many()` / `some()` / `many1()` | Collects zero-or-more / one-or-more values. |
| `sep_by(separator)` | Parses zero-or-more values separated by `separator`. |
| `between(open, parser, close)` | Parses a delimited value. |
| `delay(factory)` | Delays parser construction for recursive grammars. |
| `look_ahead()` | Requires a parser to succeed without consuming input. |
| `not_followed_by(expected=...)` | Requires a parser not to match at the current input. |

MoonBit reserves `as` and `void`, so the equivalent helpers are named
`replace` and `ignore`.

## Choice And Consumption

`or_else` is committed choice. It tries its fallback only when the first parser
fails before consuming input and before a cut. A failure after consumption is
returned as-is. This avoids accepting an alternative after a prefix has already
identified a different grammar branch.

```mbt nocheck
let pair = @parsec.Parser::token('a', expected="a").then_right(
  @parsec.Parser::token('b', expected="b"),
)
let parser = pair.or_else(@parsec.Parser::token('a', expected="a"))

// ['a', 'c'] fails at offset 1. The fallback is not tried because `pair`
// consumed 'a' before discovering that 'b' was absent.
```

Use `attempt()` when a branch intentionally needs to restore its input and let
the next alternative run after a consumed failure. Use `Parser::cut()` in a
sequence to commit even when the parser has not consumed a token yet:

```mbt nocheck
let pair = @parsec.Parser::token('a', expected="a").then_right(
  @parsec.Parser::token('b', expected="b"),
)
let retryable = pair.attempt().or_else(@parsec.Parser::token('a', expected="a"))

let committed = @parsec.Parser::cut()
  .then_right(@parsec.Parser::token('a', expected="a"))
  .or_else(@parsec.Parser::token('b', expected="b"))
```

## Repetition

`many` ends successfully only when its child parser fails without consuming
input. A child that succeeds without advancing input causes
`EmptyMatchInMany`, because continuing would not terminate.

Do not write `Parser::pure(value).many()`. Put the optionality outside the
repetition, or use a parser that consumes at least one token on success.

## Errors

`ParseError` carries the token offset where parsing stopped:

- `UnexpectedEnd` means a parser needed another token.
- `Expected` records a caller-supplied expectation label.
- `EmptyMatchInMany` identifies a non-consuming repetition.
- `EmptyChoice` identifies an empty `choice` list.
- `NotFollowedBy` identifies forbidden lookahead.
- `Context` wraps a nested parser failure with a grammar label.

Errors use token offsets, not line and column numbers. Applications that parse
text can map offsets to source locations in their own input layer.

Use `label` to replace an expectation at the current input position, and
`context` to preserve a nested failure while identifying the surrounding rule:

```mbt nocheck
let identifier = @parsec.Parser::satisfy("identifier", is_identifier)
  .label("identifier")
  .context("binding")
```

## Lookahead

`look_ahead` runs a parser without advancing its caller's input state.
`not_followed_by` succeeds only when its child parser fails at the current
offset. They are useful for token boundaries and keyword disambiguation.

```mbt nocheck
let keyword = @parsec.Parser::token('i', expected="i")
  .then_right(@parsec.Parser::token('f', expected="f"))
  .then_left(
    @parsec.Parser::satisfy("identifier continuation", is_identifier)
      .not_followed_by(expected="identifier continuation"),
  )
```

## Recursive Grammars

Use `delay` at recursive references so parser construction terminates before
the grammar is run:

```mbt nocheck
fn expression() -> @parsec.Parser[Char, Char] {
  @parsec.Parser::token('x', expected="x").or_else(
    @parsec.Parser::between(
      @parsec.Parser::token('(', expected="opening parenthesis"),
      @parsec.Parser::delay(() => expression()),
      @parsec.Parser::token(')', expected="closing parenthesis"),
    ),
  )
}

let parser = expression()
```

Keep protocol grammars in their owning packages. `parsec` supplies the parsing
mechanics; it intentionally does not define URI, JSON, CSV, or lexer policies.
