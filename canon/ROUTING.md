# Myelin Canon — how work routes (v1)

## Moments (these are mandatory, not suggestions)

| Moment | Trigger | Route |
|---|---|---|
| START | new feature / "build X" / behavior change | superpowers:brainstorming → grilling (stress-test the design) → superpowers:writing-plans → register plan in `.knowledge/state/plans.md` → Codex brief; too big/foggy for one session → wayfinder |
| SETUP | new repo or stack / first session in an unstamped repo | `myelin-stamp` → agree stack and layout with the user (codebase-design for module boundaries) → one test and one build command that pass, written in CLAUDE.md/AGENTS.md → permissions via fewer-permission-prompts or update-config allowlists, never skip-permissions → first commit through SHIP |
| STUCK | bug, error, failing test, "broken" | superpowers:systematic-debugging |
| UAT | user-visible change is code-complete, before SHIP | run (launch the real app) → drive each acceptance criterion end to end as a user, plus one failure path → web: browser-verify; iOS: the simulator tool; CLI/API: real commands against a running instance → evidence (screenshots, output) goes in the PR → any failure → STUCK |
| SHIP | done-claim, branch finish, commit/push | superpowers:verification-before-completion → ship (pr-review → UAT evidence present → ocd diff → lean → commit → pr-description) → reconcile ledger (close plans, punts → debt.md) |
| PERF | "slow", load or scale questions, bundle/memory size, before a launch | measure first and write the baseline number down → agree a budget with the user → platform tool: web chrome-devtools (debug-optimize-lcp, perf trace); backend query plans + a load test; mobile Instruments → change one thing, re-measure, keep it only if the number moved → record the budget in `.knowledge/state/DESIGN.md` or the plan. No optimisation without a number |
| DEPLOY | first deploy, CI change, a release | first time, the user steers: engineering:deploy-checklist → CI runs tests, lint and a migration check on every PR → secrets in the CI or host store, never the repo → a written rollback path. After that the agent owns it: green CI before merge → migration dry run → deploy → watch health and errors (OBSERVE) → roll back on a failed check. Never merge or deploy without the user's go-ahead |
| OBSERVE | prod error or crash / "what are users doing" / first errors or analytics setup | setup once with the user: Sentry and PostHog via their MCP or CLI, keys in env, releases tagged, alert rules → then the agent loops: Sentry issue → get_sentry_resource and details → STUCK (failing test first) → fix → link the issue. Each feature plan names its PostHog events; check them after ship. Never send PII |
| PARALLEL | 2+ independent tasks / a plan with separable phases | superpowers:dispatching-parallel-agents → one shared rules file every agent reads (scope, base branch, test command, review, ship, report) → one branch + worktree per agent → isolated test resources per run, never a shared DB → never `git stash` (shared across worktrees) → agents wait on their own jobs, no interim hand-backs → orchestrator re-runs the riskiest checks and records merge order for stacked PRs |
| HANDOFF | implementation delegated | codex:rescue with a filled brief (goal, files, invariants, acceptance, stop conditions) |

Escape hatch: user says "quick" or "raw" → skip soft routing, answer directly.
Punt rule: any "skip it for now" → add a `## ` entry to `.knowledge/state/debt.md` immediately (template at top of file; reuse a matching id instead of duplicating).
Debt loop: at task start check the injected open debt for related items; at finish mark touched items `- status: closed` + `- resolution: <date — reason — evidence>` (no evidence → stays open). A deferral never satisfies a required acceptance criterion.

## Domain shortlist (reference, not routing — fire from file context)

- Standards (any language, load at write AND review): coding-standards base; api-standards (server/backend), frontend-standards (UI), code-spacing (blank lines, lint-enforced where possible); <lang>-standards extends
- React/TS: typescript-standards, react-standards
- Swift/macOS: swiftui-expert, macos-swiftui-gotchas
- UI: ui (explore) / frontend-design (build) / ocd (review and last-mile pass); taste = project `.knowledge/state/DESIGN.md`
- UI acceptance (UAT): browser-verify — run app → attack the change → console clean → CWV → embed/dark/mobile checks; no partial hand-backs
- Architecture: codebase-design (deep-module vocabulary); audits → improve
- Bug fix: tdd (failing test first); over-engineering → lean
- Security: security-audit — fire on auth/input/query diffs

## Project state

If `.knowledge/INDEX.md` exists in cwd, it is authoritative for: active plans,
debt register, review status, design constitution. Read it before assuming
project context. Record state changes at SHIP, not "later".

## Empty lanes

SEO: none installed.
