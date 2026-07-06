# Design constitution

- voice: unset

One design voice per project — never blend. This file is the rulebook an
agent follows before touching UI. Replace the body below with a real
design-md (e.g. a getdesign.md catalog file like linear.app's), or generate
one from this project's existing UI with the `teach-impeccable` skill, or
edit the worked defaults in place. Keep the `- voice:` line above (a hook
reads it; set it to a short name when you commit to a voice).

## Principles

- Interfaces should feel calm: fewer elements, more space, no decoration
  that doesn't carry information.
- Motion explains state change; it never entertains.
- Every visual decision is a token first. No literal values in components.

## Color

- Semantic roles only — components reference roles, never raw values:
  `--bg`, `--bg-elevated`, `--fg`, `--fg-muted`, `--accent`, `--danger`,
  `--border`.
- One accent color per project. It marks primary actions and focus — if
  everything is accented, nothing is.
- Dark and light themes swap role values only; component CSS never changes.
- Contrast: body text ≥ 4.5:1 against its background, always.

## Typography

- One typeface family (plus optional mono for code). System stack is the
  default until the project earns a brand face.
- Scale (rem): 0.75 / 0.875 / 1 / 1.125 / 1.5 / 2 / 3. Nothing in between.
- Weights: 400 for body, 500 for UI labels, 600 for headings. Never 300 on
  light backgrounds, never 700+ for whole sentences.
- Line-height: 1.5 body, 1.2 headings. Max line length ~70ch.

## Spacing and layout

- Base unit 4px; allowed steps: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64.
- Spacing communicates grouping: related things sit closer than unrelated
  things — if you need a divider, try more space first.
- One max-width container per page type; content never touches viewport
  edges (min 16px gutter mobile, 24px desktop).

## Motion

- Durations: 120ms (micro: hover, toggle), 200ms (standard: reveal,
  slide), 300ms (large: modal, page). Nothing longer without a reason.
- Easing: ease-out for entering, ease-in for exiting, never linear for
  visible movement.
- Respect `prefers-reduced-motion`: all movement collapses to opacity.

## Components

- Radius: one value per project (default 8px; 4px for dense/data UI).
  Full-round only for avatars and pills.
- Elevation: two levels max — flat (border) and raised (shadow). If a
  third feels needed, the layout is wrong.
- Every interactive element has visible hover, focus-visible, active, and
  disabled states. Focus rings are never removed, only styled.
- Buttons: one primary per view. Everything else is secondary or ghost.

## Hard rules

- Never inline styles for anything a token covers.
- Never introduce a new color, font size, or spacing value outside the
  scales above — extend the scale deliberately or don't.
- Never animate layout properties (width/height/top/left); transform and
  opacity only.
- Never ship a UI state without loading, empty, and error variants.
