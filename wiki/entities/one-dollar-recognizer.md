---
type: entity
title: "Çizim Tanıma — $1 Recognizer"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - entity
  - tech
status: candidate
related:
  - "[[Rün Çizim Mekaniği]]"
  - "[[Prototip M0]]"
code_anchors: []
---

# Çizim Tanıma — $1 Recognizer

Aday tanıma teknolojisi. **Ağır bir şey gerekmiyor.**

## Neden

- $1 recognizer sınıfı algoritma çevrimdışı ve **anında** çalışır.
- Düşük cihazlarda sorun çıkarmaz.
- Küçük indirme / düşük cihaz performansı hedefiyle uyumlu.

## Tasarım kuralı

Rün formlarını tasarlarken tanıyıcının **karışma (confusion) matrisine** bak; karışan iki rünü tasarım aşamasında ayır. Sabit ölçekli çizim karesi tanıma doğruluğunu ciddi artırır (bkz [[Ekran Düzeni]]).

## Durum

**Araştırılmalı** — aday, kesin karar değil.
