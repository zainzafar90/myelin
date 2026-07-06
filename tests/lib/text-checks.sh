#!/usr/bin/env bash
# text-checks.sh — syntax, trailing-whitespace and final-newline checks.

check_bash_syntax_file() {
  local path=$1
  local display=${2:-$1}

  case "$display" in
    *.sh) ;;
    *) return 0 ;;
  esac

  if ! bash -n "$path" >/dev/null 2>&1; then
    set_check_reason "$display — bash -n reported a syntax error"
    return 1
  fi

  return 0
}

check_whitespace_file() {
  local path=$1
  local display=${2:-$1}
  local line
  local awk_status

  line=$(awk '/[[:blank:]]$/ { print NR; exit }' "$path" 2>/dev/null)
  awk_status=$?

  if [ "$awk_status" -ne 0 ]; then
    set_check_reason "$display — could not read the file for trailing whitespace"
    return 1
  fi

  if [ -n "$line" ]; then
    set_check_reason "$display — trailing whitespace at line $line"
    return 1
  fi

  return 0
}

check_final_newline_file() {
  local path=$1
  local display=${2:-$1}
  local last_byte

  [ -s "$path" ] || return 0

  last_byte=$(LC_ALL=C tail -c 1 "$path" 2>/dev/null | od -An -t x1 2>/dev/null | tr -d '[:space:]')

  if [ "$last_byte" != '0a' ]; then
    set_check_reason "$display — nonempty file lacks a final LF"
    return 1
  fi

  return 0
}

check_bash_syntax() { run_on_target check_bash_syntax_file "$@"; }
check_whitespace() { run_on_target check_whitespace_file "$@"; }
check_final_newline() { run_on_target check_final_newline_file "$@"; }
