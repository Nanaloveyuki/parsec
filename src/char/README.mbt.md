# Nanaloveyuki/parsec/char

Character parser factories for the eager `@parsec.Parser[Char, A]` input
model. The factories use Unicode whitespace, while `letter`, `alpha_num`, and
`identifier` intentionally use ASCII rules. `symbol` consumes trailing
whitespace, so it can be used directly in a token parser.

```mbt check
///|
test "parse a binding" {
  let binding = @char.identifier()
    .then_left(@char.spaces())
    .then_left(@char.symbol("="))
    .then_left(@char.integer())
  match
    binding.parse_all(['a', 'n', 's', 'w', 'e', 'r', ' ', '=', ' ', '4', '2']) {
    Ok(value) => inspect(value, content="answer")
    Err(_) => fail("expected binding")
  }
}
```
