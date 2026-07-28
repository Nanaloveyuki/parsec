# Nanaloveyuki/parsec/json

`json` is a strict RFC 8259 parser. It rejects duplicate object keys, preserves
number source text, accepts only JSON whitespace, and exposes configurable
resource limits. It does not depend on JSON5, JSON-RPC, JSONPath, or JSONL.

```mbt check
///|
test "parse strict JSON" {
  match parse("{\"enabled\":true,\"retries\":3}") {
    Ok(Object(members~)) => inspect(members.length(), content="2")
    Err(_) => fail("expected JSON object")
    _ => fail("expected JSON object")
  }
}
```

Use `JsonError::position` with `@lexer.Source` to map an error offset to a
one-based line and column. Conversion to another JSON representation, JSONL
framing, JSONPath queries, JSON-RPC, and JSON5 remain separate packages.
