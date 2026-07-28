# Nanaloveyuki/parsec

`parsec` parses `Array[T]` inputs. A `Parser[T, A]` consumes zero or more
tokens of type `T` and either produces `A` or a `ParseError` with an input
offset.

## Token parsers

Use `token` for equality-based matching and finish a complete grammar with
`parse_all`.

```mbt check
///|
test "parse a delimited token" {
  let parser = Parser::between(
    Parser::token('(', expected="opening parenthesis"),
    Parser::token('x', expected="x"),
    Parser::token(')', expected="closing parenthesis"),
  )
  match parser.parse_all(['(', 'x', ')']) {
    Ok(value) => inspect(value, content="x")
    Err(_) => fail("expected a complete parse")
  }
}
```

## Composition

`map` transforms a successful value. `flat_map` makes the next parser depend
on that value. `or_else` retries its fallback only when the first parser failed
without consuming input; this prevents silently discarding a committed prefix.

`many` and `many1` collect repetitions. A parser that succeeds without
consuming input is rejected by `many`, preventing an infinite loop.

`position()` observes the current token offset without consuming input. Feature
packages use it when a parsed value must retain an exact source offset while
the root execution state remains private.

`count(n)` parses exactly `n` values, while `repeat_0_to_n(n)` parses at most
`n`. `sep_by1` requires a non-empty separated list; `option(default)` keeps a
plain result type when an unconsumed failure should select a default value.

`sequence`, `lift2`, and `apply` provide applicative composition. For recursive
grammars assembled in stages, create a `ParserRef[T, A]`, build parsers with
`parser()`, then call `set(...)` before parsing. Running an unbound reference
returns `UnboundReference`.
