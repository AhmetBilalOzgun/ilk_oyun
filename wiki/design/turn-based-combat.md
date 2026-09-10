---
type: design
title: "Turn-Based Savaş ve QTE"
created: 2026-09-10
updated: 2026-09-10
verified: 2026-09-10
tags:
  - design
  - system
status: approved
domain: system
related:
  - "[[Rün Çizim Mekaniği]]"
  - "[[Kombo ve Palet]]"
  - "[[Zaaf Bonustur, Kapı Değil]]"
  - "[[Sessiz Başarısızlık Yok]]"
code_anchors:
  - repo: game
    symbol: TurnManager
    file: scripts/rpg/turn_manager.gd
  - repo: game
    symbol: Skill
    file: scripts/rpg/skill.gd
  - repo: game
    symbol: Combatant
    file: scripts/rpg/combatant.gd
  - repo: game
    symbol: BattleDamage.compute
    file: scripts/rpg/battle_damage.gd
  - repo: game
    symbol: EnemyAI.choose_action
    file: scripts/rpg/enemy_ai.gd
  - repo: game
    symbol: FakeRecognizer
    file: scripts/core/fake_recognizer.gd
  - repo: game
    symbol: TurnDebugOverlay
    file: scripts/rpg/turn_debug_overlay.gd
---

# Turn-Based Savaş ve QTE

Oyun gerçek zamanlı dalga savunmasından **turn-based parti RPG**'sine dönüştürüldü
(2026-09-10). Rün çizimi kalır ama rolü değişti: sürekli kombo değil, bir beceri
kullanılırken tetiklenen **sınırlı süreli QTE**.

## Tur akışı

1. **Sıra hesaplama** — tur başında canlı katılımcılar `speed`'e göre sıralanır
   (yüksek önce, stabil; klasik sıra listesi, ATB yok). `TurnManager._start_round`.
2. **Oyuncu sırası** — beceriler menüde listelenir, oyuncu beceri + hedef seçer
   (`select_action`) → durum `QTE`.
3. **QTE** — seçilen becerinin `rune_id`'si telegraf olarak gösterilir; oyuncu
   `qte_time_limit` içinde çizer. `tick(unscaled_dt)` geri sayar.
4. **Çözümleme** — tanınan rün `skill.rune_id`'ye eşitse başarı.
5. **Düşman sırası** — `EnemyAI.choose_action`: en düşük canlı hedefe en yüksek
   `base_damage`'lı beceri (QTE yok, taban hasar).

## İki ilke (kodda zorlanır — `BattleDamage.compute`)

- **Fail-soft QTE**: başarısızlık saldırıyı İPTAL ETMEZ, sadece bonusu kaybettirir.
  `recognizer` null dönse veya süre dolsa bile taban hasar uygulanır.
- **Hasar asla sıfır**: `weakness_effects` → ekstra çarpan (×1.5), `resist_effects`
  → azaltma (×0.5) ama `max(1, ...)`. Zaaf bonustur, kapı değil.

Hasar: `base → (QTE başarılıysa ×qte_bonus_multiplier) → (×zaaf VEYA ×direnç) → max(1)`.
Ayrıştırılmış döküm `DamageBreakdown`'da (overlay taban+bonus+zaaf'ı ayrı gösterir).

## Beceri modeli — 2 normal + 1 birleşim (2026-09-10)

Her karakterin **3 büyüsü** var: 2 rün-özel **NORMAL** + 1 **BİRLEŞİM** (ultimate).
Strike kaldırıldı (fail-soft QTE zaten taban hasar veriyor, ayrı düz-vuruş gereksiz).

- **Normal beceri**: tek rün QTE (`Skill.rune_id`), başarıda `qte_bonus_multiplier`
  (1.4–1.6).
- **Birleşim beceri** (`requires_charge = true`): şarj barı dolunca menüde açılır.
  QTE'de **yeni şekil yok** — kaynak rünleri **peş peşe** çizilir
  (`Skill.rune_sequence`, ör. `["ember","storm"]`). Her adım doğru → ilerle
  (pencere yenilenir); tümü doğru → **büyük buff** (bonus ×2.5, normalden yüksek).
  Kullanınca şarj sıfırlanır (başarısız olsa bile tüketilir — commit edildi).

Test verisi (`TestBattleData`): **Kayra** Plazma = ember→storm (yakma DoT),
**Derin** Fırtına = frost→gale (stun).

## Şarj barı

`Combatant.charge` / `charge_max` (varsayılan 100, `BattleConfig.charge_max`).
Hasar **verildiğinde ve alındığında** miktar kadar dolar (vurana + yiyene, DoT dahil).
`select_action` şarj dolu değilse birleşim becerisini reddeder (UI de sunmamalı).

## Durum sistemi (birleşim kimliği)

Sıra **başında** işlenir (`TurnManager._begin_turn`), önce yakma sonra stun:

- **Yakma / DoT** (`Skill.dot_fraction`): hedef bir sonraki turu başında son hasarın
  bu oranını (Plazma %40) bir kez daha yer; şarjı da doldurur. Sinyal `dot_applied`.
- **Stun** (`Skill.applies_stun`): hedef bir sonraki turunu atlar. Sinyal `stun_skipped`.

## Veri modelleri

`Character`, `Skill`, `Enemy`, `Combatant` (`scripts/rpg/`). `Enemy`'ye MVP'de
`skills` eklendi (`EnemyAI` saldırı listesi gerektiriyor; düşman QTE yapmaz).
`Skill` birleşim alanları: `requires_charge`, `rune_sequence`, `dot_fraction`,
`applies_stun`.

## Kombo/füzyon motoru SİLİNDİ (2026-09-10)

Eski gerçek-zamanlı kombo/füzyon motoru **tamamen kaldırıldı** (dosyalar silindi,
`deprecated/` dahil): `main.gd`, `main.tscn`, `combo_resolver`, `damage_rules`,
`resolved_spell`, `debug_overlay` + kombo test suite'leri. `RuneDB` sadeleşti
(`runes` + `shape_to_rune`); füzyon/timeScale/pencere/overdrive alanları gitti.
`TurnManager` füzyon iskeleti (`recent_effects`) ve `BattleConfig.enable_elemental_reactions`
silindi. Korunan: `RuneDB`, `IRuneRecognizer`, `FakeRecognizer`, `RecognizerAdapter`,
`RuneTrail`.
