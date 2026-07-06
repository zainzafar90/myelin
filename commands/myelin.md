---
description: Myelin — next|day|week|debt|reviews recaps across stamped projects
argument-hint: next | day | week | debt | reviews
---

Mode: $ARGUMENTS (default: day)

You are producing the user's myelin recap.

Read the project registry at `~/.myelin/registry.txt` (or
`$MYELIN_HOME/registry.txt`). Ignore `#` lines. For each listed project that
exists, gather data with cheap shell commands. Never read whole transcripts.

## Mode `day` (also the default)

For each project, run `git -C <path> log --all --since=midnight --oneline --stat`.
If that is empty, fall back to `--since="24 hours ago"`. Also read
`.knowledge/state/plans.md`.

Report per active project:

- commits (count and subjects)
- files touched
- plans that changed status today
- new debt entries (grep today's date in `state/debt.md`)

End with a one-line cross-project summary.

## Mode `week`

Same as `day`, but with `--since="7 days ago"`. Also report:

- plans shipped vs punted this week
- debt added vs resolved (entries removed)
- any project with zero activity, listed as dormant

## Mode `debt`

Do not grep ledgers. Run `${CLAUDE_PLUGIN_ROOT}/bin/myelin-doctor` first. It
prints one row per registry project, plus totals.

Then for each `ok` or `partial` project, run
`${CLAUDE_PLUGIN_ROOT}/bin/myelin-debt list <repo>`. It lists open items only,
as TSV: `id status severity date format line title`.

Build one table: project | id | title | severity | age (days from date) | where.

- Sort by severity (high, medium, unknown, low), then oldest first.
- Flag items older than 30 days.
- Next to each project's total, show its unparsed count
  (`${CLAUDE_PLUGIN_ROOT}/bin/myelin-debt unparsed <repo>`).
- List `missing`, `no-ledger` and `partial` projects explicitly, with the
  doctor's `candidate:` paths.
- Never treat missing, no-ledger or unreadable projects as zero debt. Say
  "unknown" for them.

## Mode `reviews`

For each project, list the commits from the last 14 days
(`git log --all --since="14 days ago" --format="%h %s"`, newest 20) and
cross-check them against `state/reviews.md`.

A commit absent from the ledger, or marked `reviewed: no`, is UNREVIEWED. List
these grouped by project, oldest first. For each group, suggest:
"run /pr-review in <project> for <sha-range>".

## Mode `next`

Answer one question: *what needs the user?* Gather per project, cheaply and in
this order. Then rank across ALL projects into a single list.

1. **Unreviewed agent commits.** Use the `reviews` logic, but give only the
   count, the oldest sha and a one-line subject per project. These rot fastest.
2. **High and medium debt.** Run
   `grep -B1 '^- severity: \(high\|med\)' state/debt.md` and take the age from
   `- date:`. Show only the oldest 1-2 per project.
3. **Stalled active plans.** Find `- status: active` in `state/plans.md` where
   the project has no commits in 7 days (`git log --since="7 days ago" -1`).

Output ONE ranked table: rank | project | what | why now | one command to act
(for example `/pr-review` or `/myelin debt`).

- Max 7 rows. Cut, don't scroll.
- Below the table, one line per skipped category ("3 low-debt items not shown").
- Ranking: unreviewed (oldest first) > high debt > medium debt older than 30
  days > stalled plans.

This is a decision queue, not a report. No history, no narration.

## Output

Compact markdown tables, no filler. Empty-case rules per mode:

- `day`, `week`: if no project has git or journal activity in the window, say
  so in one line and stop.
- `debt`: omit projects with zero open items from the table. Always list
  missing, no-ledger and partial projects. Say "no recorded debt" and stop only
  if every project is reachable and none has an open item.
- `reviews`: same logic, applied to unreviewed commits.
- `next`: if the ranked list is empty, say "Nothing needs you." and stop.
