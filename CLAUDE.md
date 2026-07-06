# myelin

A thin workflow-router plugin for Claude Code, Codex and OpenCode. It injects a
routing canon, runs exit-gate hooks, and keeps a per-project `.knowledge/`
ledger. It owns zero skills.

> **The two rules that bite**
>
> 1. Tests must be green (`bash tests/run-tests.sh`) before any commit. A hook
>    enforces it.
> 2. Edits do nothing live until: version bump, `claude plugin update
>    myelin@myelin`, restart. "It didn't work" is almost always a skipped bump.

<!-- myelin --> Machine-maintained project state lives in `.knowledge/` — read `.knowledge/INDEX.md` first.

## Read first

- How it works, formats, shipping steps: [docs/domain/context.md](docs/domain/context.md)
- Why it is built this way, and the invariants: [HANDOFF.md](HANDOFF.md)
- Authored skills: [ARSENAL.md](ARSENAL.md)

## Commands

| Task | Command |
|---|---|
| Test (required before any commit) | `bash tests/run-tests.sh` |
| Stamp projects | `bin/myelin-stamp [path…]` |
| Recaps | `/myelin next\|day\|week\|debt\|reviews` |

Ship a change: bump `version` in both `.claude-plugin/plugin.json` and
`.codex-plugin/plugin.json`, then update the plugin and restart. All steps:
[Shipping a change](docs/domain/context.md#shipping-a-change).

## Hard constraints

- Hooks are pure bash, fail-open (`trap 'exit 0' ERR`), make no model calls,
  and run in under 200ms.
- Canon is 50 lines max. SessionStart injection is 120 lines max (test-asserted).
- Grep-contract lines (`- status: active`, `- severity: high`, `reviewed: no`,
  `- voice:`, `^## `) are shared by hooks, templates and `/myelin`. Change every
  reader and migrate stamped projects in one commit, or don't.
- No plugin-loaded skills. Route by name only. Never copy third-party skills in.
- macOS bash 3.2 compatible (no bash 4 features).

## Structure

| Path | Holds |
|---|---|
| `canon/` | Routing table (injected) |
| `hooks/` | The three gates and hook wiring |
| `commands/` | `/myelin` |
| `templates/knowledge-skeleton/` | What stamping copies |
| `bin/` | `myelin-stamp`, `myelin-debt`, `myelin-doctor` |
| `adapters/` | OpenCode plugin |
| `arsenal/` | Authored skills |
| `lessons/` | Approved lessons (top 5 injected) |
| `docs/` | Domain context, plans, ADRs |
