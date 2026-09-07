---
type: deliverable
title: "Prototip M0"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - deliverable
  - milestone
status: planned
related:
  - "[[Rün Büyücüsü — Konsept]]"
  - "[[Rün Çizim Mekaniği]]"
  - "[[Düşman Tasarımı]]"
code_anchors: []
---

# Prototip M0

İlk çalışan prototip. Kâğıtta değil — **telefonda, tek elle.**

## Kapsam

- **4 rün** + düz çizgi
- **Tek dalga**
- **2 düşman tipi:** swarm (kalabalık+küçük) + tank (büyük+zırhlı)
- **~30 saniye** oynanış

## Test protokolü

Birine **20 dakika kesintisiz** oynat.

## Ölçülecek tek soru

> 20. dakikada hangi rünü çizeceğini **düşünüyor mu**, yoksa **refleksle mi** çiziyor?

- Düşünüyorsa → mekanik tutar, devam.
- Refleksle çiziyorsa → çizim yavaş bir butona dönüşmüş. Mekaniği sürüklemeye ya da kısa jestlere (çizgi, köşe, yay) indirmek gerekir.

## Bağımlılıklar / açık

- Çizim tanıma: $1 recognizer sınıfı algoritma yeterli → [[Çizim Tanıma — $1 Recognizer]].
- Rün formlarını tasarlarken tanıyıcının karışma matrisine bak; karışan iki rünü tasarım aşamasında ayır.
