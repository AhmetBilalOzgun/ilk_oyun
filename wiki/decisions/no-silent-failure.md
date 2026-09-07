---
type: decision
title: "Sessiz Başarısızlık Yok"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - decision
status: active
priority: 2
date: 2026-09-07
owner: Ahmet Bilal Özgün
context: Çizim tanıma hatasının oyuncu deneyimini bozmaması
related:
  - "[[Rün Çizim Mekaniği]]"
code_anchors: []
---

# Sessiz Başarısızlık Yok

## Decision

Sistem asla "anlaşılmadı" demez. Her çizgi en yakın rüne yuvarlanır; hiçbir şeye benzemiyorsa **düz vuruşa** düşer.

## Rationale

- "Oyun beni anlamadı" hissi hiç yaşanmaz.
- Düz vuruş zaten başarısızlık tabanı olarak tasarlandı → doğal düşme noktası.

## Alternatives Considered

- Tanınmayan çizimi reddetmek → hüsran, akış kırılır, çizim korkusu.

## Consequences

- Tanıyıcının her zaman bir çıktı üretmesi gerekir (reddetme yok).
- Düz vuruşun dengesi kritik (spam ↔ dekor).

## Status History
- 2026-09-07: created (approved)
