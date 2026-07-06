# myelin

Agent instructions for Codex, OpenCode and any agent that reads `AGENTS.md`.

<!-- myelin --> Machine-maintained project state lives in `.knowledge/` — read `.knowledge/INDEX.md` first.

How it works: [docs/domain/context.md](docs/domain/context.md). Read
[HANDOFF.md](HANDOFF.md) before touching `hooks/`, `canon/` or `templates/`.

## Before you commit

1. Run `bash tests/run-tests.sh`. It must print `0 failed`. Paste the real output.
2. Run a review pass (`/pr-review`, `/simplify`, or the `code-review` skill).
   The git gate blocks the commit without one. Do not route around it.
   No git gate in your agent? Add a line to `.knowledge/state/reviews.md`.
3. Log anything you skip in `.knowledge/state/debt.md` now, as a `## ` entry.

## Never

- Add model calls, network calls or bash 4 features to `hooks/`. Hooks are pure
  bash 3.2 (macOS default), fail open, and run in under 200ms.
- Restyle lines that scripts grep for (`- status:`, `- severity:`,
  `reviewed:`, `- voice:`, `^## `).
- Add plugin-loaded skills, or copy third-party skills into `arsenal/`.
- Push `canon/ROUTING.md` past 50 lines, or session-start output past 120.

## Shipping

Edits are not live until you bump `version` in both `.claude-plugin/plugin.json`
and `.codex-plugin/plugin.json`, update the plugin, and restart. Steps:
[Shipping a change](docs/domain/context.md#shipping-a-change).
