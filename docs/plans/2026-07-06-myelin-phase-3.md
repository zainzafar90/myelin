# Myelin phase 3 plan: the map

> **For agentic workers:** use the `superpowers:subagent-driven-development` or `superpowers:executing-plans` skill. Read [HANDOFF.md](../../HANDOFF.md) first. **Every task here has an entry gate. Check it before building. Building a phase 3 task before its gate passes is a defect, not initiative.**

**Goal:** Turn accumulated data into a navigable map: mined knowledge nodes, entropy trends, comprehension repair, one-command project onboarding, visual dashboards, and an evidence-based skill scoreboard.

**Global entry criteria:** Phase 2 tagged `v0.2.0`; miner has run ≥14 consecutive nights; the user reading recaps ≥4 days/week (metric #5 — if failing, fix recap format instead of building Phase 3); lessons flow used at least twice.

**Architecture:** All Phase 3 features are *consumers* of Phase 1-2 data (ledgers, journals, recaps, transcripts). No new capture mechanisms, no new formats beyond the four spec'd node types. Dashboards are generated Artifacts, not servers.

## Global constraints

- HANDOFF.md invariants, esp. ontology cap (4 node types, frontmatter schema: type, project, created, source, links) and miner-proposes-never-applies.
- Graph nodes live in `<project>/.knowledge/{decisions,preferences,gotchas,map}/`, one markdown file per node, filename = kebab-case slug = wikilink target.
- Injection budget unchanged (≤120 lines): graph data NEVER auto-injects beyond the INDEX summary line counts; deep nodes are pull-only.

---

### Task 1: Graph mining (miner duty extension)

**Gate:** ≥2 weeks of miner runs; PROPOSED.md lesson flow demonstrably working (approvals happened).

**Interfaces:** Miner gains duty: from each active project's daily transcripts + journal, propose node files — full file content (frontmatter: `type`, `project`, `created`, `source`, `links`) in a `## Proposed nodes` recap section. Approval convention: "apply today's proposed nodes for <project>" → assistant writes the files. Node sources: corrections→`preference`, debugging resolutions→`gotcha`, architecture choices in plan/spec discussions→`decision`, package/module explanations→`map`.

**Acceptance:** after one approved batch, `.knowledge/` contains ≥1 valid node per type across the registry; every node passes a frontmatter lint (add `myelin doctor` check: required keys present, `type` in the 4, `links` targets are slugs); Obsidian opened on a stamped project renders the graph.

---

### Task 2: Codex brief auto-inclusion

**Gate:** ≥10 total graph nodes exist in the target project (below that, inclusion is noise).

**Interfaces:** `codex/brief-template.md` (create in this task if Phase 1 left it minimal) gains a `## Project knowledge` section; the HANDOFF canon row instructs: before filling a brief, grep the target project's `gotchas/` and `preferences/` frontmatter `links`+filenames for the files in scope, paste matching nodes (≤5, whole file) into the brief.

**Acceptance:** one real Codex delegation in a stamped project shows relevant gotcha/preference content inside the brief; Codex output respects a stamped preference it would otherwise have violated (pick a testable one, e.g. CSS-variables rule).

---

### Task 3: Entropy watch (miner duty)

**Gate:** ≥30 days of git history since Phase 1 (baseline window).

**Interfaces:** New script `bin/myelin-entropy <project-path>` (deterministic, testable, no model): emits one JSON line `{"date":…,"project":…,"churn14":<lines changed in commits that touch lines added <14 days earlier — approximate via git log --numstat window diff>,"dupTokens":<jscpd if installed, else -1>,"bigFiles":<count of source files >400 lines>,"todos":<grep -rc TODO|FIXME count>}` appended to `~/.myelin/metrics/<project-slug>.jsonl`. Miner calls it per active project; weekly recap renders trend arrows (▲▼–) vs 4-week mean and proposes a `/simplify` + `improve` pass when churn14 or dupTokens rises >25% two weeks running.

**Acceptance:** script unit-tested against a fixture repo with known history; metrics files accumulate; one weekly recap shows the trend table.

---

### Task 4: Comprehension repair (miner duty)

**Gate:** graph mining (Task 1) live.

**Interfaces:** Miner flags: debugging activity (STUCK-moment evidence in transcript) in files whose git history contains no user-authored commit AND which appear in no `reviewed: yes` ledger line → recap section `## Comprehension gaps` listing file + suggestion: "run explaining-code on <file>; file the output as a map/ node". The explaining-code output, once produced in any session, is proposed as a `map` node like Task 1 nodes.

**Acceptance:** seeded test — debug a file authored entirely by Codex without reviewing it; next recap flags it; running the suggested walkthrough yields an approvable map node.

---

### Task 5: `/myelin-init` — one-command project onboarding

**Gate:** stamping has been done manually ≥3 times (Phase 1 Task 8) so the ritual is proven.

**Interfaces:** `commands/myelin-init.md`: in cwd — (1) refuse politely if `.knowledge/` exists; (2) copy skeleton (same idempotent guards as Phase 1 Task 8 commands); (3) ask ONE question: design voice (emil | project-tokens | vercel | custom) and write `state/DESIGN.md`; (4) detect stack (package.json / *.xcodeproj / pubspec.yaml / pyproject.toml) and write a thin project `CLAUDE.md` + `AGENTS.md` (build/test commands, stack line, myelin pointer) only if absent; (5) append path to `~/.myelin/registry.txt`; (6) print what was created.

**Acceptance:** run in a fresh scratch repo → all six behaviors verified; run twice → second run is a no-op with a clear message; `myelin doctor` passes with the new registry entry.

---

### Task 6: Dashboards (Artifact views)

**Gate:** the data each view renders exists (debt entries ≥5 across registry for the heatmap; 14+ days of metrics for trends).

**Interfaces:** `commands/myelin.md` gains mode `dashboard [debt|plans|reviews|entropy]`: assistant builds a single self-contained HTML file (scratchpad) and publishes via the Artifact tool — debt heatmap (severity×age grid per project), plan lifecycle board (kanban columns from plans.md statuses), review coverage bars, entropy trend lines. Data embedded at build time; a dashboard is a snapshot, not an app (Later list guards live servers).

**Acceptance:** each of the four renders from real data; total build ≤1 Artifact call each; no external resources (CSP-safe).

---

### Task 7: Skill scoreboard (canon tuning)

**Gate:** ≥3 weeks of transcript data AFTER Phase 1 hooks went live (pre-myelin history is baseline, not signal).

**Interfaces:** Weekly miner duty: count moment-skill invocations (grep transcripts for Skill-tool calls of canon-named skills) vs trigger opportunities (heuristic: sessions with error/bug keywords = STUCK opportunities, etc.); join with correction mining (lessons proposed per project-week) and churn14. Output in weekly recap: table skill | fired | should-have | trend | verdict (keep / demote / swap-candidate). Canon changes remain a human edit to `canon/ROUTING.md` — the scoreboard is evidence, never an actuator.

**Acceptance:** first scoreboard renders with honest `should-have` uncertainty noted; at least one keep/demote decision gets made from it (recorded in a `decision` node in the myelin repo's own `.knowledge/` — yes, stamp myelin itself by then).

---

### Task 8: Phase 3 close-out

- [ ] `myelin doctor` green including node lint; all tests green.
- [ ] Metrics review against HANDOFF success metrics 1-5 — write results into `docs/domain/context.md` (or an ADR) as a short retrospective.
- [ ] Re-read the Later list with the retrospective in hand; promote at most ONE item only if a month of evidence demands it.
- [ ] `git tag v0.3.0`.

## Self-review

Coverage: graph (T1), brief inclusion (T2), mining duties (T3, T4, T7), views (T6), Phase 3 `/myelin-init` (T5). All Later-list items remain excluded. No placeholders: every task states exact interfaces, gates, and acceptance; deterministic components (entropy script, init command, node lint) are specified to testable precision; model-driven components state their output contracts and approval conventions. Consistency: node schema matches the one above; registry/doctor/injection contracts unchanged from Phases 1-2.
