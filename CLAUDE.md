# İlk Oyun — LLM Wiki

Mode: Game Development Project
Purpose: Persistent knowledge base for the game — design, decisions, systems, deliverables, tooling.
Owner: Ahmet Bilal Özgün
Created: 2026-09-06

## Structure

```
ilk_oyun/
├── .raw/               # Source documents (immutable)
│   ├── articles/
│   ├── transcripts/
│   └── data/
├── wiki/
│   ├── index.md        # Master catalog
│   ├── log.md          # Append-only operation log
│   ├── hot.md          # Hot cache (~500 words)
│   ├── overview.md     # Executive summary
│   ├── design/         # Game design, mechanics, systems, UX
│   ├── decisions/      # Key decisions with rationale
│   ├── deliverables/   # Milestones, builds, releases, status
│   ├── concepts/       # Frameworks, patterns, ideas
│   ├── entities/       # People, tools, engines, third-party
│   ├── code/           # Module map, cluster → owning wiki page
│   ├── sources/        # One page per raw source
│   ├── questions/      # Filed answers to queries
│   ├── comms/          # Meeting notes, playtest notes
│   └── meta/           # Dashboard, agent playbook, lint reports
└── _templates/         # Note templates
```

## Conventions

- All notes use YAML frontmatter: type, status, created, updated, tags (minimum)
- Pages making claims about live game/build state also carry `verified: YYYY-MM-DD` — see Staleness Contract
- Pages describing shipped behavior also carry `code_anchors:` — see Code Anchors
- Wikilinks use [[Note Name]] format — filenames are unique, no paths needed
- .raw/ contains source documents — never modify them
- wiki/index.md is the master catalog — update on every ingest
- wiki/log.md is append-only — new entries go at the TOP

## Source of Truth

**The wiki is authoritative for intent. The code graph is authoritative for structure.**

| Question | Authority | Never trust |
|---|---|---|
| Why does this exist? What did we decide? What is the current state? | `wiki/` | code comments, your memory |
| What calls what? Where is X defined? What breaks if I change Y? | `codebase-memory-mcp` graph | wiki prose, your memory |

Corollary: **never hand-write a fact into the wiki that is derivable from code.** Call graphs, import lists, and function signatures rot silently and no test catches it. Write the entry point (`code_anchors`), let the graph supply the neighbours.

## Staleness Contract

Every wiki claim about live game/build state carries `verified: YYYY-MM-DD` in frontmatter, and inline `(verified YYYY-MM-DD)` where a single page mixes fresh and old claims.

**Agent rule — this is not optional:**

- `verified` within **14 days** → treat as fact, act on it.
- `verified` older than **14 days**, or absent → treat as **hypothesis, not fact.** Verify against code, the graph, or the running build before acting. Then update `verified` in the same commit.
- Never report a stale claim to the user as current state without saying when it was last verified.

**Why this rule exists:** a stale page believed by every agent that reads it is worse than no page. `verified:` is the fix — it forces a re-check instead of silent trust.

## Code Anchors

Wiki pages that describe shipped behavior carry `code_anchors:` — hand-curated entry points, not a mirror of the call graph.

```yaml
code_anchors:
  - repo: game          # adjust to your repos
    symbol: SpawnEnemy
    file: src/enemy.ext
```

**How agents use them:**

1. Read the wiki page → get intent + `code_anchors`.
2. Feed each `symbol` to `trace_path(symbol, mode="calls")` or `get_code_snippet(qualified_name)`.
3. The graph returns the real, current neighbours. That is the call structure — not anything the wiki says.

`symbol` is the durable key; `file` is a convenience hint and may drift. If a symbol no longer resolves in the graph, it was renamed or deleted — fix the anchor, do not guess.

## Operations

- Ingest: drop source in .raw/, say "ingest [filename]"
- Query: ask any question — Claude reads index first, then drills in
- Lint: say "lint the wiki" to run a health check
- Save: say "save this" or /save to file a note

## Retrieval Protocol

**Design / decision / "why" questions:**
1. `wiki/hot.md` (recent context, ~500 words)
2. `wiki/index.md` (full catalog) if hot.md is not enough
3. `wiki/<domain>/_index.md` for domain specifics
4. Individual wiki pages last

**Code questions — do NOT start in the wiki, and do NOT start with grep:**
1. `search_graph(query="...")` — find the symbol
2. `trace_path(symbol, mode="calls"|"data_flow")` — find what touches it
3. `get_code_snippet(qualified_name)` — read exact source
4. `wiki/code/_index.md` — module map, cluster → owning wiki page
5. Read/Grep only for configs, assets, and non-code files

**Mixed "why is this built this way" questions:** wiki page first for intent → its `code_anchors` → graph from there.

Apply the Staleness Contract to everything read in step 1–4 of the design path.

## MANDATORY: Post-Code Wiki Update

**Every coding agent MUST update the wiki after making any code changes.** No exceptions.

After completing any code task:

1. **Append to `wiki/log.md`** (new entry at TOP):
   ```
   ## [YYYY-MM-DD] <type> | <short title>
   - Files changed: list them
   - What changed and why (1–3 bullets)
   - Any decisions made (link [[Decision Name]] if significant)
   ```
   Types: `fix`, `feature`, `refactor`, `disable`, `config`, `document`

2. **Update `wiki/hot.md`** if the change affects: active feature set, core loop, build state, or anything in the "Key Recent Facts" block. Bump its `verified:` date.

3. **Update the relevant wiki domain page** if a system/mechanic was added, removed, or significantly changed. Bump that page's `verified:` date, and add or correct its `code_anchors:` if you added, renamed, or deleted an entry-point symbol.

4. **Re-index if structure changed** — new files, renames, or deletions make the graph lie. Run `detect_changes(project)`, then `index_repository` if it reports drift. A stale graph is the same failure mode as a stale wiki.

**Do not** mark a task complete without doing steps 1–4 above.
