#!/usr/bin/env bash
# stop-verify.sh — require verification evidence for done-claims.
# Fail-open on script error. Exit 2 blocks the stop; stderr goes to Claude.

set -u
trap 'exit 0' ERR

CLAIM_RE='(is (now )?complete|all (tests )?pass|working now|is (now )?fixed|fully (done|working)|everything is (done|complete))'
VERIFY_CMDS='pnpm (run )?(test|build|check|typecheck)|npm (run )?(test|build)|yarn (test|build)|vitest|jest|pytest|go test|cargo (test|check)|xcodebuild|swift test|tsc\b|eslint|ruff|make (test|check)'
CLAUDE_EVIDENCE_RE='"command"[[:space:]]*:[[:space:]]*"[^"]*('"$VERIFY_CMDS"')'
CODEX_CALL_RE='"type":"(custom_tool_call|function_call)"'
CODEX_EVIDENCE_RE='(cmd|command)[^a-zA-Z]{1,6}[^"]{0,200}('"$VERIFY_CMDS"'|bash tests/run-tests)'
BLOCK_MESSAGE="myelin stop-verify: a completion claim was made but no test/build/check command ran this session. Run the project's verification (see CLAUDE.md / package.json scripts) and report the actual output — or state explicitly why verification does not apply."

is_stop_hook_active() {
  printf '%s' "$1" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'
}

claim_count() {
  local input="$1" transcript="$2" last n

  last=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null) || last=""

  if [ -n "$last" ]; then
    n=$(printf '%s' "$last" | grep -icE "$CLAIM_RE") || n=0
  else
    n=$(tail -c 8000 "$transcript" | grep -icE "$CLAIM_RE") || n=0
  fi

  echo "$n"
}

has_claude_evidence() {
  local n

  n=$(tail -n 500 "$1" | grep -cE "$CLAUDE_EVIDENCE_RE") || n=0
  [ "$n" -gt 0 ]
}

has_codex_evidence() {
  local n

  n=$(tail -n 500 "$1" | grep -E "$CODEX_CALL_RE" | grep -cE "$CODEX_EVIDENCE_RE") || n=0
  [ "$n" -gt 0 ]
}

main() {
  local input transcript

  input=$(cat 2>/dev/null || true)

  is_stop_hook_active "$input" && exit 0
  command -v jq >/dev/null 2>&1 || exit 0

  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
  [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

  [ "$(claim_count "$input" "$transcript")" -eq 0 ] && exit 0

  has_claude_evidence "$transcript" && exit 0
  has_codex_evidence "$transcript" && exit 0

  echo "$BLOCK_MESSAGE" >&2
  exit 2
}

main
