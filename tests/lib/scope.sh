#!/usr/bin/env bash
# scope.sh — enumerate in-scope repo files and run a per-file checker over them.

CHECK_REASON=
FIXTURE_DIR=
SCOPE_FILE=

set_check_reason() {
  # shellcheck disable=SC2034 # read by the contract runner
  CHECK_REASON=$1
  return 1
}

is_in_scope() {
  local path=$1

  case "$path" in
    .superpowers/*|*/.superpowers/*|arsenal/skill-lock.json) return 1 ;;
  esac

  case "$path" in
    *.sh|*.md) ;;
    *) return 1 ;;
  esac

  case "$path" in
    hooks/*|bin/*|tests/*|canon/*|commands/*|templates/*|AGENTS.md|CLAUDE.md|README.md|HANDOFF.md)
      return 0
      ;;
  esac

  return 1
}

collect_scope_paths() {
  local all_paths="$FIXTURE_DIR/all-paths"
  local path

  if ! git -C "$ROOT" ls-files --cached --others --exclude-standard > "$all_paths" 2>/dev/null; then
    set_check_reason 'could not enumerate files with git ls-files --cached --others --exclude-standard'
    return 1
  fi

  if ! : > "$SCOPE_FILE"; then
    set_check_reason "could not create the in-scope file list: $SCOPE_FILE"
    return 1
  fi

  while IFS= read -r path; do
    is_in_scope "$path" || continue
    if ! printf '%s\n' "$path" >> "$SCOPE_FILE"; then
      set_check_reason "could not write the in-scope file list: $path"
      return 1
    fi
  done < "$all_paths"

  return 0
}

require_scope_file() {
  if [ ! -r "$SCOPE_FILE" ]; then
    set_check_reason 'in-scope file list is unavailable'
    return 1
  fi
}

inspect_scope() {
  local checker=$1
  local path

  require_scope_file || return 1

  while IFS= read -r path; do
    "$checker" "$ROOT/$path" "$path" || return 1
  done < "$SCOPE_FILE"

  return 0
}

# Run a file checker on one explicit path, or on every in-scope file.
run_on_target() {
  local file_checker=$1
  shift

  if [ "$#" -gt 0 ]; then
    "$file_checker" "$1" "${2:-$1}"
    return $?
  fi

  inspect_scope "$file_checker"
}
