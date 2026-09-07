---
type: decision
title: "Zaaf Bonustur, Kapı Değil"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - decision
status: active
priority: 3
date: 2026-09-07
owner: Ahmet Bilal Özgün
context: Düşman zaaf sistemi akışı bozmamalı
related:
  - "[[Düşman Tasarımı]]"
code_anchors: []
---

# Zaaf Bonustur, Kapı Değil

## Decision

Yanlış rün düşmana **%40 hasar** verir, sıfır değil. Doğru rün ödüllendirilir, yanlış rün cezalandırılmaz.

## Rationale

- Akış bozulmaz; oyuncu yanlış çizince duvara toslamaz.
- Zaaf silüetten okunur (ezber tablo değil) → doğru cevap refleksle gelir, bonus olur.

## Alternatives Considered

- Zaaf = kapı (yanlış rün 0 hasar) → hatırlama zinciri + hüsran geri gelir.

## Consequences

- Düşman HP ve rün hasar değerleri "%40 taban" varsayımıyla dengelenir.

## Status History
- 2026-09-07: created (approved)
