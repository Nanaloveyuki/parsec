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
