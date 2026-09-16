---
type: design
title: "Makro Oyun — Yol Haritası"
created: 2026-09-15
updated: 2026-09-16
verified: 2026-09-16
tags:
  - design
  - macro
status: active
related:
  - "[[Build Arketipi — Enhancement, Replacement Değil]]"
  - "[[Turn-Based Savaş ve QTE]]"
  - "[[Para Kazanma — Açık]]"
code_anchors:
  - repo: game
    symbol: RunManager
    file: scripts/rpg/run/run_manager.gd
  - repo: game
    symbol: RunMap
    file: scripts/rpg/run/run_map.gd
  - repo: game
    symbol: RunContent.campaign_map
    file: scripts/rpg/run/run_content.gd
  - repo: game
    symbol: ChoiceGenerator
    file: scripts/rpg/run/choice_generator.gd
  - repo: game
    symbol: RunScore
    file: scripts/rpg/run/run_score.gd
  - repo: game
    symbol: Challenge
    file: scripts/meta/challenge.gd
  - repo: game
    symbol: CodexData
    file: scripts/meta/codex_data.gd
---

# Makro Oyun — Yol Haritası

Mikro loop çözüldü (FIGHT → EXECUTE ritim-kombo → KILL → ORB → MULTIPLY board → CHOOSE → TRANSFORM). Makro loop cevaplaması gereken soru: **"neden bir sonraki run'ı oynuyorum?"** Cevap: **build keşfi**.

Kaynak: kullanıcının "Makro Oyun — Tasarım Önerileri" dokümanı + 2026-09-15 karar oturumu.

## Üç Katman

- **RUN:** Battle → Build (arketip) → Risk/Reward → Boss. Her run farklı build.
- **ACCOUNT / MASTERY:** stat meta (Altın CAN/HASAR) + ilerde spell/mutation/relic/discovery/collection.
- **ENDGAME:** ilerde Endless → Daily → Weekly → Leaderboard.

## Onaylanan Kararlar (2026-09-15)

1. **Build = enhancement, replacement değil.** Kimlik-swap durur; Burn/Crit/Explosion arketipi üstüne katman. Uygulama yolu B (ayrı sistem + arketip başına efekt havuzu). → [[Build Arketipi — Enhancement, Replacement Değil]]
2. **İçerik cadence:** her 3-5 bölümde bir build-değişim node'u; kalan bölümler stat meta (emniyet ağı korunur).
3. **Endless adaptive override:** Endless mode'da ritim-kombo **sürekli hızlanır** (adaptive yavaşlatma override edilir). Campaign'de adaptive ritim aynen kalır. ✅ **TAMAM (2026-09-15)** — `RunState.endless`/`depth`; `battle._on_input_requested` `maxf(adaptive, 1+depth·ENDLESS_RHYTHM_RAMP)`. → [[Turn-Based Savaş ve QTE]]
4. **Node map / route choice** ✅ **TAMAM (2026-09-15)** — StS sütun DAG'ı: `RunMap` (sütun/kenar kabı), `RunNode.next` kenarları, `RunManager` AWAITING_ROUTE+`choose`; `RunContent.campaign_map`; `battle.gd` harita ekranı (dallanma önden görülür). HEAL/TREASURE oda türleri eklendi. (İlk karar "ertelendi"ydi; kullanıcı çekti.)
5. **Sıralama:** run-end summary erkene (yakın vade). **Orb push-your-luck KALICI İPTAL (2026-09-16, kullanıcı kararı) — yapılmayacak.**

## Yakın Vade Task Listesi (öncelik sırası)

1. **Build arketip sistemi (B)** — makro motivasyonun çekirdeği. ✅ **TAMAM (2026-09-15)**
   - Yeni `Archetype` = build katmanı; `RunState.relic_set()` arketip efektlerini RelicSet'e ekler (motor mevcut hook'la okur).
   - `ChoiceOption.Kind.ARCHETYPE` + `ChoiceGenerator._archetype_candidates`; `generate()` dönüşüm slotunu garanti eder.
   - Ember havuzu: Alev Yükü / Öldürücü Ritim / Zincir Patlama. Tek yeni hook `on_kill_aoe`. 189 test.
2. **Run-end summary ekranı** ✅ **TAMAM (2026-09-15)** — `battle._show_run_summary`: başlık + build kimliği (form + arketip) + relikler + kazanılan değer. **Numeric score + best ✅ TAMAM (2026-09-16)** — `RunScore.compute` (saf: düğüm/kat + relik + arketip + elit/boss + zafer), `Meta.best_score`/`record_score`, özet panelde "★ PUAN … (rekor …)".
3. **Elite battle (risk/reward)** ✅ **TAMAM (2026-09-15)** — `RunNode.Type.ELITE` (boss'tan önce, i>=3), daha güçlü düşman (HP×1.7/DMG×1.3) + çift orb (`ELITE_ORB_MULT`). Elit "build'i sınayan özel kural" (hızlı ritim/direnç) **KALICI İPTAL (2026-09-16, kullanıcı kararı) — yapılmayacak.** Elit farkı HP/DMG/orb ölçeği olarak kalır.
4. **Content cadence wiring** ✅ **TAMAM (2026-09-15)** — `RunContent.is_build_level(i)` (i=3,7,11,15,19); `RunState.allow_archetypes` gate; arketip yalnız build-bölümlerinde, relic/dönüşüm her zaman.
5. **(Endless fazında)** adaptive-ritim override — sürekli hızlanan kombo. ✅ **TAMAM (2026-09-15)** — gerçek endless mode kuruldu (bkz aşağı).

**Durum:** yakın-vade task 1-4 TAMAM (2026-09-15). Sonra "ertelendi" 3 parça da TAMAM (2026-09-15, 253 test): (a) mastery CLAIM butonu (elle topla, → [[Mastery / Battle-Pass]]), (b) StS node map (dallanmalı ilerleme + HEAL/TREASURE odaları), (c) gerçek ENDLESS mode (home "♾ ENDLESS" girişi, sonsuz `RunMap.extend`, ritim override, oda başı altın + ölümde banka + `endless_best_depth`). Kod: `run_map.gd`, `run_manager.gd` (route flow), `run_content.gd` (campaign_map/endless_map), `battle.gd` (harita ekranı + endless). UI (harita/claim popup/endless ritim) telefonda elle doğrulanmalı; endless zorluk + ritim ramp sabitleri tune edilecek.

## Sonraki Fazlar (doküman §16)

- **Faz 2 — Build Meta:**
  - **Plazma arketip havuzu ✅ TAMAM** — `RunContent.plasma_archetypes()` (Kör Eden / Kritik / Patlayıcı Plazma), `skill_catalog`'a register, Ember→Plazma dönüşümü kablolu (wiki daha önce yanlışlıkla "başlamadı" diyordu, düzeltildi 2026-09-16).
  - **Discovery sistemi ✅ TAMAM (2026-09-16)** — `Meta.discovered` + `Meta.discover(key)`; battle hook'ları form/arketip/relik/düşman ilk karşılaşmada işler. Anahtarlar `CodexData` (RunContent türevi).
  - **Codex/spellbook ✅ TAMAM (2026-09-16)** — `scenes/codex.tscn` + `scripts/codex.gd`: keşfedilen=isim+açıklama, keşfedilmemiş=🔒 ???, "KEŞİF n/total". Home'da "📖 KODEKS" girişi.
  - character vs build progression ayrımı: karakter progression erken başladı: [[Mastery / Battle-Pass]] — arketipler mastery track'iyle açılıyor, 2026-09-15.
- **Faz 3 — Long-Term:** Endless mode ✅ (2026-09-15). Leaderboard + geniş içerik havuzu açık (leaderboard'un yerel async stub'ı Faz 4'te kuruldu).
- **Faz 4 — Live/Competitive ✅ TAMAM (2026-09-16, sunucusuz MVP):** Günlük/haftalık meydan okuma (`Challenge.daily_seed`/`weekly_seed` — tarihten deterministik seed, aynı gün herkes aynı harita) + async sosyal STUB (`Challenge.percentile` lojistik eğri → "oyuncuların %N'ini geçtin"). Skorlar `Meta.daily_best`/`weekly_best`. **Gerçek sunucu leaderboard'u hâlâ açık** — percentile() sunucu gelince gerçek dağılımla değişir, çağrı yerleri sabit.

## Tasarım İlkeleri (korunacak)

1. Makro mikro loop'un önüne geçmez (ana eğlence: skill → execution → feedback → reward).
2. Her run farklı build/hikâye üretir.
3. Kalıcı ilerleme oyun alanını genişletir (içerik > düz stat) — ama stat meta emniyet ağı olarak kalır.
4. Kaybedilen run boşa gitmez (mastery/discovery/collection progress). Fail-soft ilkesiyle uyumlu.
5. Sonsuzluk sonradan gelir — önce tek iyi run kanıtlanır.
