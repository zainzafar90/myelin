# Myelin app context

The one place for how myelin works today. Why it exists and the rules that must
not break: [HANDOFF.md](../../HANDOFF.md).

## What myelin is

A thin workflow router for coding agents. It does three things:

1. **Canon.** A routing table (`canon/ROUTING.md`, 50 lines max) injected at
   session start. It tells the agent which skill to use at four moments: START,
   STUCK, SHIP, HANDOFF.
2. **Exit gates.** Bash hooks that stop a false "done" and an unreviewed commit.
3. **Ledger.** A per-project `.knowledge/` folder any agent can read.

It is not a skill pack (it owns zero plugin skills), not a model caller (hooks
never call models), not a server or app, and it does not guess intent from
prompts.

## File map

| Path | What it is |
|---|---|
| `canon/ROUTING.md` | The routing table. The first 50 lines are injected. |
| `hooks/session-start.sh` | Injects canon, top-5 lessons, project state and top-5 open debt. |
| `hooks/stop-verify.sh` | Stop gate: a done-claim needs a test, build or check run. |
| `hooks/pre-git-gate.sh` | Git gate: `git commit` and `git push` need a review pass. |
| `hooks/hooks.json`, `hooks/codex-hooks.json` | Hook wiring for Claude and Codex. Same scripts. |
| `bin/myelin-stamp` | Copies the ledger skeleton into repos, adds `.knowledge/` to `.gitignore`, adds a pointer line to `CLAUDE.md` and `AGENTS.md`, and appends to the registry. |
| `bin/myelin-debt` | Reads a project's debt ledger: `list`, `summary`, `unparsed`, `top`, `brief`. Parser: `bin/lib/debt-ledger-{normalize,parse}.awk`. |
| `bin/myelin-doctor` | Debt-ledger health for every project in the registry. |
| `commands/myelin.md` | The `/myelin next\|day\|week\|debt\|reviews` recaps. |
| `templates/knowledge-skeleton/` | What stamping copies into a project. |
| `lessons/LESSONS.md` | Approved lessons. The first 5 bullets are injected. |
| `arsenal/` | Authored skills (repo cargo, not a plugin surface) and `skill-lock.json`. See [ARSENAL.md](../../ARSENAL.md). |
| `adapters/opencode/myelin/` | OpenCode plugin: a TypeScript shim over the same hooks. |
| `.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/` | Claude and Codex manifests and marketplaces. |
| `tests/run-tests.sh`, `tests/contract/`, `tests/lib/` | Pure-bash suite, plus code-quality and knowledge-style contracts and their helpers. |
| `docs/adr/`, `docs/plans/` | Decisions (the canonical store) and phase 2 and 3 plans. |

The registry of stamped projects is `~/.myelin/registry.txt`, one path per line,
`#` comments ignored. Set `MYELIN_HOME` to move it. Scripts find the repo from
their own location.

## The `.knowledge/` ledger

Gitignored, local, per project. `INDEX.md` is the entry point. Hooks and
`/myelin` grep these exact lines, so never restyle them.

| File | Format |
|---|---|
| `state/plans.md` | `## name`, then `- status: active\|shipped\|punted\|abandoned`, `- date:`, `- spec:`, `- notes:` |
| `state/debt.md` | See below |
| `state/reviews.md` | `- <sha> <branch> reviewed: yes\|no <date> <subject>` |
| `state/DESIGN.md` | `- voice: <name>` (one voice per project), then the rulebook |
| `myelin.conf` (optional) | `debt_path=<relative path>` points the debt tools at a different file. Absolute paths and `..` are rejected. |

Canonical debt entry:

```markdown
## title
- id: kebab-slug-unique-in-file
- status: open | closed | duplicate
- severity: high | medium | low | unknown
- where: path or subsystem
- why: consequence, and why it was deferred
- date: YYYY-MM-DD
- checked: optional note
- resolution: <date — reason — evidence>   (closed only)
- duplicate_of: <id>                        (duplicate only)
```

`myelin-debt` parses 7 shapes, so old ledgers work without migration:
`heading` (the canonical entry), `dated`, `idrec`, `dot`, `checkbox`, `bracket`
and `retired`. Lines it cannot parse show under `unparsed`, never as zero debt.

`myelin-doctor` reports one state per registry project:

| State | Meaning |
|---|---|
| `ok` | Ledger parses cleanly |
| `empty` | Ledger has no entries |
| `partial` | Some lines are unparsed |
| `no-ledger` | No debt file found |
| `missing` | Path is gone (with `candidate:` paths if the repo moved) |

## Lifecycle flows

- **Session start.** The hook prints the canon and 5 lessons. If the cwd has
  `.knowledge/state`, it adds counts (active plans, open debt, high debt,
  unreviewed commits), the top 5 open debt items (`myelin-debt brief`) and the
  design voice. Cap: 120 lines.
- **Punt to debt.** Any "skip it for now" becomes a debt entry at that moment
  (the canon's punt rule). The agent reuses a matching id instead of
  duplicating.
- **Commit gate.** On `git commit` or `git push` through Bash, the hook looks
  for a real review in the transcript: a Skill call or slash command for
  `pr-review`, `code-review` or `simplify` (on Codex: reading that skill's
  `SKILL.md`). If none is found, it exits 2 with a short message. The message
  does not list bypasses.
- **Stop gate.** If the last message claims done ("is complete", "all tests
  pass", "is fixed"…) and no test, build or check command ran in the last 500
  transcript lines, it blocks once. A second stop passes (`stop_hook_active`).
- **Debt close with evidence.** At task start the agent checks the injected
  debt for related items. At finish it sets `- status: closed` and
  `- resolution: <date — reason — evidence>`. No evidence means the item stays
  open. A deferral never satisfies a required acceptance criterion.

## Agent support

| Agent | Canon + state | Stop gate | Git gate | Notes |
|---|---|---|---|---|
| Claude Code | yes | yes | yes | Full plugin. Slash command `/myelin`. |
| Codex | yes | yes | yes | Same hooks via `codex-hooks.json`. Trust them in `/hooks`. Gates read Codex rollouts. |
| OpenCode | yes | nudge | yes | v2 plugin. Stop is a follow-up prompt after the run, not a block. |
| Pi | skills only | no | no | No adapter yet. |
| Command Code | skills only | no | no | No adapter yet. |
| Hermes | skills only | partial | no | Partial stop support only. |

The practice skills (`coding-core`, `api-engineering`, `frontend-engineering`,
`code-spacing`) live once in `arsenal/skills/`. They are symlinked into the
skill folders of every agent above. `coding-standards` was retired into
`coding-core`.

## Invariants

Short list. The full why is in [HANDOFF.md](../../HANDOFF.md).

- Hooks: pure bash, fail-open (`trap 'exit 0' ERR`), no model calls, under 200ms.
- Canon is 50 lines max. Injection is 120 lines max (test-asserted).
- Zero plugin-loaded skills. Never copy third-party skills in.
- Enforce at exits (stop, commit), never at prompts.
- Grep-contract formats change only with every reader and every stamped project
  in one commit.
- macOS bash 3.2 compatible.
- Tests green before any commit (a hook enforces it).

## Shipping a change

Editing the repo changes nothing live. Do all steps, every time:

1. Bump `version` in both `.claude-plugin/plugin.json` and
   `.codex-plugin/plugin.json`. Run `bash tests/run-tests.sh`.
2. Claude: `claude plugin update myelin@myelin`, once per profile (each
   `CLAUDE_CONFIG_DIR`).
3. Codex: `codex plugin remove myelin@myelin`, then
   `codex plugin add myelin@myelin`, then re-trust the hooks in `/hooks`.
4. Restart or open a new session. Running sessions never reload.
5. OpenCode loads straight from the repo (`adapters/opencode`, registered under
   `plugins` in `~/.config/opencode/opencode.json`). Restart OpenCode only.

If a change does not show up:

- "already latest" means the bump was skipped.
- A correct cache that still has no effect means the session predates the
  update.
- Check `ls ~/.claude/plugins/cache/myelin/myelin/` for the newest version
  directory.

Moving the repo touches only the marketplace re-add and the OpenCode plugin
path.

## Escape hatches

For the user only. They are deliberately left out of the canon and the gate
messages, so agents are not taught to dodge the gates. Every hatch is narrower
than the gate it skips.

- **Soft routing.** Say "quick" or "raw" and the agent skips routing and
  answers directly.
- **Git gate, branch.** Branches named `scratch/*`, `wip/*` or `tmp/*` skip the
  gate.
- **Git gate, message.** Put `[quick]` in the commit command. It works only on
  non-protected branches (not `main`, `master`, `develop` or `release*`).
- **Stop gate.** None needed. It blocks once, then lets the second stop through.
- **Fail-open.** If `jq` is missing or the transcript is unreadable, the gates
  allow.

## Roadmap

- **Phase 2, the loop** ([plan](../plans/2026-07-06-myelin-phase-2.md)):
  breadcrumbs, a nightly Haiku miner (recaps, corrections, orphan commits), a
  lessons flow and a health CLI. Not built. The miner only proposes. The user
  approves.
- **Phase 3, the map** ([plan](../plans/2026-07-06-myelin-phase-3.md)): graph
  nodes, entropy metrics, `/myelin-init` and dashboards. Gated on data.
- **2026-11-18 month check-in.** Mine sessions into lessons, then decide whether
  to publish.
- **Later list.** Menu-bar app, JSON graph index, SEO lane, public release.
  Nothing ships from it without a month of demonstrated need.

### Success measures

Baseline frozen 2026-07-06: moment-skill invocations about 0; 9,303 prompts,
with `/status` used 1,169 times; review coverage unmeasured.

1. Moment-skill invocations visible in history within 2 weeks.
2. Zero unreviewed commits older than 7 days.
3. No plan-drift warnings across 2 weekly recaps.
4. Repeat-correction rate falling month over month.
5. The user reads the daily recap 4 or more days a week. Watch this one
   hardest. If it fails, fix the format.

### Kill criteria

Checked at the Phase 3 retrospective, or at +6 weeks. Myelin is declared
failed, and the hooks removed, if any one holds:

1. Moment-skill firings in stamped projects are still about 0 a week.
2. Git-gate bypasses (`[quick]`, scratch-branch dodges of real work) exceed
   gate passes over any 2 weeks.
3. The user stops reading recaps for 2 weeks after one format fix.
4. Repeat-correction rate shows no gain over unstamped repos.

Compare stamped repos (the registry) against all other active repos.

## Open decisions and known gaps

- Codex's built-in `/review` is not accepted as review evidence yet.
- The gates trust a transcript the agent can write, so a forged entry passes.
  Real fix: reconcile against `reviews.md` (Phase 2).
- Hermes has only partial stop support. Pi and Command Code have no adapters.
- Reviewing in a different session than the commit still blocks. `[quick]` is
  the stopgap.
- The stop-gate claim regex is heuristic and can false-fire on innocent
  phrasing. Tune it with real data, never with a model call.
- Phase 2 miner: run the per-project fan-out as a Workflow script (capped,
  skip-inactive, no silent truncation) instead of prompt-directed subagents?
  Proposed, no verdict yet.
- `frontend-verify-standards` has not had a live run in a real UI repo. Its
  house checks are untested guesses.
- Closed already: `/goal` stays out of myelin; no `/build deep` command; native
  `/schedule` is rejected for the miner (it needs local repos and transcripts).
