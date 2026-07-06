---
name: typescript-standards
description: Use when writing, reviewing, or refactoring TypeScript/React code — enforces structural standards: file size, test-first, module boundaries.
---

# TypeScript/React Structural Standards

Layers on top of `coding-core` (universal base: file/dir limits, pure
functions, comment discipline, no globals) — read that first; this file holds
only the TypeScript/React deltas.

Prescriptive, checkable rules. If a rule and existing code conflict, flag it — don't silently follow the wrong pattern.

## 1. File & module limits
*Distills: Google TypeScript Style Guide (file organization, one concept per file)*

- One exported concept per file (component, hook, or module) — no grab-bag utility dumps.
- Group by feature/domain, not by type (`features/checkout/`, not `components/` + `hooks/` + `utils/` at root).
- No circular imports between modules — if A imports B, B must not import A.
- Barrel files (`index.ts`) only re-export; no logic inside them.
- **House rule (hard limit):** source files ≤400 lines. Split before crossing it — extract a hook, sub-component, or module. Do not wait for "a natural point."

## 2. Types discipline
*Distills: TypeScript Handbook "Do's and Don'ts"*

- Prefer `interface` for object shapes that may be extended; `type` for unions, intersections, tuples.
- No `any` — use `unknown` and narrow, or generics. `any` requires an inline justification comment if unavoidable.
- Don't add unnecessary generics or overloads when a union type suffices.
- Use discriminated unions for state/variant modeling over boolean flag soup (`{status: 'loading'|'error'|'success'}`, not three booleans).
- Export types next to the code that produces them; don't centralize all types in one giant `types.ts` per package.
- Function signatures: parameter types explicit, return type inferred unless the function is exported (then annotate).

## 3. State & boundaries
*Distills: React docs "Thinking in React" + community consensus on server/client state separation*

- Container/presentation split: data-fetching and state logic in a parent/hook, rendering in a dumb child.
- Props drilling beyond 2 levels signals a missing boundary — lift state, use composition, or context.
- **House rule:** server state (fetched/cached data) and client state (UI-only) are never mixed in the same store or hook. Server state goes through its data-fetching layer (query cache); client state is `useState`/`useReducer` or a client-only store.
- **House rule:** Zustand (or any global store) only for state shared across pages/routes. If state is used by one page/component tree, it stays local (`useState`, `useReducer`, or context scoped to that tree) — do not default to global.
- **House rule:** prefer CSS variables for theme/appearance changes over inline `style` prop edits or ad-hoc className toggling for style values.

## 4. Tests
*Distills: TypeScript Handbook guidance on refactor-safety + common TDD practice*

- **House rule (test-first bug fixes):** write a failing test that reproduces the bug before writing the fix. The test must fail against unpatched code, then pass after.
- **House rule (new features):** every new feature module ships with tests alongside it in the same PR/commit — not a follow-up.
- Test behavior/contracts, not implementation details (avoid asserting on internal state or private methods).
- One assertion focus per test; name tests as behavior statements (`"returns empty list when no items match"`, not `"test1"`).

## 5. Config & style
*Distills: Google TypeScript Style Guide (formatting, naming) + package-management convention*

- **House rule:** centralize configuration — one config module per package (e.g. `config/index.ts`) reading env vars/constants once. No scattered magic strings, ports, or flags defined ad hoc across files.
- **House rule:** pnpm only — never npm or yarn, no matter what a subfolder's lockfile suggests, unless that repo explicitly overrides it.
- Naming: `camelCase` for variables/functions, `PascalCase` for types/components/classes, `UPPER_SNAKE_CASE` for true constants.
- No default exports for anything except React components (page/route components excepted further if the framework requires it) — named exports elsewhere for greppability and refactor safety.
- Formatter/linter config (Prettier/ESLint) is checked in and enforced in CI, not left to editor defaults.

## Review checklist

- [ ] `wc -l` on touched files — any over 400 lines?
- [ ] `grep -rn "any" <file>` — any unjustified `any`?
- [ ] Bug-fix PR: does the test commit predate the fix commit (or same commit, test first in diff)?
- [ ] New feature module: is there a corresponding test file in the same change?
- [ ] `grep -rn "useState\|create(" <store files>` — any cross-page state living outside Zustand, or single-page state living inside it?
- [ ] `grep -rn "style={{" <changed files>` — inline style edits that should be CSS variables?
- [ ] Config constants scattered outside the package's config module? (`grep -rn "process.env\." | grep -v config/`)
- [ ] Lockfile check: `package-lock.json` or `yarn.lock` present where `pnpm-lock.yaml` should be?
