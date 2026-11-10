<h1 align="center">myelin</h1>

<p align="center">
  <b>Make coding agents finish the job, at every stage of a product.</b><br>
  A lifecycle router, exit gates and project memory for Claude Code, Codex and OpenCode.
</p>

---

Coding agents are good at the middle of the work and bad at its edges. They
start building before anyone agreed what to build. They say "done" without
running the tests. They commit code nobody reviewed, ship without a way back,
and forget what you decided last week.

myelin gives every session the same map of a product's life, and holds the
agent to it:

- **A route for every stage.** From the first idea to production errors, each
  stage names the skills and tools to use, so you steer the first pass and
  agents run the repeats.
- **Two gates.** A false "done" is sent back until a test or build runs. A
  `git commit` or `git push` is blocked until a review runs, including reviews
  run by subagents.
- **A memory.** Each repo gets a `.knowledge/` folder with plans, debt,
  reviews and design notes that every agent reads at the start of a session.

myelin ships no skills of its own; it points agents at the ones you already
have. The hooks are plain bash, make no model calls and fail open, so a broken
hook never blocks you.

## The lifecycle

```text
START ─▶ SETUP ─▶ build ─────────▶ UAT ─▶ SHIP ─▶ DEPLOY ─▶ OBSERVE
 idea     stack    PARALLEL         as a    review   CI/CD     Sentry
 plan     tests    HANDOFF          user    commit   rollback  PostHog
                   STUCK (any time a bug or failure shows up)
                   PERF  (when speed, load or size matters)
```

| Moment   | When it fires                                              | What the agent does                                                              |
| -------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------- |
| START    | A new feature or behavior change                           | Brainstorm, stress-test the design, write a plan, register it                    |
| SETUP    | A new repo or stack, or the first session in one           | Stamp the repo, agree the layout, get a passing test and build, set permissions  |
| PARALLEL | Two or more independent tasks                              | One rules file, one branch and worktree per agent, isolated tests, merge order   |
| HANDOFF  | One task delegated                                         | A brief with files, acceptance and stop conditions                               |
| STUCK    | A bug, error or failing test                               | Find the root cause before fixing                                                |
| UAT      | A user-visible change is code-complete                     | Run the real app and drive every acceptance criterion, failure path included     |
| SHIP     | "Done", a branch finish, a commit                          | Verify, review, polish, commit, write the PR, update the ledger                  |
| PERF     | "Slow", load, size, or before a launch                     | Measure, agree a budget, change one thing, re-measure                            |
| DEPLOY   | First deploy, a CI change, a release                       | CI with tests and a migration check, secrets out of the repo, a rollback path    |
| OBSERVE  | A production error, or "what are users doing"              | Sentry issue to failing test to linked fix; PostHog events named in every plan   |

The full routes are in [`canon/ROUTING.md`](canon/ROUTING.md), which is added
to every session.

## What you see

When a commit has no review behind it:

```text
myelin git-gate: no review pass detected this session on branch 'feature/x'.
Before committing: run /pr-review (or /simplify for quality-only), then retry.
```

When the agent says "done" without running anything:

```text
myelin stop-verify: a completion claim was made but no test/build/check command
ran this session. Run the project's verification ... and report the actual output.
```

## Quick start

You need `bash`, `git` and `jq`.

1. Clone it: `git clone https://github.com/zainzafar90/myelin ~/myelin`
2. Install it in your agent (below), then restart the agent.
3. Give a repo its memory: `~/myelin/bin/myelin-stamp ~/code/my-app`
4. Work as usual. Start a feature, and the session already knows the route.

<details>
<summary><b>Install in Claude Code, Codex or OpenCode</b></summary>

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

Without `jq` the gates switch off, and the session start says so.

| Agent        | Routes + memory | "Done" gate | Commit gate |
| ------------ | :-------------: | :---------: | :---------: |
| Claude Code  |        ✓        |   blocks    |   blocks    |
| Codex        |        ✓        |   blocks    |   blocks    |
| OpenCode     |        ✓        |    warns    |   blocks    |
| Hermes       |   skills only   |   partial   |      –      |
| Pi           |   skills only   |      –      |      –      |
| Command Code |   skills only   |      –      |      –      |

</details>

<details>
<summary><b>When myelin steps in</b></summary>

| You see                                    | Do this                                       |
| ------------------------------------------ | --------------------------------------------- |
| `no review pass detected` when committing  | Run `/pr-review` or `/simplify`, then commit  |
| The agent is sent back after saying "done" | Let it run the tests or the build             |
| `Open debt (top 5)` at session start       | Close items with a reason once they are fixed |

</details>

<details>
<summary><b>Commands</b></summary>

| Command                        | What it does                                                      |
| ------------------------------ | ----------------------------------------------------------------- |
| `/myelin next`                 | What needs you now, across every stamped repo                     |
| `/myelin day` · `week`         | Recap of commits, plans and debt                                  |
| `/myelin debt` · `reviews`     | Open debt, and commits that skipped review                        |
| `bin/myelin-stamp [path…]`     | Add `.knowledge/` to repos and register them                      |
| `bin/myelin-debt <cmd> <repo>` | Read a debt ledger: `list`, `summary`, `top`, `brief`, `unparsed` |
| `bin/myelin-doctor`            | Health check for every registered repo's ledger                   |

With no path, `myelin-stamp` stamps every repo under `~/projects` with a
commit in the last 30 days (`--days N` to change that). A path you name is
stamped even before its first commit. Stamping is safe to repeat.

</details>

<details>
<summary><b>Configuration</b></summary>

| Setting                  | Default      | Purpose                                              |
| ------------------------ | ------------ | ---------------------------------------------------- |
| `MYELIN_HOME`            | `~/.myelin`  | Where the repo registry lives                        |
| `MYELIN_SEARCH_DIRS`     | `~/projects` | Where the doctor looks for repos that moved          |
| `.knowledge/myelin.conf` | –            | `debt_path=docs/debt.md` points at another debt file |

</details>

## Development

```sh
bash tests/run-tests.sh   # must print "0 failed" before any commit
```

Edits are not live until you bump `version` in `.claude-plugin/plugin.json`
and `.codex-plugin/plugin.json`, run `claude plugin update myelin@myelin`, and
restart. All steps: [Shipping a change](docs/domain/context.md#shipping-a-change).

<details>
<summary><b>Project layout</b></summary>

```text
canon/            the routing table added to every session
hooks/            session start, stop gate and git gate, plus Claude and Codex wiring
bin/              myelin-stamp, myelin-debt, myelin-doctor
adapters/         OpenCode plugin
arsenal/skills/   coding standards skills, linked into each agent
templates/        what stamping copies into a repo
lessons/          lessons added to every session
docs/             how it works, decisions and plans
tests/            pure-bash test suite
```

</details>

## Learn more

- [How it works](docs/domain/context.md): every moment, component, flow and format
- [Design rules](HANDOFF.md): the invariants that must not break
- [Contributing](AGENTS.md): what to check before you change myelin
- [Arsenal](ARSENAL.md): the standards skills and how they are linked

## License

[MIT](LICENSE)
