---
type: decision
title: "Engine — Godot"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - decision
  - tech
status: active
priority: 2
date: 2026-09-07
owner: Ahmet Bilal Özgün
context: Prototip ve oyun için motor seçimi
related:
  - "[[Prototip M0]]"
  - "[[Rün Büyücüsü — Konsept]]"
code_anchors: []
---

# Engine — Godot

## Decision

Oyun motoru **Godot**.

## Rationale

- Küçük indirme boyutu + düşük cihaz performansı hedefiyle uyumlu.
- 2D için güçlü, mobil dışa aktarım destekli, açık kaynak / lisans yükü yok.
- Hızlı prototipleme.

## Consequences

- Dil: GDScript (varsayılan) — büyük olasılıkla. C# opsiyon.
- Godot sürümü: **4.7.2 stable**. Binary: `~/Downloads/Godot.app/Contents/MacOS/Godot` (Downloads'ta — taşınırsa MCP GODOT_PATH güncelle).
- MCP'ler (`.mcp.json`): `godot-docs` (doküman sorgu) + `godot` (Coding-Solo/godot-mcp, editör kontrol: sahne çalıştır/hata oku).
- Çizim tanıma ($1 recognizer) Godot içinde uygulanacak → [[Çizim Tanıma — $1 Recognizer]].

## Status History
- 2026-09-07: created (approved)
