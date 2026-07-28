# parsec

`parsec` is a token-generic parser-combinator library for MoonBit. It makes
small grammars composable without tying the library to a protocol, text
encoding, or input domain.

`Parser[T, A]` consumes an `Array[T]`: `T` is the input token and `A` is the
parsed value. The concrete type keeps composition type-safe within MoonBit's
current type system, without pretending to provide a language-level Monad
abstraction.

## Features

- Parse any `Array[T]`, including characters, bytes, integers, or domain tokens.
- Compose parsers with `map`, `flat_map`, `then`, `then_left`, and `then_right`.
- Match tokens with `item`, `satisfy`, and equality-based `token`.
- Build alternatives with `or_else`, `choice`, `attempt`, and `cut`.
- Repeat parsers with `optional`, `option`, `many`, `many1`, `count`,
  `repeat_0_to_n`, `sep_by`, and `sep_by1` without zero-consumption infinite
  loops.
- Compose homogeneous and heterogeneous sequences with `sequence`, `lift2`,
  and `apply`; use `ParserRef` for staged recursive grammars.
- Build delimited, recursive, and lookahead grammars with `between`, `delay`,
  `look_ahead`, and `not_followed_by`.
- Add user-facing expectations with `label` and nested grammar context with
  `context`.
- Use optional feature packages for character-oriented factories and persistent
  pull-stream input without changing the root parser's array state.

## Install

```sh
moon add Nanaloveyuki/parsec
```

Import the root package:

```mbt nocheck
import {
  "Nanaloveyuki/parsec",
}
```

Optional packages have separate imports and parser state:

```mbt nocheck
import {
  "Nanaloveyuki/parsec" @parsec,
  "Nanaloveyuki/parsec/char" @char,
  "Nanaloveyuki/parsec/lazy" @lazy,
  "Nanaloveyuki/parsec/lexer" @lexer,
}
```

- `@char` creates character parsers for the root package's `Array[Char]`
  input model.
- `@lazy` provides an independent `Stream[T]` parser for persistent pull
  streams. Its parsers cannot be mixed with root parsers.
- `@lexer` maps character offsets to source positions and spans for tokenizers
  and parse diagnostics. It does not own parser state.

## Use

Build token parsers and finish a complete grammar with `parse_all`:

```mbt nocheck
let parser = @parsec.Parser::between(
  @parsec.Parser::token('(', expected="opening parenthesis"),
  @parsec.Parser::token('x', expected="x"),
  @parsec.Parser::token(')', expected="closing parenthesis"),
)

match parser.parse_all(['(', 'x', ')']) {
  Ok(value) => println(value)
  Err(error) => println("parse failed at \{error.offset()}")
}
```

`or_else` retries only when the first branch failed without consuming input.
This makes a consumed prefix a commitment rather than silently discarding it.

See [the usage guide](docs/usage.md) for grammar composition, error handling,
recursive parsers, and feature-package boundaries.

## Documentation

- [Usage guide](docs/usage.md)
- [Development guide](docs/development.md)
- [Contributing](CONTRIBUTING.md)
- [Release guide](docs/releasing.md)
