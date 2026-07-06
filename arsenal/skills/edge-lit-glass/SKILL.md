---
name: edge-lit-glass
description: Use when styling a floating web UI surface (pill, card, popover, toolbar, HUD, overlay, sidebar, modal) to read as frosted / liquid glass over arbitrary page content — or when a backdrop-filter glass element looks flat, washed-out, grey, or invisible against a same-tone background. Plain CSS (backdrop-filter + layered box-shadow), no SVG displacement filter. Keywords glassmorphism, frosted glass, liquid glass, specular edge, glass card, glass pill.
---

# Edge-lit glass

## Overview

Convincing web "glass" is not blur alone — it's **blur + a light-drawing shadow stack**. A translucent fill and `backdrop-filter` give the frost; four `box-shadow` layers paint the *edges* (a specular top rim, a hairline, a faint cool bloom at the bottom, and an outer drop) so the surface reads as glass on **any** backdrop, even one the same tone as the glass. No SVG `feDisplacementMap` engine.

## When to use

- Floating surfaces over content you don't control: browser-extension pills/HUDs, popovers, toolbars, command bars, notification cards, sidebars, modals.
- A `backdrop-filter: blur()` element that looks flat, grey, washed-out, or vanishes on a matching background.

**Not for:** full-page backgrounds (nothing behind to refract); when you need *true* refraction that bends text/edges behind it (that needs `feDisplacementMap` + WebGL — heavier, Chromium-leaning; see bottom).

## Core recipe

The rim is drawn with an **inset shadow**, not a real border. Keep `border: 1px solid transparent` so the radius clips cleanly, and let the shadows do the edge.

```css
.glass {
  border: 1px solid transparent;
  border-radius: 16px;
  color: #fff;
  background: linear-gradient(180deg, rgba(20, 20, 22, 0.55), rgba(20, 20, 22, 0.34));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.30),        /* 1 specular top rim  */
    inset 0 0 0 1px rgba(255, 255, 255, 0.08),      /* 2 hairline outline  */
    inset 0 -8px 14px -8px rgba(184, 204, 255, 0.18),/* 3 cool bloom, bottom */
    0 10px 26px rgba(0, 0, 0, 0.34);                /* 4 outer drop        */
  -webkit-backdrop-filter: blur(16px) saturate(165%);
  backdrop-filter: blur(16px) saturate(165%);
}
```

| Layer | What it does | Skip it and… |
|---|---|---|
| 1 specular top rim | catches light on the top edge | looks like a flat chip |
| 2 hairline | 1px edge that reads on any bg | edge disappears on same-tone bg |
| 3 cool bloom | whisper of refracted light at the base | loses the "lens" feel (cheap steal from real refraction) |
| 4 outer drop | lifts it off the page | floats without depth |
| `saturate()` | revives color pulled through the blur | grey, dead frost |

**Light variant** (for glass over dark pages — flip the rim/hairline polarity):

```css
.glass.light {
  color: #16161a;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.62), rgba(255, 255, 255, 0.34));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.75),
    inset 0 0 0 1px rgba(0, 0, 0, 0.06),
    inset 0 -8px 14px -8px rgba(80, 110, 200, 0.12),
    0 10px 24px rgba(20, 20, 40, 0.16);
}
```

## State tint without restating the stack

Compose `box-shadow` from CSS vars so a state can add an outer glow (or tint) by overriding **one** variable. `box-shadow` is *not* clipped by `overflow: hidden`, so this works even on a pill that clips its own content.

```css
.glass {
  --inset: inset 0 1px 0 rgba(255,255,255,0.30), inset 0 0 0 1px rgba(255,255,255,0.08),
           inset 0 -8px 14px -8px rgba(184,204,255,0.18);
  --drop: 0 10px 26px rgba(0,0,0,0.34);
  --glow: 0 0 0 0 transparent;
  box-shadow: var(--inset), var(--drop), var(--glow);
}
.glass[data-state="warn"]  { --glow: 0 6px 22px rgba(255,176,60,0.22); }
.glass[data-state="alert"] { --glow: 0 6px 24px rgba(255,90,90,0.28); }
```

## Scale the fill and blur to the surface

Small chips stay mostly opaque; large panels **fade to transparent** top→bottom so the backdrop bleeds through the lower half — that's what reads as glass at card scale.

| Surface | fill (top → bottom α) | blur | saturate | drop |
|---|---|---|---|---|
| pill / chip | 0.55 → 0.34 | 16px | 165% | `0 10px 26px /.34` |
| card / panel | 0.78 → 0.16 | 22px | 155% | `0 18px 44px /.42` |

## Common mistakes

- **Real opaque `border` for the edge** → reads as a solid chip. Use `border: transparent` + the `inset 0 0 0 1px` hairline (visible on any bg).
- **Omitting `saturate()`** → washed-out grey. 150–170% is what makes it feel liquid.
- **Light glass on a light page, weak hairline** → invisible. Raise hairline + drop opacity.
- **Expecting `overflow:hidden` to clip the glow** → it doesn't; `box-shadow` paints outside the box (that's the win in the var-glow trick).
- **No backdrop, or missing `-webkit-` prefix** → `backdrop-filter` does nothing with no painted content behind it, and needs the prefix for Safari.
- **Glass nested in glass / many blurred layers** → GPU cost climbs. One `backdrop-filter` per surface.

## Why not SVG feDisplacementMap

Real glass *refraction* (Apple "Liquid Glass", the Aave web-glass write-up) generates a displacement-map PNG and physically bends the pixels behind the element (with a WebGL fallback). Beautiful, but heavy and Chromium-leaning — SVG `backdrop-filter` is Chromium-only and Safari caches filter output by id. For a widget floating over arbitrary third-party pages, this box-shadow recipe gets ~90% of the look, in every browser, for free.

## Demo

`demo.html` — open in a browser: dark + light glass cards, a pill, the fade-to-transparent panel, and the state-glow, all over a busy backdrop so the blur has something to refract.
