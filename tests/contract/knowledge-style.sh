#!/usr/bin/env bash
# knowledge-style — contract checks for the repo's knowledge-document style.

set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd) || exit 1
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd) || exit 1

PREFS_REL="preferences/code-quality.md"
PREFERENCE_FILES=(
  "templates/knowledge-skeleton/$PREFS_REL"
  ".knowledge/$PREFS_REL"
)
INDEX_FILES=(
  "templates/knowledge-skeleton/INDEX.md"
  ".knowledge/INDEX.md"
)
GLOBAL_STANDARDS="arsenal/skills/coding-standards/SKILL.md"
STYLE_EXAMPLES="arsenal/skills/coding-standards/references/style-examples.md"

failed=0

fail() {
  printf 'FAIL: knowledge style — %s\n' "$1"
  failed=1
}

require_file() {
  local relative_path=$1

  [ -f "$REPO_ROOT/$relative_path" ] || fail "missing required artifact: $relative_path"
}

# Missing files are reported once by require_file, so skip them here.
require_rule() {
  local relative_path=$1
  local name=$2
  local pattern=$3
  local path="$REPO_ROOT/$relative_path"

  [ -f "$path" ] || return 0
  grep -Eiq "$pattern" "$path" || fail "$relative_path — $name"
}

require_literal() {
  local relative_path=$1
  local name=$2
  local literal=$3
  local path="$REPO_ROOT/$relative_path"

  [ -f "$path" ] || return 0
  grep -Fq -- "$literal" "$path" || fail "$relative_path — $name"
}

require_index_line() {
  local relative_path=$1
  local line=$2
  local path="$REPO_ROOT/$relative_path"

  [ -f "$path" ] || return 0
  grep -Fqx -- "$line" "$path" || fail "$relative_path — missing required index line"
}

require_index_link() {
  local relative_path=$1
  local path="$REPO_ROOT/$relative_path"

  [ -f "$path" ] || return 0
  grep -Fq "($PREFS_REL)" "$path" || fail "$relative_path — missing $PREFS_REL link"
}

check_required_files() {
  local file

  for file in "${PREFERENCE_FILES[@]}" "${INDEX_FILES[@]}" "$GLOBAL_STANDARDS" "$STYLE_EXAMPLES"; do
    require_file "$file"
  done
}

check_preferences() {
  local preference

  for preference in "${PREFERENCE_FILES[@]}"; do
    require_rule "$preference" "intentional whitespace" \
      'intentional[[:space:]]+whitespace'
    require_rule "$preference" "rationale comments" \
      'rationale[[:space:]]+comments|comments?[[:space:]]+.*rationale'
    require_rule "$preference" "readable phases" \
      'readable[[:space:]]+phases|phases?[[:space:]]+.*readable'
    require_rule "$preference" "useful section spacing" \
      'preserv(e|ing|ed)[[:space:]]+.*useful[[:space:]]+section[[:space:]]+spacing|useful[[:space:]]+section[[:space:]]+spacing[[:space:]]+.*preserv'
  done
}

check_indexes() {
  local index

  for index in "${INDEX_FILES[@]}"; do
    require_index_line "$index" \
      '- [state/plans.md](state/plans.md) — plan lifecycle: active | shipped | punted | abandoned'
    require_index_line "$index" \
      '- [state/debt.md](state/debt.md) — technical debt register (add an entry the moment you punt)'
    require_index_line "$index" \
      '- [state/reviews.md](state/reviews.md) — commit review ledger'
    require_index_line "$index" \
      '- [state/DESIGN.md](state/DESIGN.md) — the single design constitution for this project'
    require_index_link "$index"
  done
}

# shellcheck disable=SC2016 # literal $ in expected text
check_standards() {
  require_rule "$GLOBAL_STANDARDS" "intentional whitespace" \
    'intentional[[:space:]]+whitespace'
  require_rule "$GLOBAL_STANDARDS" "lint-enforced code-spacing" \
    'code-spacing.*enforced[[:space:]]+by[[:space:]]+a[[:space:]]+lint[[:space:]]+rule'
  require_rule "$GLOBAL_STANDARDS" "comments explain rationale or constraints" \
    'comments?[[:space:]]+explain.*(rationale|constraints)'
  require_rule "$GLOBAL_STANDARDS" "prohibition on restating change history or narrating obvious code" \
    'restat.*(change|narrat)|narrat.*obvious|narrate.*next[[:space:]]+line'
  require_rule "$STYLE_EXAMPLES" "blank-line default rhythm" \
    'one[[:space:]]+blank[[:space:]]+line[[:space:]]+is[[:space:]]+a[[:space:]]+default[[:space:]]+rhythm,[[:space:]]+not[[:space:]]+a[[:space:]]+hard[[:space:]]+maximum'
  require_literal "$STYLE_EXAMPLES" "optional jq example" \
    '# jq is optional;'
  require_literal "$STYLE_EXAMPLES" "stdin fallback example" \
    'INPUT=$(cat 2>/dev/null || true)'
  require_literal "$STYLE_EXAMPLES" "ship-command guard example" \
    'is_ship_command "$CMD" || exit 0'
}

main() {
  check_required_files
  check_preferences
  check_indexes
  check_standards

  [ "$failed" -eq 0 ] && echo 'knowledge-style: pass'
  [ "$failed" -eq 0 ]
}

main "$@"
