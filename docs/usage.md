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
| `eof()` | Succeeds only at end of input. |
| `position()` | Returns the current offset without consuming input. |
| `map(f)` | Transforms a successful result. |
| `flat_map(f)` | Chooses the next parser from the previous result. |
| `then(next)` | Sequences two parsers and keeps both results as a pair. |
| `then_right(next)` | Sequences two parsers and keeps the right result. |
| `then_left(next)` | Sequences two parsers and keeps the left result. |
| `replace(value)` / `ignore()` | Replaces a parsed value or discards it as `Unit`. |
| `optional()` | Produces `Some(value)` or `None`. |
| `option(default)` | Uses a default after an unconsumed failure. |
| `many()` / `many1()` | Collects zero-or-more / one-or-more values. |
| `count(n)` / `repeat_0_to_n(n)` | Parses exactly / at most `n` values. |
| `sep_by(separator)` / `sep_by1(separator)` | Parses zero-or-more / one-or-more separated values. |
| `between(open, parser, close)` | Parses a delimited value. |
| `delay(factory)` | Delays parser construction for recursive grammars. |
| `sequence(parsers)` | Runs homogeneous parsers in order and collects values. |
| `lift2(left, right, f)` / `apply(argument)` | Combines heterogeneous parser results. |
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
the next alternative run after a consumed failure. `Parser::cut()` is a hard
commit: `attempt()` does not revoke it. Use a cut in a sequence to commit even
when the parser has not consumed a token yet:

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
- `ExpectedAny` combines labels from alternatives that fail at the same offset.
- `EmptyMatchInMany` identifies a non-consuming repetition.
- `EmptyChoice` identifies an empty `choice` list.
- `UnboundReference` identifies a `ParserRef` that was parsed before `set`.
- `NotFollowedBy` identifies forbidden lookahead.
- `Context` wraps a nested parser failure with a grammar label.

Errors use token offsets, not line and column numbers. Applications that parse
text can map offsets to source locations in their own input layer.

When retryable alternatives fail, `or_else` and `choice` preserve the error at
the furthest offset. This keeps a deeper expectation useful after `attempt()`
has made a branch eligible for fallback.

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

Use `ParserRef` when mutually recursive parsers need to be assembled in
separate steps. Bind the reference before its parser is run:

```mbt nocheck
let expression : @parsec.ParserRef[Char, Char] = @parsec.ParserRef::new()
let nested = expression.parser()
expression.set(
  @parsec.Parser::token('x', expected="x").or_else(
    @parsec.Parser::between(
      @parsec.Parser::token('(', expected="opening parenthesis"),
      nested,
      @parsec.Parser::token(')', expected="closing parenthesis"),
    ),
  ),
)
```

Keep protocol grammars in their owning packages. The root `parsec` package
supplies parsing mechanics; protocol and format packages define their own
syntax and policies.

## Feature Packages

The root package is the eager `Array[T]` parser. Optional packages deliberately
use separate types where their input model needs different state.

### Character Factories

`Nanaloveyuki/parsec/char` returns root parsers, so it composes directly with
`@parsec.Parser[Char, A]`:

```mbt nocheck
import {
  "Nanaloveyuki/parsec" @parsec,
  "Nanaloveyuki/parsec/char" @char,
}

let identifier = @char.identifier()
match identifier.parse_all(['_', '4']) {
  Ok(value) => println(value)
  Err(error) => println("parse failed at \{error.offset()}")
}
```

### Persistent Pull Streams

`Nanaloveyuki/parsec/lazy` is a separate parser implementation for persistent
pull streams. Use it when `Array[T]` is not the appropriate input ownership
model. Its `Stream[T]`, `State[T]`, and `Parser[T, A]` do not interoperate with
the root package's types.

```mbt nocheck
import {
  "Nanaloveyuki/parsec/lazy" @lazy,
}

let parser = @lazy.Parser::token('o', expected="o").then_right(
  @lazy.Parser::token('k', expected="k"),
)
match parser.parse_all(@lazy.Stream::from_string("ok")) {
  Ok(value) => println(value)
  Err(error) => println("parse failed at \{error.offset()}")
}
```

Custom streams created with `Stream::from_fn` must be persistent: repeated
reads of the same stream must return the same token and tail. This is required
for `attempt` and alternatives to replay input. One-shot or destructive sources
must be buffered or memoized by the caller for now.

### Source Locations

`Nanaloveyuki/parsec/lexer` turns character offsets into one-based source
positions and half-open spans. It is a lexical-data package, not a second parser
implementation, so it can map root parse errors without sharing root state.

```mbt nocheck
import {
  "Nanaloveyuki/parsec" @parsec,
  "Nanaloveyuki/parsec/lexer" @lexer,
}

let source = @lexer.Source::new("ac")
let parser = @parsec.Parser::token('a', expected="a").then_right(
  @parsec.Parser::token('b', expected="b"),
)
match parser.parse(['a', 'c']) {
  Err(error) =>
    match source.error_position(error) {
      Some(position) => println("line \{position.line()}, column \{position.column()}")
      None => ()
    }
  Ok(_) => ()
}
```

`Source::span(start, end)` creates a half-open `[start, end)` range, and
`Located[T]` pairs a token or AST-adjacent value with such a span. Recovery,
trivia ownership, CST construction, and AST lowering intentionally remain
outside this package.

### Strict JSON

`Nanaloveyuki/parsec/json` is a strict RFC 8259 parser for configuration and
other bounded documents. It accepts only JSON whitespace, preserves number
source text, rejects duplicate object keys, validates Unicode surrogate pairs,
and accepts `JsonLimits` for input and nesting limits.

```mbt nocheck
import {
  "Nanaloveyuki/parsec/json" @json,
}

match @json.parse("{\"enabled\":true,\"retries\":3}") {
  Ok(@json.Object(members~)) => println(members.length())
  Err(error) => println("parse failed at \{error.offset()}")
  _ => ()
}
```

This package deliberately does not depend on JSON5, JSON-RPC, JSONPath, or
JSONL packages. JSON5 is a different, permissive syntax; JSON-RPC and JSONL
are protocol or framing layers; JSONPath queries a parsed tree. Applications
may use them alongside `parsec/json` through explicit adapters.
