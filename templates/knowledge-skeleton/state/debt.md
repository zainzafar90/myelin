# Technical debt

Add an entry at the moment of punting — never "later". Entry format:

    ## <short title>
    - id: <kebab-slug, unique within this file>
    - status: open | closed | duplicate
    - severity: high | medium | low | unknown
    - where: <path or subsystem>
    - why: <consequence, and why it was deferred>
    - date: YYYY-MM-DD
    - checked: <optional note>
    - resolution: <date — reason — evidence>   (closed only)
    - duplicate_of: <id>                         (duplicate only)

<!-- Worked example (delete when you add your first real entry) —
     real entries start at column 0, like this:

    ## Carousel iframe recalculates height on every scroll
    - id: carousel-height-recalc
    - status: open
    - severity: medium
    - where: apps/iris/src/carousel
    - why: punted during launch crunch; needs ResizeObserver rework
    - date: 2026-07-06
-->

