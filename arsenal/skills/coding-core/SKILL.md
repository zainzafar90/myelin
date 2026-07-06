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
  version: "1.0.0"
---

# Coding core

Leave code easy to traverse, vertically scannable, explicit about its rules, and safe to modify.
Prefer boring, concrete code over cleverness and architectural ceremony.

## Apply proportionately

Use the host's instruction hierarchy. Within these standards, follow documented repository contracts and
conventions over generic defaults. A stack reference does not authorize a dependency migration, weaken
security, or change public behavior. Surface a material conflict rather than silently choosing a new contract.

Correctness and preserved business rules come first, then readability, clear ownership, safe changeability,
testability, consistency, and finally abstraction when justified.

For a small fix, inspect the relevant feature and its callers; do not turn it into a repository-wide audit.
For review-only requests, report findings without editing files unless edits are requested.

## Before changing code

1. Read applicable repository instructions and inspect the touched package's manifests, lockfiles, scripts,
   nearby code, and tests. Determine the actual language, framework, runtime, and established conventions.
2. Identify the behavior being changed, its callers, and the rules that must remain true. Separate intended
   behavior changes from refactoring. Do not infer important business rules solely from a convenient example.
3. Identify the smallest coherent change and the tests that would catch a broken rule.
4. Read only applicable references. Python code: [Python](references/python.md).
   TypeScript code, whether server or client: [TypeScript](references/typescript.md).
   Do not load a language reference merely because that language exists elsewhere in the monorepo.

The API and frontend skills add concern-specific rules; they do not replace this core. Load them explicitly
when applicable through the repository's instruction snippet or the host's skill mechanism. For another
language, retain the generic principles and consult that repository's conventions and version-appropriate
official documentation rather than inventing a framework profile.

## Readability

- Write control flow in proper multiline blocks; use braces in languages with braced statement bodies.
  Do not compress an `if`, loop body, or several independent statements onto one line.
- Separate independent logical operations with whitespace. Make the successful path easy to find.
- Prefer guard clauses and shallow nesting. Roughly two levels is a review signal, not a mechanical limit
  or an excuse to scatter one operation across tiny functions.
- Name meaningful business decisions, not every trivial expression. Prefer `can_cancel_order` over a
  repeated compound condition and `calculate_refund` over `process_data`.
- Avoid nested ternary expressions. Use explicit branches for business logic; a simple binary presentation
  choice is acceptable. This rule concerns executable expressions, not language-level type syntax.
- Extract an operation when its name explains a real concept. Do not replace readable code with vague
  `handle`, `process`, or `finalize` helpers just to shorten the caller.
- Do not optimize for minimum line count. Extra lines should improve comprehension, not introduce ceremony.

## Responsibility and placement

A function represents a conceptual operation. A file has a coherent primary responsibility. Keep
feature-specific rules, types, helpers, and components with that feature; share only genuinely generic code.

Do not split by arbitrary line limits or by syntax category. A cohesive module may contain its related
constants, types, parsing, validation, and payload construction. Split when ownership or reasons to change
actually diverge. A 300-line cohesive file can be healthier than seven meaningless files.

Avoid catch-all `utils`, `helpers`, `common`, `manager`, and root-level dumping grounds. Narrowly scoped
shared modules are fine. Use names that explain ownership and purpose.

Do not create empty architecture, generic base services, speculative interfaces, deep inheritance,
framework-like registries, or event buses where ordinary functions are sufficient. A little duplication is
preferable to the wrong shared abstraction. Do not force a class, repository, or service layer into simple code.

Keep entry points focused on their boundary responsibility. Keep important decisions in explicitly owned,
directly testable code, not hidden in transport handlers, serializers, rendering, or repeated conditions.
Framework entry-point conventions may differ; the API and frontend skills explain the relevant distinction.

## Contracts, dependencies, and failures

Make important input/output contracts explicit. Validate untrusted input at the relevant boundary; static
types alone do not validate runtime values. Do not multiply representations unless their responsibilities differ.
Preserve meaningful distinctions such as absent, empty, invalid, zero, and failed.
Preserve units and time-zone/offset semantics for real instants. When exact currency arithmetic matters,
use integer minor units or an appropriate decimal representation with an explicit rounding policy.

Dependencies and resource ownership must be visible. Prefer ordinary construction or the framework's
established mechanism over hidden mutable globals or a new dependency-injection container. Load and validate
configuration in an appropriate central boundary; fail early for required missing configuration. Never treat
configuration delivered to a client as a secret.

Distinguish expected domain rejection from programming and infrastructure failure. Catch only to recover,
translate, add useful context, or reliably report. A top-level reporting boundary may catch broadly, but must
preserve failure semantics. Never disguise a failed operation as success, an empty dataset, or a valid default.

Do not commit secrets, log credentials indiscriminately, interpolate untrusted input into SQL or shell
commands, evaluate untrusted input as application code, or treat client-side checks as authoritative authorization. Use the actual
trusted enforcement boundary. Do not weaken validation, tests, or type/lint checks to make a change appear green.

## Files, names, and spacing

- One concept per file. File names carry the domain: `billing-checkout.service.ts`, not `service.ts`;
  never `utils`, `helpers`, `misc`. Directory structure is explicit by domain/feature, not by type.
- Soft limit: about 15 files per directory before splitting into subdirectories; do not fragment one
  concept across tiny files. Hard limit: 400 lines per file unless a language skill tightens it.
- New code follows domain naming and feature grouping. Do not relocate existing files unless the task
  is a restructure; frontend-engineering does not impose a universal directory tree.
- Intention-revealing names, one vocabulary per concept, name length proportional to scope.
- Prefer pure functions; keep I/O and mutation at the edges. No global mutable state outside one named
  owner; centralize configuration in one module.
- Rule of three: copy once is fine, extract on the third. Build for today's requirement; YAGNI wins
  over DRY until the third occurrence.
- Blank-line spacing follows the `code-spacing` skill and is enforced by a lint rule wherever the
  repo's linter supports it (for example `@stylistic/padding-line-between-statements`); otherwise it is
  checked at review. Preserve intentional whitespace and section spacing; remove only accidental runs.
  Examples: [style examples](references/style-examples.md).

## Comments and traceability

**Additional house rule:** comments should explain a non-obvious reason, invariant, tradeoff, or external
constraint—not narrate the next line or describe the edit history. Delete change-narration comments
("added X", "now handles Y"); comments explain rationale or constraints, and git holds history. Prefer a better name over an explanatory
comment for an obvious operation. Preserve useful rationale, public-contract documentation, and legally
required notices. Do not add comment blocks or docstrings mechanically to every function.

For important invariants, keep lightweight traceability in the repository's existing convention:

```text
Rule: stock cannot become negative.
Owner: inventory reservation operation.
Persistence protection: conditional update plus a database constraint, where applicable.
Tests: rejects overselling; concurrent reservations cannot oversell.
```

Do not invent a documentation framework or sidecar system. Add documentation only where it protects behavior
or makes a non-obvious decision discoverable; update it when the corresponding rule changes.

## Change and verification workflow

1. Confirm or add behavior tests around the affected rule before risky restructuring.
2. Make the smallest architectural improvement that solves the actual problem. Preserve public APIs,
   payloads, permissions, defaults, navigation, and error behavior unless their change is intentional.
3. Keep mechanical moves/formatting, structural cleanup, and behavioral changes separately reviewable where
   practical. Avoid unrelated rewrites and opportunistic dependency/tool replacements.
4. Remove dead code introduced by the change after checking callers. Keep compatibility code only when a
   real consumer needs it; explain that need rather than leaving temporary layers indefinitely.
5. Run the repository's relevant formatter, linter, type checks, behavior tests, and build/startup checks.
   Discover actual commands; do not assume the examples in a reference are configured. Respect tool permissions.
6. Review the diff for unexpected files, behavior changes, suppressions, weakened tests, and stale documentation.

Test observable behavior and important rules rather than private implementation structure. Use integration
tests for infrastructure guarantees; a mock does not prove database, transaction, or concurrency behavior.
Scale verification to risk. Never claim an unrun check passed; report unavailable checks and remaining uncertainty.

## Completion check

Can the main operation be understood by reading downward? Are important decisions named? Are responsibilities
cohesive without unnecessary files? Are contracts, ownership, and failure behavior explicit? Could a critical
rule break while every relevant test stays green? Did the change stay within scope?

For implementation, summarize the change, intentional behavior differences, checks actually run, and any
unverified risk. For review, lead with actionable findings and their consequence; distinguish demonstrated
bugs from preferences. Do not produce a long compliance checklist for a trivial change.
