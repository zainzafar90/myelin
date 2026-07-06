#!/usr/bin/env bash
# session-start.sh — inject canon, top lessons and project state summary.
# Budget: <=120 lines total. Fail-open: any error exits 0.

set -u
trap 'exit 0' ERR

ROOT="${MYELIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}}"
readonly ROOT
readonly CANON_LINES=50
readonly LESSON_COUNT=5
readonly DEBT_TOP_COUNT=5
readonly DEBT_TOOL="$ROOT/bin/myelin-debt"

read_cwd() {
  local input="$1"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true
  fi

  return 0
}

warn_if_jq_missing() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "- warning: jq not found — myelin commit/stop gates are disabled (brew install jq)"
  fi

  return 0
}

print_canon() {
  if [ -f "$ROOT/canon/ROUTING.md" ]; then
    head -n "$CANON_LINES" "$ROOT/canon/ROUTING.md"
  fi

  return 0
}

print_lessons() {
  if [ -f "$ROOT/lessons/LESSONS.md" ]; then
    echo ""
    echo "## Lessons (top 5 — apply these)"
    grep -m "$LESSON_COUNT" '^- ' "$ROOT/lessons/LESSONS.md" 2>/dev/null || true
  fi

  return 0
}

count_matches() {
  local pattern="$1" file="$2" n

  n=$(grep -c "$pattern" "$file" 2>/dev/null) || n=0
  echo "$n"
}

print_debt_top() {
  local brief="$1"

  echo "## Open debt (top 5)"
  printf '%s\n' "$brief" | sed -n "2,$((DEBT_TOP_COUNT + 1))p"
}

print_design_voice() {
  local k="$1" voice

  voice=$(sed -n 's/^- voice: //p' "$k/state/DESIGN.md" 2>/dev/null | head -1)

  if [ -n "$voice" ]; then
    echo "- design voice: $voice"
  fi

  return 0
}

print_project_state() {
  local cwd="$1" k="$1/.knowledge"
  local plans debt high brief="" summary reviews

  if [ -z "$cwd" ] || [ ! -d "$k/state" ]; then
    return 0
  fi

  echo ""
  echo "## Project state (.knowledge — authoritative)"

  plans=$(count_matches '^- status: active' "$k/state/plans.md")
  debt=$(count_matches '^## ' "$k/state/debt.md")
  high=$(count_matches '^- severity: high' "$k/state/debt.md")

  if [ -x "$DEBT_TOOL" ]; then
    brief=$("$DEBT_TOOL" brief "$cwd" "$DEBT_TOP_COUNT" 2>/dev/null) || brief=""
  fi

  summary=$(printf '%s\n' "$brief" | sed -n 1p)

  if [ -n "$summary" ]; then
    debt=$(printf '%s' "$summary" | sed -n 's/.*open=\([0-9]*\).*/\1/p')
    high=$(printf '%s' "$summary" | sed -n 's/.*high=\([0-9]*\).*/\1/p')

    if [ -z "$debt" ] || [ -z "$high" ]; then
      summary=""
      debt=0
      high=0
    fi
  fi

  reviews=$(count_matches 'reviewed: no' "$k/state/reviews.md")
  echo "- active plans: $plans | debt: $debt (high: $high) | unreviewed commits: $reviews"

  if [ -n "$summary" ] && [ "$debt" -gt 0 ]; then
    print_debt_top "$brief"
  fi

  print_design_voice "$k"
  echo "- details: read $k/INDEX.md"
}

main() {
  local input cwd

  input=$(cat 2>/dev/null || true)
  cwd=$(read_cwd "$input")

  warn_if_jq_missing
  print_canon
  print_lessons
  print_project_state "$cwd"
}

main
exit 0
