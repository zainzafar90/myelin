# Code-quality preferences

- Preserve intentional whitespace (intentional blank lines, useful section spacing and visual rhythm) when they improve natural reading flow.
- Blank-line spacing follows the `code-spacing` skill (after imports; around functions, classes, types, exports and block statements; after declaration groups; before return). A lint rule enforces it wherever the repo's linter supports it (e.g. `@stylistic/padding-line-between-statements`); otherwise it is checked at review. Bash files here have no linter: review only, do not reformat existing files.
- Remove only accidental whitespace: trailing spaces, inconsistent indentation, or unexplained runs of empty lines.
- Comments explain rationale, constraints, invariants, or workarounds—not obvious code or change history.
- Prefer readable phases, named helpers, and guard clauses over compressed command chains.
- Keep hooks Bash 3.2-compatible, pure Bash, fail-open, and easy to test.
