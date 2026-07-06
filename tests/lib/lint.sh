#!/usr/bin/env bash
# lint.sh — require ShellCheck >= 0.10 and lint every shell script.

SHELLCHECK_VERSION=

shellcheck_version_supported() {
  local version=$1

  printf '%s\n' "$version" | awk -F. '
    NF < 2 { exit 2 }
    {
      for (i = 1; i <= NF; i++) {
        if ($i !~ /^[0-9]+$/) {
          exit 2
        }
      }
      if (($1 + 0) > 0 || ($2 + 0) >= 10) {
        exit 0
      }
      exit 1
    }
  '
}

read_shellcheck_version() {
  local version_output
  local command_status

  SHELLCHECK_VERSION=

  if ! command -v shellcheck >/dev/null 2>&1; then
    set_check_reason 'prerequisite: ShellCheck is not installed'
    return 1
  fi

  version_output=$(shellcheck --version 2>/dev/null)
  command_status=$?

  if [ "$command_status" -ne 0 ]; then
    set_check_reason 'prerequisite: shellcheck --version failed'
    return 1
  fi

  SHELLCHECK_VERSION=$(printf '%s\n' "$version_output" | awk -F: '
    $1 ~ /^[[:space:]]*version[[:space:]]*$/ {
      value=$2
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }
  ')

  if [ -z "$SHELLCHECK_VERSION" ]; then
    set_check_reason 'prerequisite: ShellCheck version is missing or unparseable'
    return 1
  fi

  return 0
}

require_supported_shellcheck() {
  local version_status

  read_shellcheck_version || return 1

  shellcheck_version_supported "$SHELLCHECK_VERSION"
  version_status=$?

  if [ "$version_status" -eq 2 ]; then
    set_check_reason "prerequisite: ShellCheck version $SHELLCHECK_VERSION is unparseable"
    return 1
  fi

  if [ "$version_status" -ne 0 ]; then
    set_check_reason "prerequisite: ShellCheck $SHELLCHECK_VERSION is too old; need >= 0.10"
    return 1
  fi

  return 0
}

is_shellcheck_target() {
  local path=$1

  case "$path" in
    hooks/*.sh|bin/*.sh|tests/*.sh) return 0 ;;
    bin/*.*) return 1 ;;
    bin/*) [ -x "$ROOT/$path" ] ;;
    *) return 1 ;;
  esac
}

check_shellcheck() {
  local path

  require_scope_file || return 1
  require_supported_shellcheck || return 1

  while IFS= read -r path; do
    is_shellcheck_target "$path" || continue

    if ! shellcheck --shell=bash --severity=warning "$ROOT/$path" >/dev/null 2>&1; then
      set_check_reason "$path — ShellCheck reported a warning or error"
      return 1
    fi
  done < "$FIXTURE_DIR/all-paths"

  return 0
}
