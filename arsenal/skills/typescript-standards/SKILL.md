---
name: typescript-standards
description: Use when writing, reviewing, or refactoring TypeScript code. Loads coding-core and its TypeScript reference, and gives a grep-checkable review list for file size, any, exports, comments, config, and lockfiles. React components also need react-craft.
metadata:
  version: "2.0.0"
---

# TypeScript standards

The rules live in two places. Load both; do not restate them here.

- [coding-core](../coding-core/SKILL.md): limits, naming, comments, package manager, workflow.
- [TypeScript reference](../coding-core/references/typescript.md): types, modules, tests, tooling.
- React components, hooks, and routes: also load `react-craft`.

If a rule and existing code conflict, flag it. Never silently copy the wrong pattern.

## Review checklist

Run on the touched files (`$FILES`). Every hit is a lead; read it before calling it a finding.

| Check | Command |
|---|---|
| Over 200 lines | `wc -l $FILES \| awk '$1 > 200 && $2 != "total"'` |
| Unjustified `any` | `grep -nE ':\s*any\b\|<any>\|\bas any\b\|any\[\]' $FILES` |
| Default exports | `grep -n 'export default' $FILES` (allowed only where the framework requires) |
| One-line guards | `grep -nE '^\s*if \(.*\) (return\|throw\|continue\|break)\b' $FILES` |
| `//` comments | `grep -nE '^\s*//' $FILES` (house style is `/* */`, 8 words or fewer) |
| Inline style values | `grep -n 'style={{' $FILES` (prefer CSS variables) |
| Scattered env reads | `grep -n 'process.env\.' $FILES \| grep -v '/config'` |
| Wrong lockfile | `ls package-lock.json yarn.lock 2>/dev/null` next to a `pnpm-lock.yaml` |
| Bug fix without a failing test first | the test change precedes or ships with the fix |
| New feature module without tests | a test file exists in the same change |
