---
type: decision
title: "Build Arketipi — Enhancement, Replacement Değil"
created: 2026-09-15
updated: 2026-09-15
verified: 2026-09-15
tags:
  - decision
  - macro
status: active
priority: 2
date: 2026-09-15
owner: Ahmet Bilal Özgün
context: Makro oyunun ana motivasyonu build keşfi; kimlik-swap sistemini bozmadan build arketipi eklemek
related:
  - "[[Makro Oyun — Yol Haritası]]"
  - "[[Turn-Based Savaş ve QTE]]"
code_anchors:
  - repo: game
    symbol: Archetype
    file: scripts/rpg/archetype.gd
  - repo: game
    symbol: ChoiceGenerator
    file: scripts/rpg/run/choice_generator.gd
  - repo: game
    symbol: RunState
    file: scripts/rpg/run/run_state.gd
---

# Build Arketipi — Enhancement, Replacement Değil

## Decision

Makro oyunun ana motivasyonu **build keşfi** ("bu run'da nasıl bir büyücü kuruyorum?"). Bunu mevcut sisteme **katman (enhancement)** olarak ekleriz — **replacement değil**:

1. **Kimlik-swap DURUR.** Storm rünü Ember'i Plazma'ya komple dönüştürmeye devam eder (mevcut sistem korunur).
2. Üstüne **build arketipi** gelir: wave-arası CHOICE'ta oyuncu **Burn / Critical / Explosion** gibi bir arketip seçer → aktif formu modifiye eder ("Burn Ember" gibi). Arketipler transform'la çakışmaz, birlikte stacklenir. Aynı 3 arketip Plazma için de yapılır (form başına arketip havuzu).
3. **Uygulama yolu = B (ayrı arketip sistemi).** CHOICE'a ayrı arketip-seçim ekranı + **arketip başına ayrı efekt havuzu**. (Reddedilen A: mevcut relic'leri aile-etiketleyip emergent build — daha ucuzdu ama daha az net.)

## Rationale

- Build keşfi bu oyuna oturuyor: kod zaten transform + relic + equipment ile build hissi üretiyor. Arketip bunu **oyuncunun bilinçli seçtiği** net bir eksene çevirir.
- Enhancement olması mevcut kimlik-swap yatırımını korur, mikro loop'u bozmaz.
- B yolu (ayrı sistem) daha çok authored içerik ister ama arketip kimliği **net** olur — oyuncu "Burn build kuruyorum" diyebilsin.

## İçerik Maliyeti — Emniyet Ağı

Arketip = pahalı authored içerik. Bu yüzden:

- **Her 3-5 bölümde bir** build-değişim node'u (arketip seçimi / evrim).
- **Kalan bölümler stat meta'ya devam** (Altın ile CAN/HASAR upgrade — ucuz retention tabanı). Stat meta kaldırılmaz, ikincil katman olur.

## Alternatives Considered

- **A — Relic aile-etiketi (emergent build):** mevcut relic'leri burn/crit/explosion aileleriyle etiketle, aynı aileden üst üste gelince build kendiliğinden oluşur. Ucuz + kod yeniden kullanımı yüksek. Reddedildi: build kimliği yeterince net değil.
- **Combo matrisini geri getirip emergent discovery:** 2026-09-13 redesign matrisi sildi (kimlik-swap geldi). Geri getirmek istenmedi.

## Consequences

- `ChoiceOption`'a yeni arketip tipi + `ChoiceGenerator` arketip seçimi üretir.
- `MageForm` üstüne arketip modifier katmanı (transform ile birlikte uygulanır).
- Arketip başına × form başına efekt havuzu authored edilmeli (önce Ember: Burn/Crit/Explosion; sonra Plazma).
- Denge: build-node cadence (3-5) + stat-meta arası soft-gate telefonda test edilmeli.

## Refinement — Dışlayıcı Commit (2026-09-15)

İlk impl arketipleri **stacklenen buff paketi** yaptı (relic-hook bundle + form adı ön eki); kullanıcı "seçimi ifade etmeliydi" dedi. Karar güncellendi:

- **Dışlayıcı:** run'da yalnız BİR arketip commit edilir; diğerleri o run kilitlenir ("Burn VEYA İnfaz VEYA Patlama"). Gate: `ChoiceGenerator._archetype_candidates`, loadout'ta arketip varsa hiç sunmaz.
- **Davranış farkı, sadece +sayı değil:** 🔥 Alev = DoT, 🎯 İnfaz = tek hedef execute+lifesteal (alan yok), 💥 Patlama = yeni `basic_splash` hook ile normal saldırı alana yayılır + ölüm zinciri.
- **Netleştirme:** arketip = DÖNÜŞÜM DEĞİL. Gerçek kimlik dönüşümü = kimlik-swap (Storm rünü → Plazma). Arketip form'un ÜSTÜNDE dışlayıcı build yönü.
- **Açık:** dokümanın "ayrı arketip-seçim ekranı" (3 seçenek tek ekran yan yana) hâlâ yapılmadı — şu an CHOICE pool'unda tekli sunuluyor. Follow-up.

## Status History
- 2026-09-15: created (approved — B seçildi)
- 2026-09-15: implemented (task #1) — `Archetype` + ARCHETYPE seçimi + Ember havuzu + `on_kill_aoe` hook, 189 test. → log.md
- 2026-09-15: refined — **dışlayıcı commit** + davranış farkı (`basic_splash`) + arketip ikonları, 206 test. → log.md
