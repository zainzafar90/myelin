# Lifecycle Moments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow the canon from four moments (START, STUCK, SHIP, HANDOFF) to the whole product lifecycle: SETUP, PARALLEL, UAT, PERF, DEPLOY, OBSERVE. Fix the git gate so reviews run by subagents count. Reposition the README as a lifecycle router.

**Architecture:** Each moment is one row in `canon/ROUTING.md` that routes by skill or tool name, plus a short entry in `docs/domain/context.md`. A test asserts each row is injected and the canon stays within 50 lines. The gate change is one extra transcript glob in `hooks/pre-git-gate.sh`.

**Tech Stack:** Markdown, bash 3.2, `jq`, the pure-bash test suite.

**Spec:** the user's phase list (2026-11-11 session), and the gaps table in that session: idea, setup, async implementation, testing/UAT, refactor, performance, CI/CD, observability, instrumentation.

## Global Constraints

- `canon/ROUTING.md` stays within 50 lines; session-start output within 120 (test-asserted).
- Hooks: pure bash 3.2, fail-open (`trap 'exit 0' ERR`), no model or network calls, under 200 ms.
- Route by name only. Own zero plugin skills. Never copy third-party skills in.
- Don't restyle grep-contract lines (`- status:`, `- severity:`, `reviewed:`, `- voice:`, `^## `).
- One stacked PR per task on `zainzafar90/myelin`. Each branch is cut from the previous task's branch. The version bump goes in the last PR only.
- `bash tests/run-tests.sh` must print `0 failed` before every commit.

## Review Focus

1. Canon over 50 lines: `session-start.sh` cuts with `head -n 50`, so a row past line 50 vanishes silently. Task 1 adds a test that fails if the canon file exceeds 50 lines.
2. Subagent transcript dir missing, empty, or holding a non-review mention: the gate must still block, and must not error. Task 2 tests both.
3. Codex transcripts have no `subagents/` sibling: the glob must match nothing and fall through. Covered by Task 2's "dir missing" test.
4. Moments overlapping existing ones (UAT vs SHIP's browser-verify, PERF vs browser-verify's CWV). Each row names its trigger so only one fires. Checked by hand in review.
5. A moment's route naming a skill or tool that isn't installed. Rows name only skills or MCPs present today (listed per task), and fall back to a plain step.

---

### Task 1: SETUP moment, plus fixing the red baseline test

Branch `lifecycle/1-setup` from `origin/main`. PR base `main`.

**Files:**
- Modify: `canon/ROUTING.md` (moments table)
- Modify: `docs/domain/context.md` ("What myelin is" moment list; new "Lifecycle moments" section)
- Modify: `tests/run-tests.sh` (`run_gate_file`, `test_session_start`)

**Interfaces:**
- Produces: the test helper `assert_moment <NAME>`, which checks `| NAME |` is in the session-start output. Later tasks call it once each.

- [ ] **Step 1:** Fix the baseline failure. `gate blocks escaped-quote commit on main` fails because its fixture's `cwd` is a hard-coded `/tmp/myelin-fakerepo`. Make `run_gate_file` rewrite `.cwd` to `$FAKEREPO` with `jq` before piping to the hook. Run the suite: expect `0 failed`.
- [ ] **Step 2:** Add tests `canon within 50 lines` (`[ "$(wc -l < canon/ROUTING.md)" -le 50 ]`) and `assert_moment SETUP`. Run: expect 1 fail (SETUP missing).
- [ ] **Step 3:** Add the SETUP row. Trigger: new repo, new stack, or first session in an unstamped repo. Route: `myelin-stamp` → agree the stack and layout with the user (`codebase-design` for module boundaries) → one test and one build command that pass, written in CLAUDE.md/AGENTS.md → permissions through `fewer-permission-prompts` / `update-config` allowlists, never skip-permissions mode → first commit through SHIP.
- [ ] **Step 4:** Docs: list the moments in context.md and add a two-line SETUP entry. Run the suite: `0 failed`.
- [ ] **Step 5:** Commit, review, push, open the PR.

### Task 2: PARALLEL moment, plus the subagent review evidence fix

Branch `lifecycle/2-parallel` from Task 1's branch. PR base `lifecycle/1-setup`.

**Files:**
- Modify: `hooks/pre-git-gate.sh` (`has_review_evidence`)
- Create: `tests/fixtures/subagent-session.jsonl` and `tests/fixtures/subagent-session/subagents/agent-1.jsonl` (review Skill call), `tests/fixtures/subagent-mention-session.jsonl` and `.../subagents/agent-1.jsonl` (review only mentioned in text)
- Modify: `tests/run-tests.sh`, `canon/ROUTING.md`, `docs/domain/context.md`

**Interfaces:**
- Produces: `has_review_evidence <transcript>` returns 0 if the transcript **or** any `${transcript%.jsonl}/subagents/*.jsonl` holds a real review call.

- [ ] **Step 1:** Tests: `gate allows commit when a subagent ran the review` (exit 0); `gate blocks when a subagent only mentions a review` (exit 2); `gate blocks when there is no subagents dir` (exit 2, existing no-evidence fixture). Run: the first fails.
- [ ] **Step 2:** In `has_review_evidence`, after the main transcript check, loop over `"${transcript%.jsonl}"/subagents/*.jsonl`, skip non-files (unmatched glob), and return 0 on the first file with `has_claude_review` or `has_codex_review`. Run: `0 failed`.
- [ ] **Step 3:** `assert_moment PARALLEL`, then the row. Trigger: 2+ independent tasks, or a plan with separable phases. Route: `superpowers:dispatching-parallel-agents` (or `subagent-driven-development`) → one shared rules file every agent reads (scope, base branch, test command, review, ship, report format) → one branch and worktree per agent → isolated test resources per run (no shared DB) → never `git stash` (shared across worktrees) → agents wait on their own jobs, no interim hand-backs → orchestrator re-checks the riskiest results and records merge order for stacked PRs.
- [ ] **Step 4:** Docs: PARALLEL entry, plus the commit-gate flow now mentions subagent transcripts. Close the known gap "reviewing in a different session still blocks" only for subagents (other sessions still block).
- [ ] **Step 5:** Commit, review, push, open the PR.

### Task 3: UAT moment

Branch `lifecycle/3-uat` from Task 2's. PR base `lifecycle/2-parallel`.

- [ ] **Step 1:** `assert_moment UAT` (fails).
- [ ] **Step 2:** Row. Trigger: a user-visible change is code-complete, before SHIP. Route: `run` (launch the real app) → drive each acceptance criterion end to end as a user, including one failure path → web: `browser-verify`; iOS: the simulator tool; CLI or API: real commands against a running instance → evidence in the PR (screenshots, command output) → any failure → STUCK. SHIP's browser-verify step then points back at UAT, not a second pass.
- [ ] **Step 3:** Docs entry. Run the suite: `0 failed`. Commit, review, push, PR.

### Task 4: PERF moment

Branch `lifecycle/4-perf`. PR base `lifecycle/3-uat`.

- [ ] **Step 1:** `assert_moment PERF` (fails).
- [ ] **Step 2:** Row. Trigger: "slow", load or scale questions, bundle or memory size, before a launch. Route: measure first and write the baseline number down → set a budget with the user → platform tools: web `chrome-devtools-mcp:debug-optimize-lcp` and perf traces; backend query plans and a load test; mobile Instruments → change one thing, re-measure, keep it only if the number moved → record the budget in `.knowledge/state/DESIGN.md` or the plan. No optimisation without a number.
- [ ] **Step 3:** Docs entry. Suite green. Commit, review, push, PR.

### Task 5: DEPLOY moment

Branch `lifecycle/5-deploy`. PR base `lifecycle/4-perf`.

- [ ] **Step 1:** `assert_moment DEPLOY` (fails).
- [ ] **Step 2:** Row. Trigger: first deploy, CI changes, a release. Route: first time, with the user steering: `engineering:deploy-checklist` → CI runs tests, lint and a migration check on every PR → secrets live in the CI or host store, never the repo → a written rollback path. After that the agent owns it: green CI before merge → migration dry run → deploy → watch health and errors (OBSERVE) → roll back on a failed check. Never merge or deploy without the user's go-ahead.
- [ ] **Step 3:** Docs entry. Suite green. Commit, review, push, PR.

### Task 6: OBSERVE moment

Branch `lifecycle/6-observe`. PR base `lifecycle/5-deploy`.

- [ ] **Step 1:** `assert_moment OBSERVE` (fails).
- [ ] **Step 2:** Row. Trigger: a prod error or crash, "what are users doing", or first setup of errors or analytics. Route: setup once with the user: Sentry and PostHog through their MCP or CLI, keys in env, releases tagged, alert rules → then the agent loops: Sentry issue → `get_sentry_resource` / details → STUCK (failing test first) → fix → link the issue. Every new feature's plan names its PostHog events; check them after ship. Never send PII.
- [ ] **Step 3:** Docs entry. Suite green. Commit, review, push, PR.

### Task 7: Product pass and release

Branch `lifecycle/7-release`. PR base `lifecycle/6-observe`.

**Files:** `README.md`, `docs/domain/context.md` (roadmap, open decisions), `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` (`0.2.3` → `0.3.0`).

- [ ] **Step 1:** README: lead with the lifecycle (idea → setup → build → UAT → ship → perf → deploy → observe) as the one diagram, a table of all ten moments with their trigger, then the gates and memory. Keep install and commands as they are. Every claim checked against the code.
- [ ] **Step 2:** Bump both versions. Suite green.
- [ ] **Step 3:** Commit, review, push, PR. The PR body lists the stack's merge order and the post-merge steps (`claude plugin update myelin@myelin`, the Codex re-add, restart).
