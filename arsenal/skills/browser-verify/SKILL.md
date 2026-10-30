---
name: browser-verify
description: >-
  The definition of done for browser-facing changes. Drives the change in a
  real browser: interact with the changed control, try to break it, check
  console, failed requests, color schemes and viewports, and report pass or
  fail with evidence. Use before claiming a UI change is done, after editing
  components, pages, routes, forms, or styles, or when asked to test, verify,
  QA, or check something in the browser. Works with whichever browser tool the
  host provides.
metadata:
  version: "1.1.0"
---

# Browser verify

No browser evidence, no completion claim. A build that passes is not a page that works.

## 1. Pick the browser tool

Go down the table. A tool counts if it is loaded or can be loaded (search for deferred tools first).
If a tool cannot open the URL, try the next row. Do not install anything to get one.

| Tool | Use for |
|---|---|
| Built-in browser pane (`mcp__Claude_Browser__*`) | default in the Claude desktop app |
| Playwright MCP (`browser_*`) | scripted interaction, console, network |
| Chrome DevTools MCP | console, network, Lighthouse, performance traces |
| Repo's own `@playwright/test` | when no browser tool is connected |

Launch the real app first; the `run` skill knows per-project launch quirks.
A local `.html` file: serve it (`python3 -m http.server` in its folder) and open the `http://localhost` URL;
many tools block `file://`. None available: say so and stop. Never report "verified" from reading code.

## 2. Write the attack before opening the page

Name the URL, the changed control, and every way it could fail.

- Bad: "Check the login form renders on http://localhost:5173."
- Good: "On http://localhost:5173/login submit empty, with a bad email, with a wrong password, then valid.
  Expect field errors, no double submit, redirect on success, zero console errors."

Cover what applies: empty, invalid, very long text (300+ characters), two fast clicks, keyboard only
(Tab to the control, Enter or Space to activate, Escape), slow or failed request, and the loading, empty,
and error states. Also cover the house checks that apply:

- Both color schemes (dark and light) and both viewports (about 375px and desktop).
- Embedded surface (iframe widget): verify inside an iframe host, not just standalone.
- User-facing page: Lighthouse audit, no Core Web Vitals regression versus before the change.

Every attack on the list runs, even after an earlier one fails. Nothing is skipped for time.
An attack that cannot apply (no request to throttle) is N/A with the reason, not NOT RUN.

## 3. Run the pass

1. Reuse an open tab on the app if there is one; reload instead of starting a new browser.
2. Read the page structure (accessibility tree or snapshot) once to get element refs.
3. Interact with the changed control directly. Batch fills and clicks into one call where the tool allows.
   Take a new snapshot only after navigation, submit, or a dialog opening or closing.
4. Async results: wait for the change to appear, then read it back. A read right after a click can be stale.
5. Count what matters, such as requests sent or rows added. Use the network log, or a small script in the
   page when the tool has no network view. Two fast clicks must produce one effect; use the tool's real
   double click or two real clicks, never a scripted `.click()`.
6. After each step, check console errors and failed network requests.
7. Screenshot each meaningful state: before, after, and every failure. Save to the project if the tool allows;
   otherwise cite the inline screenshot.
8. Long or many-step runs go to a subagent so the main thread keeps editing.

## 4. Report

```text
URL: http://localhost:5173/login
| Check                        | Result | Evidence           |
|------------------------------|--------|--------------------|
| empty submit shows errors    | PASS   | login-empty.png    |
| double click sends 1 request | FAIL   | 2 POST /api/login  |
Console: 0 new errors. Failed requests: none.
```

Any FAIL: fix the code, rerun the whole pass, report again. NOT RUN counts as FAIL.
Only an all-PASS report supports a done-claim.

## Shortcuts that are not allowed

- "It compiled, so it works." Open the page.
- "The screenshot looks right." Click the thing.
- "One console error is from before." Prove it with the same check on the unchanged code. No unchanged
  version (a new page): every error counts.
- "I'll snapshot after every fill." Fills do not change structure; batch them.
