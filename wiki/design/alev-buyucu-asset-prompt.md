---
type: design
title: "Alev Büyücüsü — Pixel Art Asset Promptu"
created: 2026-09-14
updated: 2026-09-14
verified: 2026-09-14  # kombo ritim dövüşü için gereken alev büyücüsü asset listesi
tags:
  - design
  - assets
  - art
status: approved
domain: art
related:
  - "[[Turn-Based Savaş ve QTE]]"
---

# Alev Büyücüsü — Pixel Art Asset Promptu

Kombo ritim dövüşü (per-tile büyü + finisher) için gereken assetler. **Sadece alev
büyücüsü.** Aşağıdaki blok bir pixel-art üretim agent'ına doğrudan verilebilir.

**Mevcut ile tutarlılık (kod referansı, `scripts/battle.gd`):** wizard kare ~256px
(`WIZARD_SCALE=0.9`), fireball sağa (+x) uçar, transparan PNG. Mevcut set:
`assets/wizard/wizard_fire_frames.tres` (idle/cast/hurt/walk/ult/levelup/victory/death),
`assets/wizard/fx_fireball.png`, `fx_fire_comet.png`. Yeni assetler bunlarla aynı palet/ölçekte olmalı.

## Prompt (agent'a ver)

```
Pixel-art asset seti — "Alev Büyücüsü" (fire mage) turn-based RPG kombo ritim savaşı.
Stil: retro pixel art, koyu fantezi palet (amber/turuncu/kızıl alev + koyu mor gölge),
temiz siluet, transparan arka plan (PNG). Sağa bakan yön (+x). Yatay sprite-sheet, her
frame eşit hücre, hücre boyutu 256×256 (mevcut wizard ile aynı ölçek).

1) wizard_fire — karakter animasyon seti (tek sheet, satır başına animasyon):
   - idle (4 frame, hafif nefes/alev titreşimi)
   - cast_small (4 frame) — tek elle küçük ateş atışı (normal tile büyüsü)
   - cast_finisher (6 frame) — iki elle büyük alev patlatma pozu (kombonun son vuruşu;
     dramatik, ekstra ışık/parıltı)
   - hurt (2 frame), victory (4 frame), death (4 frame)
   Tutarlılık: ayak çizgisi tüm framelerde sabit, merkezli.

2) Escalating fireball mermileri (ayrı PNG'ler, sağa uçar, ~64–96px):
   - fireball_s.png (küçük, kombo 1. tile)
   - fireball_m.png (orta, ara tile)
   - fireball_l.png (büyük, son normal tile)
   - fireball_finisher.png (dev alev topu/komet, finisher; iz/parıltılı)

3) Impact efektleri (kare sheet, patlama animasyonu, transparan):
   - hit_spark_small (4 frame, ~64px) — normal tile isabeti
   - hit_burst_finisher (6 frame, ~128px) — finisher patlaması (ekran-dolduran alev)

4) Ritim tile UI ikonları (alev temalı, 5 yön, ~84×84, tek sheet):
   - tap (●), swipe_left (◀), swipe_right (▶), swipe_up (▲), swipe_down (▼)
   Her biri alevden yontulmuş rün/glif hissi; MÜKEMMEL isabet için parlayan varyant
   (glow overlay) da üret.

5) "PERFECT" isabet flash sprite (~96px, 3 frame parıltı) — haptik ile eşzamanlı görsel.

Teslim: her asset ayrı PNG + (mümkünse) Godot SpriteFrames'e uygun eşit-hücreli yatay
sheet. Palet ve ölçek yukarıdaki mevcut wizard setiyle bire bir uyumlu olmalı.
```

## Kod entegrasyon notları (assetler gelince)

- `cast_finisher` → `battle._on_tile_resolved` finisher dalında `_play_anim(caster,"ult")`
  yerine yeni anim adı bağlanabilir; normal tile `cast_small`.
- `fireball_s/m/l/finisher` → `battle._fx_projectile` şu an tek `FX_FIREBALL` + `scale`
  parametresiyle escalation yapıyor; ayrı sprite'lar için tile index/finisher'a göre texture
  seçimi eklenebilir.
- `tile UI ikonları` → şu an `RhythmMinigame._create_pixel_tile` PixelFont sembolleri (`●◀▶▲▼`)
  çiziyor; sprite geldiğinde Label yerine `Sprite2D` bağlanır.
- Placeholder gelene kadar kod mevcut `fx_fireball.png` + prosedürel tile ile çalışır (fail-soft görsel).
```
