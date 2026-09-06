---
type: meta
title: "Agent Playbook"
created: 2026-09-06
updated: 2026-09-06
verified: 2026-09-06
tags:
  - meta
  - workflow
---

# Agent Playbook

Which agents and skills for which tasks.

---

## Two Sources of Truth — Know Which One You're Asking

| Question | Authority |
|---|---|
| Why does this exist? What did we decide? What's the current state? | **the wiki** |
| What calls what? Where is X? What breaks if I change Y? | **the code graph** |

Never hand-write into the wiki a fact derivable from code. Write the entry point (`code_anchors`), let the graph supply the neighbours. Full rules in `CLAUDE.md`.

## Staleness Contract

Every wiki page carries `verified: YYYY-MM-DD`.

- Within 14 days → fact, act on it.
- Older than 14 days or missing → **hypothesis.** Verify against code/graph/running build first, then bump `verified:` in the same commit.
- Never report a stale claim as current state without naming its verified date.

## Codebase Memory (Fast Context)

Use `codebase-memory-mcp` before exploring code — faster and more token-efficient than reading files, and it cannot go stale the way prose does.

```
search_graph(project, query="natural language")
get_code_snippet(project, qualified_name="...")
trace_path(project, "fnName", mode="calls")
get_architecture(project, aspects=["modules","clusters","entry_points"])
detect_changes(project)
```

If not indexed yet → `index_repository` first. Full module map: [[Code Map]].

## Wiki Operations

| Operation | Command |
|---|---|
| Add new knowledge | Drop in `.raw/`, say "ingest [filename]" |
| Query anything | Ask — Claude reads `wiki/hot.md` → `wiki/index.md` → drills in |
| Health check | "lint the wiki" |
| Save a note | "save this" or `/save` |
| Update hot cache | Edit `wiki/hot.md` directly |

---

## Do Not

- Do not read whole files to find a function — use `search_graph` or `get_code_snippet` first
- Do not hand-write call graphs or "X calls Y" into wiki prose — it rots silently. Use `code_anchors` + the graph
- Do not act on a wiki claim older than 14 days without verifying it first
- **Do not mark a code task complete without updating `wiki/log.md`** — mandatory, not optional
