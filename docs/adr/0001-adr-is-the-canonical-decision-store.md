---
status: accepted
---

# `docs/adr/` is the canonical decision store

Three mechanisms in the arsenal record architectural decisions:

- `domain-modeling`'s `docs/adr/` (committed, standard format)
- loopkit's `decision-record` (destination unspecified)
- myelin Phase 3's planned `decision` graph nodes (`.knowledge/decisions/`)

Three stores for one fact is how records rot. Nothing reads all three, so
decisions silently duplicate or vanish depending on which skill happened to
fire.

## Decision

`docs/adr/NNNN-slug.md` (the `domain-modeling` format) is canonical.

- When Phase 3 builds `decision` nodes, they are pointers or summaries that link
  to an ADR file. They are never a parallel store.
- loopkit's `decision-record` skill, if it writes elsewhere, should be pointed
  at `docs/adr/`, or treated as a prompt-only skill that produces ADR-formatted
  output.
- ADRs stay in git (per repo, committed). `.knowledge/` ledgers are gitignored
  state.
