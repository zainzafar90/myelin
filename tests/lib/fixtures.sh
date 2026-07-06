#!/usr/bin/env bash
# fixtures.sh — prove each text checker accepts good input and rejects bad.

make_fixture() {
  local name=$1
  local path=$2
  shift 2

  if ! printf '%s\n' "$@" > "$path"; then
    set_check_reason "fixture $name — could not create fixture"
    return 1
  fi
}

create_fixture_files() {
  make_fixture valid-phases.sh "$FIXTURE_DIR/valid-phases.sh" \
    '#!/usr/bin/env bash' \
    'set -u' \
    '' \
    'phase_one() {' \
    "  printf '%s\\n' one" \
    '}' \
    '' \
    '' \
    'phase_two() {' \
    "  printf '%s\\n' two" \
    '}' \
    '' \
    'phase_one' \
    'phase_two' || return 1

  make_fixture trailing-whitespace.sh "$FIXTURE_DIR/trailing-whitespace.sh" \
    '#!/usr/bin/env bash' \
    'set -u' \
    '' \
    "printf '%s\\n' trailing    " || return 1

  make_fixture missing-final-lf.sh "$FIXTURE_DIR/missing-final-lf.sh" \
    '#!/usr/bin/env bash' \
    'set -u' || return 1
  if ! printf '%s' "printf '%s\\n' missing-final-lf" >> "$FIXTURE_DIR/missing-final-lf.sh"; then
    set_check_reason 'fixture missing-final-lf.sh — could not create fixture'
    return 1
  fi

  make_fixture invalid-syntax.sh "$FIXTURE_DIR/invalid-syntax.sh" \
    '#!/usr/bin/env bash' \
    'if true; then' \
    "  printf '%s\\n' invalid"
}

fixture_assert() {
  local fixture_name=$1
  local checker=$2
  local expected=$3
  local path=$4
  local actual

  "$checker" "$path" >/dev/null 2>&1
  actual=$?

  if [ "$actual" -ne "$expected" ]; then
    set_check_reason "fixture $fixture_name — $checker expected exit $expected, got $actual"
    return 1
  fi

  printf 'PASS: fixture %s — %s (exit %s)\n' "$fixture_name" "$checker" "$expected"
}

assert_fixture_row() {
  local name=$1
  local path=$2
  local syntax_exit=$3
  local whitespace_exit=$4
  local newline_exit=$5
  local status=0

  fixture_assert "$name" check_bash_syntax "$syntax_exit" "$path" || status=1
  fixture_assert "$name" check_whitespace "$whitespace_exit" "$path" || status=1
  fixture_assert "$name" check_final_newline "$newline_exit" "$path" || status=1

  return "$status"
}

run_fixture_matrix() {
  local status=0

  if ! FIXTURE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/myelin-code-quality-fixtures.XXXXXX" 2>/dev/null) || [ ! -d "$FIXTURE_DIR" ]; then
    set_check_reason 'could not create the fixture directory with mktemp -d'
    return 1
  fi

  create_fixture_files || return 1

  assert_fixture_row 'valid shell' "$FIXTURE_DIR/valid-phases.sh" 0 0 0 || status=1
  assert_fixture_row 'trailing whitespace' "$FIXTURE_DIR/trailing-whitespace.sh" 0 1 0 || status=1
  assert_fixture_row 'missing final LF' "$FIXTURE_DIR/missing-final-lf.sh" 0 0 1 || status=1
  assert_fixture_row 'invalid syntax' "$FIXTURE_DIR/invalid-syntax.sh" 1 0 0 || status=1

  return "$status"
}
