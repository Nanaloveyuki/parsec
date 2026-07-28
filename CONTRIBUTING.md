# Contributing to parsec

Read [the development guide](docs/development.md) before changing the library.
It defines the parser semantics, package boundaries, local setup, and required
validation.

Small bug fixes, tests, and documentation updates can be proposed directly.
Open an issue or discussion before introducing a new public abstraction,
changing backtracking semantics, or adding a protocol-specific grammar.

## Pull Requests

- Branch from current `main` and keep each pull request focused.
- Describe the user-visible behavior and the validation actually run.
- Include tests and documentation for observable behavior changes.
- Include the generated `pkg.generated.mbti` diff for intentional public API
  changes.
- Wait for all required GitHub Actions checks and at least one maintainer
  approval before merge.

