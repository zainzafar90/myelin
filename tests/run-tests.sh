#!/usr/bin/env bash
# run-tests — hook and contract tests, plain bash. Run from anywhere.

set -u

cd "$(dirname "$0")/.." || exit 1

FIXTURES=tests/fixtures
FAKEPROJ="$FIXTURES/fakeproj"
SESSION_INPUT="$FIXTURES/session-start-input.json"
INJECTION_BUDGET=120

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/myelin-tests.XXXXXX") || exit 1
FAKEREPO="$WORK_DIR/repo"
NO_REPO="$WORK_DIR/not-a-repo"
SESSION_OUT="$WORK_DIR/session-start.out"

pass=0
fail=0

cleanup_work_dir() {
  rm -rf -- "$WORK_DIR"
}

record() {
  local ok=$1
  local name=$2
  local detail=${3:-}

  if [ "$ok" -eq 0 ]; then
    pass=$((pass + 1))
    echo "PASS: $name"
  else
    fail=$((fail + 1))
    echo "FAIL: $name$detail"
  fi
}

# t <name> <expected_exit> <cmd...>
t() {
  local name=$1
  local want=$2
  local got
  shift 2

  "$@" >"$WORK_DIR/out" 2>"$WORK_DIR/err"
  got=$?

  if [ "$got" -eq "$want" ]; then
    record 0 "$name"
  else
    record 1 "$name" " (exit $got, wanted $want)"
  fi
}

assert_output_has() {
  local name=$1
  local needle=$2

  grep -q "$needle" "$SESSION_OUT"
  record $? "$name"
}

stop_input() {
  printf '{"transcript_path":"%s","stop_hook_active":%s}' "$FIXTURES/transcript-$1.jsonl" "$2"
}

stop_missing_input() {
  printf '{"transcript_path":"/nonexistent","stop_hook_active":false}'
}

gate_input() {
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"transcript_path":"%s","cwd":"%s"}' \
    "$1" "$FIXTURES/transcript-$2.jsonl" "$3"
}

run_stop() { stop_input "$@" | bash hooks/stop-verify.sh; }
run_stop_missing() { stop_missing_input | bash hooks/stop-verify.sh; }
run_gate() { gate_input "$@" | bash hooks/pre-git-gate.sh; }
run_gate_file() { bash hooks/pre-git-gate.sh < "$1"; }
run_session_start() { bash hooks/session-start.sh < "$1"; }

gate_on_branch() {
  git -C "$FAKEREPO" checkout -q "$@"
}

setup_fake_project() {
  mkdir -p "$FAKEPROJ/.knowledge/state"
  printf '## Plan A\n- status: active\n## Plan B\n- status: shipped\n' > "$FAKEPROJ/.knowledge/state/plans.md"
  printf '## Debt X\n- severity: high\n## Debt Y\n- severity: low\n' > "$FAKEPROJ/.knowledge/state/debt.md"
}

setup_fake_repo() {
  mkdir -p "$FAKEREPO" "$NO_REPO"
  git -C "$FAKEREPO" init -q -b main
  git -C "$FAKEREPO" commit -q --allow-empty -m init
  mkdir -p "$FAKEREPO/.knowledge/state"
  printf '## Ship embeds v2\n- status: active\n' > "$FAKEREPO/.knowledge/state/plans.md"
}

test_session_start() {
  local lines

  t "session-start exits 0" 0 run_session_start "$SESSION_INPUT"
  run_session_start "$SESSION_INPUT" > "$SESSION_OUT"

  assert_output_has "canon injected" "Myelin Canon"
  assert_output_has "plan count" "active plans: 1"
  assert_output_has "debt count" "debt: 2 (high: 1)"

  lines=$(wc -l < "$SESSION_OUT" | tr -d ' ')
  [ "$lines" -le "$INJECTION_BUDGET" ]
  record $? "injection budget ($lines lines)"

  t "session-start fail-open on empty stdin" 0 run_session_start /dev/null
  t "knowledge style contract" 0 bash tests/contract/knowledge-style.sh
}

test_stop_verify() {
  t "stop blocks claim w/o evidence" 2 run_stop claim-no-evidence false
  t "stop allows claim with evidence" 0 run_stop claim-with-evidence false
  t "stop respects stop_hook_active" 0 run_stop claim-no-evidence true
  t "stop fail-open on missing transcript" 0 run_stop_missing
  t "stop blocks when only test-word evidence" 2 run_stop claim-test-word false
  t "stop catches 'is now fixed' claim" 2 run_stop claim-test-word false
}

test_gate_blocking() {
  local no_evidence=claim-no-evidence

  t "gate blocks commit w/o review on main" 2 run_gate "git commit -m msg" "$no_evidence" "$FAKEREPO"
  t "gate allows commit with review evidence" 0 run_gate "git commit -m msg" with-review "$FAKEREPO"
  t "gate ignores non-git commands" 0 run_gate "ls -la" "$no_evidence" "$FAKEREPO"
  t "gate blocks escaped-quote commit on main" 2 run_gate_file "$FIXTURES/gate-escaped-quote-input.json"
  t "gate blocks double-space git  commit on main" 2 run_gate "git  commit -m msg" "$no_evidence" "$FAKEREPO"
  t "gate blocks git -c flag commit on main" 2 run_gate "git -c user.name=x commit -m msg" "$no_evidence" "$FAKEREPO"
}

test_gate_branches() {
  local no_evidence=claim-no-evidence

  gate_on_branch -b scratch/spike
  t "gate skips scratch branches" 0 run_gate "git commit -m msg" "$no_evidence" "$FAKEREPO"

  gate_on_branch -b feature/x
  t "gate honors [quick] on non-protected branch" 0 run_gate "git commit -m [quick] wip" "$no_evidence" "$FAKEREPO"

  gate_on_branch main
  t "gate ignores [quick] on protected branch" 2 run_gate "git commit -m [quick] wip" "$no_evidence" "$FAKEREPO"
  t "gate blocks when review only MENTIONED (canon text)" 2 run_gate "git commit -m msg" canon-mention "$FAKEREPO"
  t "gate fail-open outside a git repo" 0 run_gate "git commit -m msg" claim-no-evidence "$NO_REPO"
}

main() {
  trap cleanup_work_dir EXIT

  setup_fake_project
  setup_fake_repo

  test_session_start
  test_stop_verify
  test_gate_blocking
  test_gate_branches

  t "code-quality contract" 0 bash tests/contract/code-quality.sh

  echo
  echo "$pass passed, $fail failed"
  [ "$fail" -eq 0 ]
}

main "$@"
