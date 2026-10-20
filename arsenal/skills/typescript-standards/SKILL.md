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

```bash
wc -l $FILES | awk '$1 > 200 && $2 != "total"'           # over 200 lines
grep -nE ':\s*any\b|<any>|\bas any\b|any\[\]' $FILES    # unjustified any
grep -n 'export default' $FILES                         # only where the framework requires
grep -nE '^\s*if \(.*\) (return|throw|continue|break)\b' $FILES  # one-line guards
grep -nE '^\s*//' $FILES                                 # house style is /* */, 8 words or fewer
grep -n 'style={{' $FILES                               # prefer CSS variables
grep -n 'process.env\.' $FILES | grep -v '/config'      # scattered env reads
ls package-lock.json yarn.lock 2>/dev/null              # wrong lockfile next to pnpm-lock.yaml
```

Also check by reading the diff: a bug fix ships with a test that failed first, and a new feature module
ships with its tests in the same change.
