# Changelog

## 0.1.4 - 2026-09-25

### Fixed

- Qualify black-box tests and package examples for MoonBit warning 25
  (`test_unqualified_package`) on toolchain 0.1.20260920.

## 0.1.3 - 2026-08-09

### Fixed

- Regenerated package interfaces with the current MoonBit toolchain so CI's
  generated-interface verification remains clean after the toolchain update.

## 0.1.2 - 2026-07-28

### Added

- `Nanaloveyuki/parsec/json`, a strict RFC 8259 parser with duplicate-key
  detection, Unicode escape validation, source offsets, and resource limits.
- Non-consuming `Parser::position()` for feature packages that need parser
  offsets without accessing private execution state.

## 0.1.1 - 2026-07-28

### Added

- Advanced root combinators: `sequence`, `lift2`, `apply`, `count`,
  `repeat_0_to_n`, `sep_by1`, `option`, and staged recursive `ParserRef`.
- `Nanaloveyuki/parsec/char` character factories for whitespace, identifiers,
  integers, and whitespace-consuming symbols.
- `Nanaloveyuki/parsec/lazy` independent persistent pull-stream parsers.
- `Nanaloveyuki/parsec/lexer` source positions, spans, and located values.

## 0.1.0 - 2026-07-28

### Added

- Token-generic `Parser[T, A]` with sequencing, committed choice, repetition,
  delimiters, recursion support, and offset-aware parse errors.

### Changed

- Standardized on `flat_map`, `many1`, and `eof` before the first release.

### Fixed

- Preserve furthest retryable parser errors and merge same-offset expectations.
- Keep `cut` committed when wrapped by `attempt`.
- Preserve token expectations at end of input.
