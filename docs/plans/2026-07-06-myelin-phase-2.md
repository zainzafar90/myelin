# Myelin phase 2 plan: the loop

> **For agentic workers:** use the `superpowers:subagent-driven-development` or `superpowers:executing-plans` skill. Interfaces and acceptance criteria are exact. Implementation detail is yours where marked. Read [HANDOFF.md](../../HANDOFF.md) first. Its invariants override any convenient shortcut.

**Goal:** Close the data loop. Sessions leave breadcrumbs. A nightly Haiku miner turns them into recaps, lesson proposals and orphan-commit audits. A CLI keeps the system healthy.

**Entry criteria:** Phase 1 tagged `v0.1.0`, smoke test passed, at least 3 stamped projects in `~/.myelin/registry.txt`, and hooks live for at least 3 days without the user disabling them.

**Architecture:** A `SessionEnd` hook appends JSONL breadcrumbs per project (capture is dumb and instant). A launchd job runs `claude -p` headless each evening. The miner prompt fans out one Haiku subagent per *active* project and writes recap files and proposals. Nothing is auto-applied: lessons and ledger changes land as proposals for the user to approve. `bin/myelin` gives doctor, status and update.

**Tech Stack:** Bash, JSONL, launchd (macOS), `claude -p` headless with `--model haiku` subagents via the miner prompt.

## Global constraints

- All [HANDOFF.md](../../HANDOFF.md) invariants. Especially: no model calls in hooks; the miner proposes and never silently writes ledgers or lessons; Haiku-only mining; skip projects with no activity that day; at most 10 miner subagents per night.
- The journal format is a grep-contract (below). Its readers are the miner and `/myelin`. Never break it.
- Miner outputs live in `~/.myelin/recaps/` and `lessons/PROPOSED.md` in this repo. They never go inside stamped projects, except as proposal blocks in recap files.

---

### Task 1: SessionEnd breadcrumb hook

**Files:** Create `hooks/session-end.sh`; modify `hooks/hooks.json` (add `SessionEnd`); extend `tests/run-tests.sh` + fixture.

**Interfaces:**
- Consumes: SessionEnd stdin JSON (`cwd`, `session_id`).
- Produces: one appended line to `<cwd>/.knowledge/journal.jsonl` **iff** `<cwd>/.knowledge/` exists (unstamped projects are untouched). Line schema (exact keys, one line):
  `{"ts":"<ISO8601>","session":"<id>","branch":"<git branch or empty>","dirty":<int changed files>,"diffstat":"<last line of git diff --stat HEAD or empty>"}`

**Steps:**
- [ ] Failing tests: stamped cwd → appends valid JSON line (validate with `python3 -m json.tool`); unstamped cwd → no file created; empty stdin → exit 0 (fail-open); two runs → two lines (append, not overwrite).
- [ ] Implement (~25 lines, same fail-open pattern as Phase 1 hooks; derive fields with `git -C "$CWD"`; ISO ts via `date -u +%Y-%m-%dT%H:%M:%SZ`).
- [ ] Wire `SessionEnd` into `hooks.json`; tests green; commit `feat: SessionEnd breadcrumbs`.

---

### Task 2: Miner prompt — `routines/nightly-miner.md`

**Files:** Create `routines/nightly-miner.md`.

**Interfaces:**
- Consumed by: Task 4's headless invocation (`claude -p "$(cat routines/nightly-miner.md)"`).
- Produces (contract): `~/.myelin/recaps/YYYY-MM-DD.md` (daily), and appends to `lessons/PROPOSED.md`. The weekly rollup `recaps/YYYY-Www.md` on Fridays **reuses daily files and never re-mines transcripts**.

**Miner duties (Phase 2 scope only — recap, corrections, orphans):**
1. Read `~/.myelin/registry.txt`. For each project, activity check = journal lines with today's date OR `git log --since=midnight` non-empty. Skip inactive. Cap: if >10 active, process the 10 with most commits and note the skipped ones in the recap (no silent truncation).
2. Per active project, spawn ONE Haiku subagent (Agent tool, `model: haiku`) with a self-contained prompt: project path, today's journal lines, `git log --since=midnight --oneline --stat`. It returns: 3-6 bullet summary; corrections found in that project's transcript files under `~/.claude/projects/` **modified today only** (user messages that contradict/redirect the assistant — quote ≤120 chars each); commit list.
3. Orphan detection (main context, cheap): per project, `git log --all --since="14 days ago" --format="%h %D %s"` cross-checked against `.knowledge/state/reviews.md`; absent or `reviewed: no` → orphan.
4. Write `recaps/YYYY-MM-DD.md`: per-project sections, cross-project one-liner, `## Orphan commits` table (project | sha | age | subject), `## Proposed ledger updates` (drift you noticed — proposals only).
5. Corrections → append to `lessons/PROPOSED.md` as: `- [ ] (YYYY-MM-DD, <project>) <candidate lesson, imperative, ≤2 lines> — evidence: "<quote>"`. Dedup against both PROPOSED.md and LESSONS.md before appending (same lesson twice = skip and increment a `(seen Nx)` counter on the existing line).
6. Never edit `LESSONS.md`, any `.knowledge/state/*`, or the canon. Proposals only.

**Steps:**
- [ ] Write the prompt implementing exactly the above (full text, no summaries of duties — the miner has zero context).
- [ ] Dry-run: `claude -p "$(cat routines/nightly-miner.md)" --permission-mode acceptEdits` on a day with real activity; verify recap file exists, sections present, PROPOSED.md well-formed, no ledger/canon writes (`git -C <myelin repo> status` clean except `lessons/PROPOSED.md`; stamped projects untouched per `git status` in each).
- [ ] Commit `feat: nightly miner prompt (recap + corrections + orphans)`.

---

### Task 3: Lessons flow — propose → approve → inject

**Files:** Create `commands/lessons.md`; `lessons/PROPOSED.md` (seeded header).

**Interfaces:**
- `/lessons` (no args): show PROPOSED.md checkboxes + current LESSONS.md top-5.
- `/lessons approve <n>[,<n>…]`: move proposal(s) into `LESSONS.md` (imperative wording, newest near top), delete from PROPOSED.md.
- `/lessons reject <n>[,<n>…]`: delete from PROPOSED.md.
- `/lessons demote <n>`: move a LESSONS.md bullet below the top-5 fold.
- Contract with `session-start.sh` (unchanged): top 5 `^- ` bullets of LESSONS.md are what gets injected — ordering IS the priority mechanism.

**Steps:**
- [ ] Write `commands/lessons.md` implementing the four modes (it's a prompt file: instruct exact file edits, preserve `- [ ]` numbering by list position).
- [ ] Verify live: seed 2 fake proposals, approve 1, reject 1, confirm LESSONS.md and next-session injection reflect it.
- [ ] Commit `feat: /lessons approval flow`.

---

### Task 4: Scheduling — launchd + headless run

**Files:** Create `bin/myelin-mine` (wrapper) and `ops/com.myelin.mine.plist`.

**Interfaces:**
- `bin/myelin-mine`: runs `claude -p "$(cat <repo>/routines/nightly-miner.md)" --permission-mode acceptEdits`, with logging to `~/.myelin/logs/mine-YYYY-MM-DD.log`; skips (exit 0, logged) if no registry project had activity — the cheap check duplicates the miner's own gate so idle days cost zero tokens.
- plist: daily 18:00 local, `RunAtLoad false`, loaded via `launchctl load ~/Library/LaunchAgents/…` (installed by copy, path expanded — launchd doesn't do `~`).

**Steps:**
- [ ] Write wrapper + plist (full contents; log stdout+stderr; guard with a lockfile so overlapping runs exit early).
- [ ] Install: copy plist to `~/Library/LaunchAgents/`, `launchctl load`, then `launchctl start com.myelin.mine` once manually; verify log + recap output.
- [ ] Commit `feat: nightly mining via launchd`.
- **Note:** weekly rollup = same wrapper; the miner prompt branches on `date +%u` == 5. Keep one schedule, not two.

---

### Task 5: `bin/myelin` CLI — doctor | status | update | recap

**Files:** Create `bin/myelin` (~120 lines bash, no deps).

**Interfaces / acceptance:**
- `doctor`: every skill named in `canon/ROUTING.md` resolves under `~/.claude/skills/` or `~/.claude/plugins/cache/**/skills/` (reuse Phase 1 Task 2 Step 3 logic, but *parse names from the canon* so new routes are auto-checked); hooks in `hooks.json` exist + executable; registry paths exist; commands present in installed plugin copy. Exit non-zero listing each failure; `0 problems` otherwise. Also prints empty lanes (lines under `## Empty lanes`).
- `status`: plugin version (plugin.json), installed-copy freshness (diff repo vs cache mtime), last recap date, PROPOSED.md pending count, registry size, last mine log tail(3).
- `update`: `git -C <myelin repo> pull` (if remote exists), `claude plugin update myelin`, then `doctor`.
- `recap`: `open`/`cat` today's recap (fallback: latest).

**Steps:**
- [ ] Failing tests in `tests/run-tests.sh`: `doctor` exits 0 on healthy repo; exits non-zero after `mv` -ing a hook away (restore after); `status` prints version line.
- [ ] Implement; `chmod +x`; symlink `ln -sf <myelin repo>/bin/myelin /usr/local/bin/myelin` (or `~/bin` if not writable).
- [ ] Tests green; commit `feat: myelin CLI (doctor/status/update/recap)`.

---

### Task 6: Review-ledger reconciliation

**Files:** Modify `routines/nightly-miner.md` (duty 3 extension); no project files touched by hand.

**Interfaces:** When the miner finds transcript evidence that `/pr-review` ran against commits absent from `reviews.md`, it emits proposal lines in the recap: `- propose: <project> reviews.md += "<sha> <branch> reviewed: yes <date> <subject>"`. `/myelin reviews` (Phase 1) already surfaces unreviewed state; approval = the user says "apply the review-ledger proposals from today's recap" in any session — the assistant applies them (this is a documented convention, not a hook; automation of apply is Later-listed).

**Steps:**
- [ ] Extend miner prompt; dry-run on a day after running `/pr-review` somewhere; verify proposal lines render.
- [ ] Commit `feat: miner proposes review-ledger reconciliation`.

---

### Task 7: Phase 2 smoke test + tag

- [ ] `bash tests/run-tests.sh` fully green.
- [ ] `myelin doctor` → 0 problems.
- [ ] Force one full nightly cycle manually (`bin/myelin-mine`); verify: recap written, proposals present-or-explicitly-none, orphan table correct against a known-unreviewed commit, no unauthorized writes anywhere (`git status` in myelin + all stamped projects).
- [ ] Next morning check: SessionStart in a stamped project reflects any approved lessons; `/lessons` shows pending proposals.
- [ ] `git tag v0.2.0`.

## Self-review

Duties 1-4 and the Phase 2 list all mapped (breadcrumbs→T1, miner→T2, lessons→T3, schedule→T4, CLI→T5, reviews→T6). Duties 5-7 (entropy, comprehension, canon-tuning/scoreboard) correctly deferred to Phase 3. No placeholders: every contract, schema, and acceptance criterion is explicit; implementation freedom is bounded by tests and grep-contracts. Consistency: journal schema keys match between T1 (writer) and T2/T4 (readers); LESSONS.md top-5 contract unchanged from Phase 1 Task 3.
