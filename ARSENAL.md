# Arsenal

Everything needed to rebuild the skill setup on a new machine rides in this
repo's git. The plugin itself loads zero skills. `arsenal/` is repo cargo, not
a plugin surface.

## New machine

```bash
git clone https://github.com/zainzafar90/myelin ~/myelin
for d in ~/.claude/skills ~/.codex/skills; do ln -s ~/myelin/arsenal/skills/* "$d"/; done

# Third-party skills: copy the lockfile snapshot first, then install
cp ~/myelin/arsenal/skill-lock.json ~/.agents/.skill-lock.json
npx skills install

# loopkit (optional): link everything except simplify and systematic-debugging
git clone git@github.com:Archive228/loopkit.git ~/practice/loopkit
ln -s ~/practice/loopkit/skills/* ~/.claude/skills/
```

## What lives where

| Piece | In myelin git | Live location |
|---|---|---|
| Practice skills: `coding-standards` (base), `api-standards`, `frontend-standards`, `code-spacing` | `arsenal/skills/` (one source for every profile) | Symlinked into the skill folders of Claude (every profile), Codex, OpenCode, Command Code, Pi and Hermes |
| Language and verify skills: `typescript-standards`, `browser-verify`, future `<lang>-standards` | `arsenal/skills/` | Symlinked into the same folders |
| Adopted orphan skills, such as `edge-lit-glass` (no known upstream, so adopting is not forking) | `arsenal/skills/` | Symlinked into `~/.claude/skills/` |
| Third-party skills (118: source repo, path and hash each) | `arsenal/skill-lock.json` (snapshot; refresh with `cp ~/.agents/.skill-lock.json arsenal/`) | `~/.agents/` (has its own local git) |
| loopkit (31 skills) | Not copied; upstream reference only | `~/practice/loopkit` clone, symlinked |
| Manifest of `~/.claude/skills` | Not in this repo | `~/.claude/skills/SOURCES.md` (local git) |

Renamed 2026-10-30: `coding-core`, `api-engineering` and `frontend-engineering`
are now `coding-standards`, `api-standards` and `frontend-standards`.
`frontend-verify-standards` was folded into `browser-verify`.

## Rules

- The plugin loads zero skills. The canon routes to these skills by name, like
  any installed skill.
- Never copy third-party skills into this repo. Upstreams stay upstream. Only
  the lockfile snapshot rides here.
