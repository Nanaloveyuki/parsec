# Developing parsec

## Scope

`parsec` is a general token parser library. Keep protocol grammars, text
decoding, source-location policy, and lexer definitions in consumer packages.
The public package is `Nanaloveyuki/parsec`; all user-facing parser types and
combinators belong under `src/`.

The key behavioral rules are part of the public contract:

- `parse_all` must reject trailing input.
- `or_else` may backtrack only when the first branch consumed nothing.
- `attempt` can restore consumption but cannot revoke a `cut` commitment.
- `many` must reject a successful child parser that consumed nothing.
- `ParseError` offsets are token offsets.
- Retryable alternatives retain the furthest failure; same-offset expectations
  are merged as `ExpectedAny`.

## Local Setup

Install the current MoonBit toolchain. This project has no third-party
dependencies or native build prerequisites.

From the repository root, update the local registry and dependency cache:

```powershell
moon update
moon install
```

## Layout

```text
src/
  types.mbt          Public parser state and errors
  core.mbt           Construction, execution, and primitive token parsers
  transform.mbt      Value transformation and sequencing
  choice.mbt         Alternatives, retry, commitment, and error decoration
  repetition.mbt     Optional, repeated, separated, and delimited parsers
  lookahead.mbt      Positive and negative lookahead
  *_test.mbt         Behavior tests
  README.mbt.md      Package documentation and checked examples
```

MoonBit packages are directory-based. Files inside `src/` are one package;
split files by responsibility, not by an assumed namespace.

`Reply[T, A]` is package-private. It records consumed and committed state so
`attempt`, `cut`, `or_else`, and repetition can make correct control-flow
decisions. Keep that representation private; external callers execute parsers
through `run`, `parse`, or `parse_all`.

## Validation

Run the narrowest relevant test while iterating, then run the full matrix
before review:

```powershell
moon fmt --check
moon check --target all
moon test --target all
moon info
git diff --check
```

`moon info` regenerates `src/pkg.generated.mbti`. Never edit that file by
hand. Review and commit its diff whenever the public API intentionally changes.

## Change Workflow

Create a focused branch from current `main`. Keep public API changes small,
add a behavior test for each semantic change, and update package and user
documentation when observable behavior changes.

Do not commit `_build`, `.mooncakes`, local tool caches, generated temporary
files, or machine-specific paths. The GitHub workflow is the authoritative
cross-platform gate and must pass before merge.
