---
type: meta
title: "Code Map"
updated: 2026-09-16
verified: 2026-09-16
tags:
  - code
---

# Code Map

Module clusters, what's indexed in the code graph, and how to query it.

## Repos / Projects

| Project | Indexed? | Graph name |
|---|---|---|
| İlk Oyun | 2026-09-16 | `Users-ahmetbilalozgun-Documents-Projects-Games-ilk_oyun` |

## Query the Graph

Use `codebase-memory-mcp` before reading files:

```
search_graph(project, query="natural language")   # find a symbol
get_code_snippet(project, qualified_name="...")    # exact source
trace_path(project, "fnName", mode="calls")        # what touches it
get_architecture(project, aspects=["modules","clusters","entry_points"])
detect_changes(project)                            # has graph drifted?
```

If a project is not indexed yet, run `index_repository` FIRST.

## Not Indexed — Read/Grep only

_(list configs, assets, generated files here)_

## Intent owners

Görsel dil ve ritim sunumu: [[Tatlış Büyücüler ve Açık Hava Görsel Dili]]. Savaş/run niyeti: [[Turn-Based Savaş ve QTE]]. Güncel yapı ve komşulukları grafikten sorgula.
