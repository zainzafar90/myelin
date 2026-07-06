function keyline(k, v) {
  if (k == "id") {
    if (cur && c_fmt == "heading" && !blank && c_id == "") {
      c_id = v

      return
    }

    begin("idrec", v, "open", "unknown", "", "")

    return
  }

  if (!cur) {
    unparsed($0)

    return
  }

  c_keys++

  if (k == "status") c_status = statnorm(v)
  else if (k == "severity") c_sev = sevnorm(v)
  else if (k == "date") c_date = isdate(v) ? substr(v, 1, 10) : v
  else if (k == "where") c_where = v
  else if (k == "why") c_why = v
}

function dotitem(rest, d,  p, head, sev, t) {
  p = index(rest, " · ")
  head = p > 0 ? substr(rest, 1, p - 1) : ""
  t = p > 0 ? substr(rest, p + 4) : rest

  if (head !~ /^[a-z0-9][a-z0-9_-]*$/) {
    head = slug(rest)
    t = rest
  }

  sev = "unknown"

  if (match(t, /\((high|med|medium|low)[^)]*\)[ \t]*$/)) {
    sev = substr(t, RSTART + 1)
    sev = sevnorm(sev)
  }

  single("dot", head, "open", sev, d, t)
}

function datedbullet(line,  d, rest) {
  d = substr(line, 3, 10)
  rest = substr(line, 14)

  if (substr(rest, 1, 1) == " ") rest = substr(rest, 2)

  if (substr(rest, 1, 3) == "· ") {
    dotitem(substr(rest, 4), d)

    return
  }

  single("dated", "", "open", tagsev(rest), d, rest)
}

function checkbox(line,  st, rest, d) {
  st = substr(line, 4, 1) == " " ? "open" : "closed"
  rest = substr(line, 7)
  d = ""

  if (isdate(rest)) {
    d = substr(rest, 1, 10)
    rest = substr(rest, 12)
  }

  single("checkbox", "", st, tagsev(rest), d, rest)
}

function bracket(line,  rest, d, sev, tok, tk) {
  rest = substr(line, 3)
  d = ""
  sev = "unknown"

  while (match(rest, /^\[[^]]*\]/)) {
    tok = substr(rest, 2, RLENGTH - 2)
    rest = substr(rest, RLENGTH + 1)
    tk = sevnorm(tok)

    if (isdate(tok)) d = substr(tok, 1, 10)
    else if (tk != "unknown" && tolower(tok) ~ /^(high|med|medium|low)$/) sev = tk

    sub(/^[ \t]+/, "", rest)
  }

  if (d == "" && isdate(rest)) {
    d = substr(rest, 1, 10)
    rest = substr(rest, 12)
  }

  single("bracket", "", "open", sev, d, trim(rest))
}

function retired(line,  d, rest) {
  d = substr(line, 11, 10)
  rest = substr(line, 22)
  sub(/^:[ ]*/, "", rest)
  single("retired", "", "closed", "unknown", d, rest)
}

function keybullet(line,  k, v) {
  k = line
  sub(/^- /, "", k)
  v = k
  sub(/:.*/, "", k)
  sub(/^[a-z_]+:[ ]?/, "", v)
  keyline(k, trim(v))
}

function bullet(line) {
  if (line ~ /^- [a-z_]+:( |$)/) return keybullet(line)
  if (line ~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]( |$)/) return datedbullet(line)
  if (line ~ /^- \[[ xX]\] /) return checkbox(line)
  if (line ~ /^- \[/) return bracket(line)
  if (line ~ /^- RETIRED [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:/) return retired(line)

  unparsed(substr(line, 3))
}

in_c {
  if (index($0, "-->")) in_c = 0

  next
}

index($0, "<!--") {
  if (!index(substr($0, index($0, "<!--")), "-->")) in_c = 1

  next
}

/^(    |\t)/ { next }

/^[ \t]*$/ {
  blank = 1

  next
}

/^[ \t]/ { next }

/^## / {
  begin("heading", "", "open", "unknown", "", trim(substr($0, 4)))

  next
}

/^#/ {
  flush()

  next
}

/^- / {
  bullet($0)

  next
}

END { flush() }
