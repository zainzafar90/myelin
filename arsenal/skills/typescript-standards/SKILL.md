---
name: typescript-standards
description: Use when writing, reviewing, or refactoring TypeScript code. Loads coding-standards and its TypeScript reference, and gives a grep-checkable review list for file size, any, exports, comments, config, and lockfiles. React components also need react-standards.
metadata:
  version: "2.0.0"
---

# TypeScript standards

The rules live in two places. Load both; do not restate them here.

- the `coding-standards` skill: limits, naming, comments, package manager, workflow.
- `references/typescript.md` in `coding-standards`: types, modules, tests, tooling.
- React components, hooks, and routes: also load `react-standards`.

If a rule and existing code conflict, flag it. Never silently copy the wrong pattern.

## Review checklist

Set the file list first, then run the checks. `set --` and `"$@"` work the same in bash and zsh.
Every hit is a lead; read it before calling it a finding.

```bash
set -- $(git diff --name-only HEAD -- '*.ts' '*.tsx')   # touched files
# set -- $(find src -name '*.ts' -o -name '*.tsx')      # whole-folder review instead

wc -l "$@" | awk '$1 > 200 && $2 != "total"'                  # over 200 lines
grep -nE ':\s*any\b|<any>|\bas any\b|any\[\]' "$@"            # unjustified any
grep -n 'export default' "$@"                                 # only where the framework requires
grep -nE '\bif \(.*\) (return|throw|continue|break)\b' "$@"   # one-line guards
grep -nE '^\s*//' "$@"                                        # house style is /* */, 8 words or fewer
grep -n 'style={{' "$@"                                       # prefer CSS variables
grep -n 'process.env\.' "$@" | grep -v '/config'              # scattered env reads
ls pnpm-lock.yaml package-lock.json yarn.lock 2>/dev/null     # more than one = mixed package managers
```

Also check by reading the diff: a bug fix ships with a test that failed first, and a new feature module
ships with its tests in the same change.
