# Myelin Canon — how work routes (v1)

## Moments (these are mandatory, not suggestions)

| Moment | Trigger | Route |
|---|---|---|
| START | new feature / "build X" / behavior change | superpowers:brainstorming → grilling (stress-test the design) → superpowers:writing-plans → register plan in `.knowledge/state/plans.md` → Codex brief; too big/foggy for one session → wayfinder |
| STUCK | bug, error, failing test, "broken" | superpowers:systematic-debugging (perf → diagnose) |
| SHIP | done-claim, branch finish, commit/push | superpowers:verification-before-completion (browser-facing diff → frontend-verify-standards) → /pr-review or /simplify → /pr-description on branch finish → reconcile ledger (close plans, punts → debt.md) |
| HANDOFF | implementation delegated | codex:rescue with a filled brief (goal, files, invariants, acceptance, stop conditions) |

Escape hatch: user says "quick" or "raw" → skip soft routing, answer directly.
Punt rule: any "skip it for now" → add a `## ` entry to `.knowledge/state/debt.md` immediately (template at top of file; reuse a matching id instead of duplicating).
Debt loop: at task start check the injected open debt for related items; at finish mark touched items `- status: closed` + `- resolution: <date — reason — evidence>` (no evidence → stays open). A deferral never satisfies a required acceptance criterion.

## Domain shortlist (reference, not routing — fire from file context)

- Standards (any language, load at write AND review): coding-core base; api-engineering (server/backend), frontend-engineering (UI), code-spacing (blank lines, lint-enforced where possible); <lang>-standards extends
- React/TS: typescript-standards, react-craft, react-state-management; test data → migrate-to-shoehorn
- Swift/macOS: swiftui-expert, macos-patterns, macos-swiftui-gotchas
- UI: ui (explore) / frontend-design (build) / critique + polish (review); taste = project `.knowledge/state/DESIGN.md`
- UI done-claim: frontend-verify-standards — run app → /expect → console clean → CWV → embed/dark/mobile checks; no partial hand-backs
- Architecture: codebase-design (deep-module vocabulary); audits → improve; competing plans (Codex vs Claude) → plan-arbiter
- Regression/structure (loopkit): bisect-regression ("which commit broke this"), write-failing-test-first (every bug fix), reduce-nesting, kill-dead-code
- Security (loopkit): secret-scan, owasp-review, authz-check, input-validation, sql-review — fire on auth/input/query diffs
- DB (loopkit): migration-writer, schema-diff — fire on schema changes

## Project state

If `.knowledge/INDEX.md` exists in cwd, it is authoritative for: active plans,
debt register, review status, design constitution. Read it before assuming
project context. Record state changes at SHIP, not "later".

## Empty lanes

SEO: none installed. (Add via find-skills when needed.)
