#!/usr/bin/env bash
# code-quality — objective Bash 3.2 checks over the repo's .sh and .md files.

set -u

if ! SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd); then
  printf 'FAIL: setup — could not resolve the checker directory\n'
  exit 1
fi

if ! ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd); then
  printf 'FAIL: setup — could not resolve the repository root\n'
  exit 1
fi

LIB_DIR="$ROOT/tests/lib"

# shellcheck source=/dev/null
. "$LIB_DIR/scope.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/text-checks.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/lint.sh"
# shellcheck source=/dev/null
. "$LIB_DIR/fixtures.sh"

cleanup_fixtures() {
  if [ -n "$FIXTURE_DIR" ] && [ -d "$FIXTURE_DIR" ]; then
    rm -rf -- "$FIXTURE_DIR" >/dev/null 2>&1 || :
  fi
}

run_named_check() {
  local name=$1
  local checker=$2

  CHECK_REASON=

  if "$checker"; then
    printf 'PASS: %s\n' "$name"
    return 0
  fi

  printf 'FAIL: %s — %s\n' "$name" "${CHECK_REASON:-check failed}"
  return 1
}

run_repo_checks() {
  local status=0

  run_named_check 'bash syntax' check_bash_syntax || status=1
  run_named_check 'whitespace' check_whitespace || status=1
  run_named_check 'final newline' check_final_newline || status=1
  run_named_check 'shellcheck' check_shellcheck || status=1

  return "$status"
}

main() {
  local fixtures_only=0

  if [ "$#" -eq 1 ] && [ "$1" = '--fixtures-only' ]; then
    fixtures_only=1
  elif [ "$#" -ne 0 ]; then
    printf 'FAIL: arguments — unknown argument: %s\n' "$1"
    exit 2
  fi

  trap cleanup_fixtures EXIT

  if ! run_fixture_matrix; then
    printf 'FAIL: fixtures — %s\n' "${CHECK_REASON:-fixture matrix failed}"
    exit 1
  fi

  if [ "$fixtures_only" -eq 0 ]; then
    # shellcheck disable=SC2034 # read by lib/scope.sh
    SCOPE_FILE="$FIXTURE_DIR/in-scope-paths"

    if ! collect_scope_paths; then
      printf 'FAIL: file list — %s\n' "${CHECK_REASON:-could not collect in-scope files}"
      exit 1
    fi

    run_repo_checks || exit 1
  fi

  printf 'code-quality: pass\n'
}

main "$@"
