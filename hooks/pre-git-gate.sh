#!/usr/bin/env bash
# pre-git-gate.sh — require a review pass before git commit/push.
# scratch/wip/tmp branches skip; [quick] bypasses on non-protected branches.
# Fail-open on script error. Exit 2 blocks; stderr goes to Claude.

set -u
trap 'exit 0' ERR

GIT_WRITE_RE='(^|[;&| ])git[[:space:]]+(-[^[:space:]]+[[:space:]]+|-c[[:space:]]+[^[:space:]]+[[:space:]]+)*(commit|push)\b'
CLAUDE_REVIEW_RE='("skill"[[:space:]]*:[[:space:]]*"(simplify|pr-review|pr_review|code-review(:code-review)?)"|<command-name>(pr-review|pr_review|code-review|simplify|review))'
CODEX_CALL_RE='"type":"(custom_tool_call|function_call)"'
CODEX_REVIEW_RE='(cat|sed|head|tail|nl|bat)[^"]{0,40}skills/(simplify|pr-review|pr_review|code-review)/SKILL\.md'

is_bash_tool_call() {
  printf '%s' "$1" | grep -q '"tool_name"[[:space:]]*:[[:space:]]*"Bash"'
}

is_git_write() {
  printf '%s' "$1" | grep -qE "$GIT_WRITE_RE"
}

is_skipped_branch() {
  case "$1" in
    scratch/*|wip/*|tmp/*) return 0 ;;
  esac

  return 1
}

is_protected_branch() {
  case "$1" in
    main|master|develop|release*) return 0 ;;
  esac

  return 1
}

has_quick_bypass() {
  local branch="$1" cmd="$2"

  if is_protected_branch "$branch"; then
    return 1
  fi

  printf '%s' "$cmd" | grep -q '\[quick\]'
}

has_claude_review() {
  local n

  n=$(grep -cE "$CLAUDE_REVIEW_RE" "$1") || n=0
  [ "$n" -gt 0 ]
}

has_codex_review() {
  local n

  n=$(grep -E "$CODEX_CALL_RE" "$1" | grep -cE "$CODEX_REVIEW_RE") || n=0
  [ "$n" -gt 0 ]
}

has_review_evidence() {
  local transcript="$1"

  if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
    return 1
  fi

  # Evidence = real invocation, never prose: canon names these words.
  has_claude_review "$transcript" || has_codex_review "$transcript"
}

print_active_plans() {
  local plans="$1/.knowledge/state/plans.md" active

  if [ ! -f "$plans" ]; then
    return 0
  fi

  active=$(grep -B2 '^- status: active' "$plans" | grep '^## ' | head -3)

  if [ -n "$active" ]; then
    echo "Active plans to reconcile at SHIP:"
    echo "$active"
  fi

  return 0
}

print_block_message() {
  local branch="$1" cwd="$2"

  echo "myelin git-gate: no review pass detected this session on branch '$branch'."
  echo "Before committing: run /pr-review (or /simplify for quality-only), then retry."
  echo "(Mechanism: this gate is satisfied by an actual Skill invocation of pr-review/code-review/simplify in this session's transcript — running one is sufficient; no need to inspect the hook.)"
  echo "Do not route around this gate (branch renames, message markers); only the user may bypass it."
  print_active_plans "$cwd"
}

main() {
  local input cmd cwd branch transcript

  input=$(cat 2>/dev/null || true)

  is_bash_tool_call "$input" || exit 0
  command -v jq >/dev/null 2>&1 || exit 0

  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
  is_git_write "$cmd" || exit 0

  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""
  branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null) || exit 0

  [ -n "$branch" ] || exit 0
  is_skipped_branch "$branch" && exit 0
  has_quick_bypass "$branch" "$cmd" && exit 0

  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || transcript=""
  has_review_evidence "$transcript" && exit 0

  print_block_message "$branch" "$cwd" >&2
  exit 2
}

main
