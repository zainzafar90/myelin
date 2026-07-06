function trunc(s) {
  gsub(/\t/, " ", s)

  return length(s) > 100 ? substr(s, 1, 97) "..." : s
}

function trim(s) {
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)

  return s
}

function isdate(s) {
  return s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/
}

function slug(s,  t) {
  t = tolower(s)
  gsub(/\[[^]]*\]/, " ", t)
  gsub(/[^a-z0-9]+/, "-", t)
  sub(/^-+/, "", t)
  sub(/-+$/, "", t)

  if (length(t) > 50) {
    t = substr(t, 1, 50)
    sub(/-+[^-]*$/, "", t)
  }

  return t == "" ? "item" : t
}

function sevnorm(v) {
  v = tolower(v)
  sub(/^[^a-z]+/, "", v)

  if (!match(v, /^[a-z]+/)) return "unknown"

  v = substr(v, 1, RLENGTH)

  if (v == "high") return "high"
  if (v == "med" || v == "medium") return "medium"
  if (v == "low") return "low"

  return "unknown"
}

function statnorm(v) {
  v = tolower(v)

  if (match(v, /^[a-z]+/)) v = substr(v, 1, RLENGTH)

  return (v == "closed" || v == "duplicate") ? v : "open"
}

function tagsev(t,  s) {
  if (!match(t, /\[(high|med|medium|low)\]/)) return "unknown"

  s = substr(t, RSTART + 1, RLENGTH - 2)

  return sevnorm(s)
}

function uniqueid(id) {
  seen[id]++

  return seen[id] > 1 ? id "-" seen[id] : id
}

function itemtitle(id) {
  if (c_fmt != "idrec") return c_title
  if (c_why != "") return c_why
  if (c_where != "") return c_where

  return id
}

function emit(id, title) {
  print "I" TAB id TAB c_status TAB c_sev TAB (c_date == "" ? "-" : c_date) TAB c_fmt TAB c_line TAB trunc(title)
}

function flush(bulleted,  id) {
  if (!cur) return

  if (bulleted && c_fmt == "heading" && c_keys == 0) {
    cur = 0

    return
  }

  id = uniqueid(c_id != "" ? c_id : slug(c_title))
  emit(id, itemtitle(id))
  cur = 0
}

function begin(fmt, id, status, sev, date, title) {
  flush(fmt != "heading" && fmt != "idrec")
  cur = 1
  blank = 0
  c_keys = 0
  c_fmt = fmt
  c_id = id
  c_status = status
  c_sev = sev
  c_date = date
  c_line = NR
  c_title = title
  c_why = ""
  c_where = ""
}

function single(fmt, id, status, sev, date, title) {
  begin(fmt, id, status, sev, date, title)
  flush()
}

function unparsed(t) {
  flush(1)
  print "U" TAB NR TAB trunc(t)
}
