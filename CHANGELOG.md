# Changelog

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
