---
name: coding-core
description: >-
  Applies shared coding and change-safety standards when implementing, refactoring,
  debugging, or reviewing code in any language. Use for code changes, architecture
  cleanup, business-rule preservation, and code review. Covers readable control
  flow, cohesive responsibilities, explicit contracts, safe failures, and behavior
  tests. Combine with api-engineering for server work, code-spacing for blank lines, and frontend-engineering for
  UI work. Not a framework migration or a mandate to reorganize the repository.
metadata:
  version: "1.1.0"
---

# Coding core

Leave code easy to traverse, vertically scannable, explicit about its rules, and safe to modify.
Prefer boring, concrete code over cleverness and architectural ceremony.

This skill is the single home for shared numbers and naming rules. Language and concern skills
(`typescript-standards`, `react-craft`, `api-engineering`, `frontend-engineering`) add deltas and
must not restate or contradict them.

## Apply proportionately

Follow the host's instruction hierarchy, then documented repository conventions, then these defaults.
A stack reference never authorizes a dependency migration, weaker security, or a public behavior change.
Surface a material conflict instead of silently picking a new contract.

Priority: correctness and preserved business rules, then readability, ownership, changeability,
testability, consistency, and abstraction last.

Scope a small fix to the feature and its callers, not a repository audit. For review-only requests,
report findings without editing.

## Before changing code

1. Read repository instructions, the touched package's manifest, lockfile, scripts, nearby code, and tests.
2. Name the behavior being changed, its callers, and the rules that must stay true. Keep intended behavior
   changes separate from refactoring. Do not infer a business rule from one convenient example.
3. Pick the smallest coherent change and the tests that would catch a broken rule.
4. Load only the matching language reference: [Python](references/python.md),
   [TypeScript](references/typescript.md) (server or client). For other languages, keep these principles
   and follow the repository plus version-appropriate official docs.

## Readability

- Control flow is always multiline. Use braces where the language has them. Never put an `if`, loop body,
  or guard `return` on the same line as its condition.
- Separate independent logical steps with whitespace. Make the success path easy to find.
- Prefer guard clauses and shallow nesting. Two levels is a review signal, not a mechanical limit.
- Name business decisions, not every expression: `canCancelOrder` over a repeated compound condition,
  `calculateRefund` over `processData`.
- Never nest ternaries. Use explicit branches for business logic; a simple binary presentation choice is fine.
- Extract a function when its name explains a real concept. Vague `handle`, `process`, `finalize` helpers
  that only shorten the caller are worse than the inline code.

## Responsibility and placement

A function is one conceptual operation; a file has one primary responsibility. Keep feature rules, types,
helpers, and components with their feature. Share only genuinely generic code.

Split when ownership or reasons to change diverge, not by syntax category. A cohesive module may hold its
constants, types, parsing, validation, and payload construction together.

No catch-all `utils`, `helpers`, `common`, `misc`, or `manager` modules or folders. A narrowly named shared
module (`format-currency.ts`) is fine.

No empty architecture: generic base services, speculative interfaces, deep inheritance, registries, or event
buses where ordinary functions work. A little duplication beats the wrong shared abstraction.

Entry points stay focused on their boundary. Important decisions live in explicitly owned, directly testable
code, not in handlers, serializers, rendering, or repeated conditions.

## Contracts, dependencies, and failures

Make important input/output contracts explicit. Validate untrusted input at its boundary; static types do not
validate runtime values. Preserve distinctions such as absent, empty, invalid, zero, and failed. Preserve units
and time-zone semantics. For exact money, use integer minor units or a decimal type with an explicit rounding policy.

Dependencies and resource ownership are visible. Prefer ordinary construction or the framework's mechanism over
hidden mutable globals or a new DI container. Load and validate configuration in one central module; fail early
on missing required config. Configuration delivered to a client is never secret.

Distinguish expected domain rejection from programming and infrastructure failure. Catch only to recover,
translate, add context, or report. Never disguise a failure as success, an empty dataset, or a valid default.

Never commit secrets, log credentials, interpolate untrusted input into SQL or shell commands, evaluate
untrusted input as code, or treat client-side checks as authorization. Never weaken validation, tests, or
type/lint checks to turn a change green.

## Files, names, and limits

- **200 lines per file, hard limit**, every language and file type. Split by real responsibility before
  crossing it. Language skills may tighten this, never loosen it.
- One concept per file. File names are kebab-case and carry the domain: `billing-checkout.service.ts`,
  not `service.ts`.
- Directories group by domain or feature, not by type. About 15 files per directory before splitting into
  subdirectories; do not fragment one concept across tiny files.
- New code follows these rules. Do not relocate existing files unless the task is a restructure.
- Intention-revealing names, one vocabulary per concept, name length proportional to scope.
- Prefer pure functions; keep I/O and mutation at the edges. No global mutable state outside one named owner.
- Rule of three: copy once is fine, extract on the third occurrence. YAGNI beats DRY until then.
- Package manager: pnpm for new JavaScript/TypeScript repositories. In an existing repository, use the one its
  lockfile shows; never switch tools as a side effect.
- Blank-line spacing follows the `code-spacing` skill and is enforced by a lint rule wherever the repo's linter
  supports it (for example `@stylistic/padding-line-between-statements`); otherwise it is checked at review.
  Preserve intentional whitespace and section spacing; remove only accidental runs.
  Examples: [style examples](references/style-examples.md).

## Comments

Comments explain a non-obvious rationale or constraint, and only when removing the comment would let someone
break it. They never narrate the next line or restate change history ("added X", "now handles Y"); git holds
history. Prefer a better name over an explanatory comment.

- Block style: `/* */` in languages that have it; the native line comment elsewhere (`#` in shell and Python).
- 8 words or fewer, naming the constraint. Too long: `/* we dedupe here because the provider can send
  the same webhook twice */`. Right: `/* webhooks retry; dedupe by event id */`.
- Keep public-contract docs and legally required notices. Never add docstrings mechanically.

For an important invariant, keep lightweight traceability in the repository's existing convention:

```text
Rule: stock cannot become negative.
Owner: inventory reservation operation.
Protection: conditional update plus a database constraint.
Tests: rejects overselling; concurrent reservations cannot oversell.
```

## Change and verification workflow

1. Confirm or add behavior tests around the affected rule before risky restructuring.
2. Make the smallest improvement that solves the actual problem. Preserve public APIs, payloads, permissions,
   defaults, navigation, and error behavior unless the change is intended.
3. Keep mechanical moves, structural cleanup, and behavior changes separately reviewable.
4. Remove dead code your change created after checking callers. Keep compatibility code only for a named consumer.
5. Run the repository's real formatter, linter, type checks, tests, and build. Discover the commands; never assume them.
6. Review the diff for unexpected files, behavior changes, suppressions, weakened tests, and stale docs.

Test observable behavior and rules, not private structure. A mock does not prove database, transaction, or
concurrency behavior. Never claim an unrun check passed; report what was not run.

## Completion check

Does the main operation read downward? Are decisions named? Is every file under 200 lines? Are contracts,
ownership, and failures explicit? Could a critical rule break while every test stays green? Did the change
stay in scope?

For implementation, report the change, intended behavior differences, checks actually run, and unverified risk.
For review, lead with actionable findings and their consequence; separate demonstrated bugs from preferences.
