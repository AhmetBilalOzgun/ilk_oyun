---
type: meta
title: "Overview"
created: 2026-09-06
updated: 2026-09-07
verified: 2026-09-07
tags:
  - meta
  - overview
status: draft
---

# İlk Oyun — Executive Summary

## What It Is

**Rün Büyücüsü** — dikey, 2D, dalga tabanlı mobil savunma oyunu. Oyuncu ekran altındaki sabit kareye parmağıyla **rün şekilleri çizer**; soldaki büyücü o büyüyü sağdan gelen düşmanlara fırlatır. Rünler zincirlenerek kombolara döner. Fark: girdi = seçim değil **üretim** ("ben yaptım" hissi), ve reklam = oynanış (dilsiz, 6 saniyede anlaşılır).

## Current State (2026-09-07)

| Component | Status |
|---|---|
| Concept | **Approved** |
| Prototype | Planned — [[Prototip M0]] |
| Build | — |

## Core Loop

Düşman dalgası gelir → oyuncu düşmanın silüetine göre rün çizer → büyücü fırlatır → rünleri zincirleyip kombo yapar → dalga biter → rün seçim ekranı (duruş noktası) → sonraki dalga. Dalga başına 40–60 sn.

## Tech Stack

- **Engine:** **Godot** → [[Engine — Godot]]
- **Language:** GDScript (varsayılan; C# opsiyon)
- **Platform:** Mobil (dikey, tek el). Küçük indirme + düşük cihaz hedefi.
- **Çizim tanıma:** $1 recognizer aday → [[Çizim Tanıma — $1 Recognizer]]

## Key Pages

- [[Rün Büyücüsü — Konsept]]
- [[Ekran Düzeni]] · [[Rün Çizim Mekaniği]] · [[Kombo ve Palet]] · [[Düşman Tasarımı]]
- [[Prototip M0]]
- [[Decisions Index]] · [[Code Map]] · [[Agent Playbook]]
