# Style examples (Bash 3.2 compatible)

## Comment contrast

Bad: narration of the next command.

```bash
# Check whether jq exists
command -v jq >/dev/null 2>&1 || exit 0
```

Good: rationale and a fail-open constraint.

```bash
# jq is optional; a missing parser must never block the user's work.
command -v jq >/dev/null 2>&1 || exit 0
```

## Whitespace contrast

Bad: an unexplained triple-blank-line run.

```bash
INPUT=$(cat 2>/dev/null || true)



CWD=$(extract_cwd "$INPUT")
```

Good: intentional phase separation. One blank line is a default rhythm, not a hard maximum.

```bash
INPUT=$(cat 2>/dev/null || true)

CWD=$(extract_cwd "$INPUT")

BR=$(current_branch "$CWD")
```

## Readable phases (pseudocode)

```bash
INPUT=$(cat 2>/dev/null || true)
CWD=$(extract_cwd "$INPUT")
TRANSCRIPT=$(extract_transcript "$INPUT")

CMD=$(extract_command "$INPUT")
BR=$(current_branch "$CWD")

is_ship_command "$CMD" || exit 0
is_protected_branch "$BR" || exit 0
review_was_recorded "$TRANSCRIPT" || block_commit
```
