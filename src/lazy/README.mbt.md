# Nanaloveyuki/parsec/lazy

`lazy` is an independent parser package for persistent pull streams. It owns
its `Stream`, `State`, parser reply state, and parser type; it does not share
state with the eager root package.

Use `Stream::from_array` or `Stream::from_string` for in-memory input. Custom
streams passed to `Stream::from_fn` must be persistent: reading the same stream
again must return the same token and tail, because `attempt` and alternatives
can replay input.

```mbt check
///|
test "parse a lazy character stream" {
  let parser = Parser::token('o', expected="o").then_right(
    Parser::token('k', expected="k"),
  )
  match parser.parse_all(Stream::from_string("ok")) {
    Ok(value) => inspect(value, content="k")
    Err(_) => fail("expected lazy input")
  }
}
```

For destructive or one-shot sources, buffer or memoize input before exposing
it as a `Stream`. This package does not yet provide I/O buffering or stream
memoization.
