---
type: design
title: "Mastery / Battle-Pass"
created: 2026-09-15
updated: 2026-09-15
verified: 2026-09-15
tags:
  - design
  - macro
  - meta
status: active
related:
  - "[[Build Arketipi — Enhancement, Replacement Değil]]"
  - "[[Makro Oyun — Yol Haritası]]"
  - "[[Para Kazanma — Açık]]"
code_anchors:
  - repo: game
    symbol: MasteryTrack
    file: scripts/meta/mastery_track.gd
  - repo: game
    symbol: MetaProgress.add_mastery
    file: scripts/meta/meta_progress.gd
---

# Mastery / Battle-Pass

Kalıcı **karakter ilerleme** katmanı (doküman §7 "Character Progression"). Kullanıcı yönü
(2026-09-15): arketipler ve bazı eşyalar **rastgele çıkmasın** — oyuncu oynadıkça dolan
bir barla **sırayla açılsın** (battle-pass mantığı). Retention omurgası: "oyunu açarken
bir sonraki ödüle ne kadar yakınım?"

## Nasıl çalışır

1. **Mastery XP** — her savaş zaferi mastery kazandırır (`MASTERY_PER_WIN=12`, ELITE
   `+15`, BOSS `+20`). `battle.gd` savaş bitişinde `Meta.add_mastery(gain)` çağırır.
2. **Track (`MasteryTrack.TIERS`)** — kümülatif eşikli sıralı ödül listesi. Ödül tipleri:
   `archetype` (build yönü açılır), `equipment` (parça verilir), `gold`, `crystal`.
   Bir eşik dolunca **hak edilir** ama ödül **ELLE toplanır** (2026-09-15): `add_mastery`
   sadece XP ekler; `claimable_count()` hak edilmiş-toplanmamış sayısı; `claim_next()`
   sıradaki tier'ı uygular. Home'da nabızlı **"🎁 TOPLA (n)"** + ödül popup (aç→topla
   dopamini). `claimed_tiers` çifte ödülü önler; kalıcı (`user://meta.json`).
3. **Arketip gating** — açılan arketip `Meta.unlocked_archetypes`'a girer. Run başında
   `battle.gd` bunu `RunState.unlocked_archetypes`'a kopyalar; `ChoiceGenerator` yalnız
   AÇILAN arketipleri CHOICE havuzunda sunar. Kilitli olan hiç çıkmaz.
4. **Ana ekran UI** — `home.gd` mastery çubuğu + "Sıradaki: 🎯 İnfaz build (X/Y)".

## Arketip erişiminin üç kapısı (hepsi geçilmeli)

Bir arketibin CHOICE'ta çıkması için:
1. **Açılmış** olmalı (mastery track) — kalıcı.
2. **Build-bölümü** olmalı (`is_build_level`: i=3,7,11,15,19) — cadence.
3. Büyücü **henüz commit etmemiş** olmalı (dışlayıcı: run'da 1 arketip).

## v1 Track

| Eşik | Ödül |
|---|---|
| 40 | 🔥 Alev build |
| 110 | 👢 Köz Çizme (eşya) |
| 200 | 🎯 İnfaz build |
| 320 | 💰 200 Altın |
| 470 | 💥 Patlama build |
| 650 | 🛡 Alev Zırhı (eşya) |
| 900 | 💎 5 Kristal |

## Ertelenen / açık

- ~~**Claim etkileşimi** (battle-pass "topla" butonu + ödül gösterisi)~~ ✅ **TAMAM (2026-09-15)** — elle TOPLA + popup (`claim_next`).
- **Premium track** (kristalle ikinci sıra) — ileride.
- Eşik/kazanç dengesi telefonda tune edilecek (prototip değerleri).
- Track döngüsü / sonsuz tier (endless ile) — sonra.
