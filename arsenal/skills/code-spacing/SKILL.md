---
name: code-spacing
description: >-
  Adds and enforces blank lines between declarations and logical blocks in a
  repository. Use when the user asks for line gaps or vertical spacing, when code
  is cramped with no blank lines, or to set up a lint rule that keeps spacing from
  drifting. Applies the spacing once as a whitespace-only change, proves nothing
  else changed, and wires the rule into the repo's check gate. Works in any repo;
  the TypeScript/JavaScript path is the most detailed.
---

# Code spacing

Goal: every file reads in vertical steps. A blank line separates top-level
declarations and independent logical steps inside a function. A tool enforces it,
so nobody (human or agent) has to remember.

## Rule

Put a blank line:
- after the import block
- before and after every function, class, type, interface and export
- before and after `if`, `for`, `while`, `do`, `try`, `switch` and other block statements
- after a group of `const`/`let` declarations (consecutive declarations may stay together)
- before `return`

Spacing is enforced by a lint rule wherever the repo's linter supports it; otherwise it is checked at review.
Never copy a cramped local style because "the surrounding code does it". This rule wins.

## Steps

1. **Detect the stack.** Read the manifest, lockfile, scripts and any existing
   lint config. Reuse an existing linter when there is one; don't add a second.
2. **Add the rule** (TypeScript/JavaScript recipe below; see "Other languages").
3. **Dry run.** Run the linter and report the count of violations.
4. **Autofix**, then hand-fix what the fixer mangles. Autofix splits multi-statement
   one-liners (`x => { const a = f(); if (a) g(a); }`) into broken fragments with
   odd single-space indents. Find them with
   `grep -rnE '^ [a-zA-Z]' src` and rewrite each as a proper multi-line block.
5. **Prove whitespace only.** `git diff -w --ignore-blank-lines` must show only the
   re-wrapped one-liners from step 4. Check there are no doubled blank lines.
6. **Gate it.** Add `lint` / `lint:fix` scripts and put `lint` in the repo's main
   check command (e.g. `typecheck && lint && build && test`). Run the full gate.
7. **Document it** with one line in the repo's CLAUDE.md (or equivalent) under a
   Style heading, naming the lint and fix commands.
8. **Ship it as its own PR**, separate from behavior changes.

## TypeScript / JavaScript recipe

Install: `eslint`, `typescript-eslint` (parser only), `@stylistic/eslint-plugin`.

`eslint.config.js` (only this rule, so the PR stays about spacing):

```js
import tseslint from "typescript-eslint";
import stylistic from "@stylistic/eslint-plugin";

const BLOCKS = ["if", "for", "while", "do", "try", "switch", "block-like"];
const DECLARATIONS = ["function", "class", "export", "type", "interface"];

export default tseslint.config({
  files: ["src/**/*.{ts,tsx}"],
  languageOptions: { parser: tseslint.parser },
  plugins: { "@stylistic": stylistic },
  rules: {
    "@stylistic/padding-line-between-statements": [
      "error",
      { blankLine: "always", prev: "import", next: "*" },
      { blankLine: "any", prev: "import", next: "import" },
      { blankLine: "always", prev: "*", next: DECLARATIONS },
      { blankLine: "always", prev: DECLARATIONS, next: "*" },
      { blankLine: "always", prev: "*", next: [...BLOCKS, "return"] },
      { blankLine: "always", prev: BLOCKS, next: "*" },
      { blankLine: "always", prev: ["const", "let"], next: "*" },
      { blankLine: "any", prev: ["const", "let"], next: ["const", "let"] },
    ],
  },
});
```

Adjust `files` to the repo's source folders. Use `.mjs` if `package.json` has no
`"type": "module"`.

**TypeScript 7:** typescript-eslint fails with "does not support TS 7.0". Use the
official side-by-side aliases, then confirm `npx tsc --version` still reports 7:

```json
"@typescript/native": "npm:typescript@^7.0.2",
"typescript": "npm:@typescript/typescript6@^6.0.2"
```

Prettier won't add these lines (it only keeps existing blank lines), so keep this
rule alongside it.

## Other languages

- **Python:** `ruff format` (or black) handles blank lines between top-level and
  nested definitions. Inside functions there's no reliable autofixer, so apply the
  rule by hand in files you touch and note it in CLAUDE.md.
- **Go:** `gofmt` doesn't add blank lines; apply by hand. `wsl` (golangci-lint)
  enforces similar rules if the repo already uses golangci-lint.
- **Other stacks:** look for a formatter or linter "padding"/"blank line" rule
  first. If there's none, apply by hand and document the rule; don't invent tooling.

## When delegating

Tell subagents explicitly: "blank line between declarations and logical blocks".
Don't write "match surrounding style", because they will copy the cramped code.

## Done when

- The linter passes, and the main check command runs it.
- The diff is whitespace-only, apart from re-wrapped one-liners.
- Tests and build pass.
- CLAUDE.md names the rule and the fix command.
