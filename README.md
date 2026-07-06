<h1 align="center">myelin</h1>

<p align="center">
  <b>Make coding agents finish the job.</b><br>
  Workflow routing, exit gates and project memory for Claude Code, Codex and OpenCode.
</p>

---

Coding agents skip steps. They say "done" without running the tests. They
commit code nobody reviewed. They forget what you agreed on last week.

myelin closes those gaps with three small pieces:

- **A guide.** Each session starts with a short routing table: which skill to
  use when you start a feature, hit a bug, ship, or hand off work.
- **Two gates.** A false "done" gets sent back until a test or build runs.
  A `git commit` or `git push` is blocked until a review runs.
- **A memory.** Each repo gets a `.knowledge/` folder with plans, debt,
  reviews and design notes. Every agent reads it at the start of a session.

It ships no skills of its own; it points agents at the ones you already have.
The hooks are plain bash, make no model calls, finish in under 200 ms, and
fail open, so a broken hook never blocks you.

## How it works

```text
session start ──▶ guide + open plans + top debt are added to context
      │
      ▼
   you work
      │
      ├── agent says "done" ──▶ stop gate:  did a test or build run?  no → sent back
      │
      └── git commit / push ──▶ git gate:   did a review run?        no → blocked
```

## Supported agents

| Agent        | Guide + memory | "Done" gate | Commit gate |
| ------------ | :------------: | :---------: | :---------: |
| Claude Code  |       ✓        |   blocks    |   blocks    |
| Codex        |       ✓        |   blocks    |   blocks    |
| OpenCode     |       ✓        |    warns    |   blocks    |
| Hermes       |  skills only   |   partial   |      –      |
| Pi           |  skills only   |      –      |      –      |
| Command Code |  skills only   |      –      |      –      |

## Install

You need `bash`, `git` and `jq`. Without `jq` the gates switch off and the
session start says so.

```sh
git clone https://github.com/zainzafar90/myelin ~/myelin
```

**Claude Code**

```sh
claude plugin marketplace add ~/myelin
claude plugin install myelin@myelin
```

**Codex**

```sh
codex plugin marketplace add ~/myelin
codex plugin add myelin@myelin
```

Then type `/hooks` in Codex and approve the three myelin hooks.

**OpenCode**

Add the adapter to `~/.config/opencode/opencode.json`, using the full path:

```json
{
  "plugins": ["/absolute/path/to/myelin/adapters/opencode/myelin"]
}
```

Restart the agent after installing.

## Quick start

Give a repo its `.knowledge/` folder:

```sh
~/myelin/bin/myelin-stamp ~/code/my-app
```

Run it with no path to stamp every repo under `~/projects` with a commit in
the last 30 days (`--days N` to change that). Stamping is safe to repeat.

Then just work. When myelin steps in, here is what to do:

| You see                                    | Do this                                       |
| ------------------------------------------ | --------------------------------------------- |
| `no review pass detected` when committing  | Run `/pr-review` or `/simplify`, then commit  |
| The agent is sent back after saying "done" | Let it run the tests or the build             |
| `Open debt (top 5)` at session start       | Close items with a reason once they are fixed |

## Commands

| Command                        | What it does                                                   |
| ------------------------------ | -------------------------------------------------------------- |
| `/myelin next`                 | What needs you now, across every stamped repo                  |
| `/myelin day` · `week`         | Recap of commits, plans and debt                               |
| `/myelin debt` · `reviews`     | Open debt, and commits that skipped review                     |
| `bin/myelin-stamp [path…]`     | Add `.knowledge/` to repos and register them                   |
| `bin/myelin-debt <cmd> <repo>` | Read a debt ledger: `list`, `summary`, `top`, `brief`, `unparsed` |
| `bin/myelin-doctor`            | Health check for every registered repo's ledger                |

## Configuration

| Setting                  | Default      | Purpose                                             |
| ------------------------ | ------------ | --------------------------------------------------- |
| `MYELIN_HOME`            | `~/.myelin`  | Where the repo registry lives                       |
| `MYELIN_SEARCH_DIRS`     | `~/projects` | Where the doctor looks for repos that moved         |
| `.knowledge/myelin.conf` | –            | `debt_path=docs/debt.md` points at another debt file |

## Project layout

```text
canon/            the routing guide added to every session
hooks/            session start, stop gate and git gate, plus Claude and Codex wiring
bin/              myelin-stamp, myelin-debt, myelin-doctor
adapters/         OpenCode plugin
arsenal/skills/   coding standards skills, linked into each agent
templates/        what stamping copies into a repo
lessons/          lessons added to every session
docs/             how it works, decisions and plans
tests/            pure-bash test suite
```

## Learn more

- [How it works](docs/domain/context.md): every component, flow and format
- [Design rules](HANDOFF.md): the invariants that must not break
- [Contributing](AGENTS.md): what to check before you change myelin
- [Arsenal](ARSENAL.md): the standards skills and how they are linked

## License

[MIT](LICENSE)
