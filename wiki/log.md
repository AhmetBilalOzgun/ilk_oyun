---
type: meta
title: "Operation Log"
updated: 2026-09-06
---

# Operation Log

Append-only. **New entries go at the TOP.** Format:

```
## [YYYY-MM-DD] <type> | <short title>
- Files changed: list them
- What changed and why (1–3 bullets)
- Any decisions made (link [[Decision Name]] if significant)
```

Types: `fix`, `feature`, `refactor`, `disable`, `config`, `document`

---

## [2026-09-06] document | Wiki memory system scaffolded
- Files changed: `CLAUDE.md`, `wiki/**`, `_templates/**`, `.raw/**`
- Ported the LLM-wiki agent memory system (blank start): governing `CLAUDE.md`, index/hot/log/overview, domain `_index` pages, note templates.
- No game content yet — structure only.
