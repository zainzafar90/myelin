# Myelin handoff

You are inheriting myelin. This is what I would tell you across the desk on my
last day.

- What the app is and how it runs today: [docs/domain/context.md](docs/domain/context.md)
- What is next: [docs/plans/](docs/plans/)
- Why it is built this way, and what will kill it: this file

## What this is, in one breath

The user has 134+ excellent skills that never fire, no view of what shipped,
unreviewed agent code merging silently, and codebases whose mental model they
are losing.

Myelin fixes activation and state. It is a **nervous system, not a muscle**:

- a routing canon of 50 lines or fewer, injected every session
- exit gates that make "done" and "commit" honest
- a per-project `.knowledge/` ledger any agent can read

A nightly Haiku miner would turn their transcripts into recaps, lessons and
audits. It is planned (Phase 2), not built.

## Invariants

Break these and the project dies.

1. **Zero owned skills.** Myelin routes to installed packs by name. Copy one
   skill into this repo and you own a fork forever. Don't.
2. **Hooks never call models.** Shell only, under 200ms, **fail-open**
   (`trap 'exit 0' ERR`). One hung hook and the user disables everything.
   Users already ignore advisory systems, and a *broken* enforcing system is
   worse than none.
3. **Budgets are hard.** Canon is 50 lines max. SessionStart injection is 120
   lines max. The miner is Haiku only, activity-gated and capped. The moment
   myelin feels expensive or noisy, it gets bypassed, and metric 5 fails.
4. **Ontology cap: 4 node types** (decision, preference, gotcha, map). Every
   knowledge system dies by type proliferation. The answer to "we need a new
   type" is almost always "it's a `map` or a `decision`".
5. **The Later list is contractual.** Nothing ships from it (menu-bar app, JSON
   graph index, SEO lane, public release) without a month of demonstrated
   need. The user named the dopamine risk: the harness exists partly to stop
   them building more harness.
6. **Enforce at exits, never at entrances.** No prompt-regex routing, ever.
   Prompts are conversational ("can we maybe you know…"), so intent-guessing
   misfires and burns trust. Exits (stop, commit, push) are deterministic.
7. **Formats are grep-contracts.** `- status: active`, `- severity: high`,
   `reviewed: no`, `- voice:` and `^## ` entry headers. Hooks, templates and
   `/myelin` all depend on them. Change a format and you migrate every stamped
   project and every reader in one commit.

## The user

Build for this person:

- Conversational and iterative. Plan-first in theory, `/status`-spamming in
  practice.
- Works across about 20 active repos. Mostly React/TypeScript, with rising
  Swift/macOS and agent tooling.
- Delegates implementation to Codex. Asks for a confidence percentage after
  changes.
- *Wants* discipline but routes around friction. Every gate needs an escape
  hatch, and every escape hatch must be narrower than the gate.

## Runbook

Commands, shipping steps (Claude, Codex, OpenCode), the debug ladder, moving
the repo, and escape hatches live in
[docs/domain/context.md](docs/domain/context.md). Keep three rules in your
head:

- Tests green (`bash tests/run-tests.sh`) before any commit.
- Edits do nothing live until version bump, plugin update and restart. The
  installed copy is a cache keyed by `version`. Same version means no refresh.
- The miner (Phase 2, unbuilt) **proposes** and the user approves. It must
  never write ledgers or lessons silently. The day it does, trust in the data
  dies.

## Success metrics

The future miner reports these. Watch metric 5 hardest. Kill criteria are in
[docs/domain/context.md](docs/domain/context.md#kill-criteria).

1. Moment-skill invocations are visible in history within 2 weeks (baseline
   about 0).
2. Zero unreviewed commits older than 7 days by the end of Phase 2.
3. Active projects show no plan-drift warnings for 2 weekly recaps running.
4. Repeat-correction rate falls month over month.
5. **The user reads the daily recap 4 or more days a week.** If this fails, the
   recap format is wrong. Fix the format, don't abandon the system.

## Known traps

- **Stop-gate claim regex is heuristic.** It will sometimes false-fire on
  innocent phrasing ("the docs are complete"). Tune it in `hooks/stop-verify.sh`
  with real transcript data. Do NOT fix it with a model call (invariant 2).
- **Review evidence detection** (git gate) greps the transcript for real review
  invocations (Skill `tool_use` JSON or `<command-name>` tags), never prose. A
  prose match once let the injected canon whitelist itself every session
  (fixed in v0.1.6; fixture `transcript-canon-mention.jsonl`). Remaining gap:
  a review in a *different session* than the commit still blocks unfairly.
  `[quick]` is the short-term hatch. A miner-reconciled `reviews.md` is the
  real fix.
- **Loose sessions** (no branch ceremony) escape the SHIP gate by design. Only
  the miner will catch their punts. Accepted trade-off.
- **The `claude plugin` CLI may drift between versions.** If install breaks,
  wire `hooks/*.sh` directly in `~/.claude/settings.json` and symlink
  `commands/*.md` into `~/.claude/commands/`. The scripts are host-agnostic
  (Codex and OpenCode already reuse them).

## Roadmap

Phase 1 shipped. Current state and open decisions are in
[docs/domain/context.md](docs/domain/context.md). Next:

- [Phase 2](docs/plans/2026-07-06-myelin-phase-2.md): the loop
- [Phase 3](docs/plans/2026-07-06-myelin-phase-3.md): the map, gated on data

The Later list is quarantined. Re-read invariant 5.

Good luck. Keep it small. The boring version that runs every day beats the
brilliant version that gets disabled.
