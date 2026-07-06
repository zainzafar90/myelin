---
name: frontend-verify-standards
description: Use before declaring ANY browser-facing change done — the definition of done for UI work. An edit that compiles is not done; run it, attack it, audit it, rerun until clean.
---

# Frontend Verification Standards (definition of done)

Composition skill: chains tools that already exist; this file only sets the
bar. Never report a UI change complete on a successful edit or build alone.

## The loop
*Distills: the loop pattern (edit → verify end-to-end → fix → rerun) + an embed-heavy stack*

1. **Launch the real app** — use `/run` (it knows per-project launch quirks).
2. **`/expect`** — adversarial browser pass against the change: interact with
   the control directly (click it, type in it, toggle it), try to break it,
   screenshots captured, structured pass/fail. Prefer this over raw
   Playwright/chrome tools.
3. **Console clean** — zero NEW errors or warnings introduced by the change.
4. **Performance** — if the change touches a user-facing page: chrome-devtools
   Lighthouse audit; no Core Web Vitals regression versus before the change.

## House checks (the ones that bite this stack)

- **Embed context:** if the surface ships as an embed/iframe (e-commerce
  widgets), verify it INSIDE an iframe host, not just standalone — cookies,
  postMessage, and viewport all behave differently.
- **Both color schemes:** dark mode and light mode.
- **Both viewports:** mobile (~375px) and desktop.
- **Data states:** change touches fetching? Verify loading, empty, and error
  states render (route: loading-empty-error-states).

## Exit rule

Any step fails → fix → rerun from step 1. Partial verification is not a
hand-back state; "should work" is not evidence. The done-claim must cite what
was interacted with, console status, and screenshots/CWV numbers where taken.
