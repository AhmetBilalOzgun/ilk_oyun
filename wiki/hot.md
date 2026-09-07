---
type: meta
title: "Hot Cache"
updated: 2026-09-07
verified: 2026-09-07  # çizim izi + rün hayaleti eklendi
---

# Recent Context

> [!warning] Staleness
> Any product/build-state claim below older than 14 days is a **hypothesis, not a fact** (see Staleness Contract in `CLAUDE.md`). Verify against code, graph, or the running build before acting, then bump `verified:`.

## Last Updated
2026-09-07 — **Çizim juice eklendi** (`scripts/rune_trail.gd`): canlı iz (parmak arkasında parlak hat + uç noktası). `RuneTrail` Node2D en son child → DrawCanvas üstüne çizer; main `set_live()` besler. "Çizerken önizleme" kolonunu karşılar. (Rün hayaleti fikri denendi, tasarımcı kararıyla iptal edildi.)
(önceki: **Kombo sistemi çekirdeği çalışıyor**.)

### (arşiv) Kombo sistemi çekirdeği
2026-09-07 — **Kombo sistemi çekirdeği çalışıyor**. İki katman: saf `RefCounted` çekirdek (`scripts/core/`, motordan bağımsız, `unscaled_dt` alır) + motor adaptörü (`main.gd`). Sınıflar: `ComboResolver` (saf: taşıyıcı=ilk rün, etki union+füzyon, hasar ×1.6/rün), `ComboStateMachine` (Idle→Casting→Window, overdrive), `ChargeMeter`, `ChainTracker`, `TimeScaleController`, `RuneDB`, `DamageRules`. **Kritik:** tüm kombo zamanlaması duvar saatinden (`Time.get_ticks_usec`) → `Engine.time_scale`'den bağımsız (pencere yavaşlamaz). Tuning: `data/combo_config.json`. Recognizer null→strike. Debug overlay F1. Test: `godot --headless -s res://tests/run_tests.gd` → 56/56 geçti. → [[Kombo ve Palet]]
(önceki: **Tank melee düşman** — `scripts/enemy.gd`, yürü+menzilde melee, HP 400.)

### (arşiv) Tank melee düşman
2026-09-07 — **Tank melee düşman çalışıyor**. Yeniden kullanılabilir `Enemy` node'u (`scripts/enemy.gd`, preload + `setup`/`tick`, health.gd pattern'i). Gövdeyi oyuncuya doğru yürütür, menzile girince melee vurur. Tank profili: HP 400, hasar 5, hız 45 px/sn, cooldown 1.4 sn. Oyuncu artık gerçekten hasar alıyor; saldırı yalnız menzilde (eski uzaktan-hasar bug'ı yok). Can çubuğu yürüyen tankı takip eder. run_project ile test: yürüdü/vurdu/400 HP'de öldü, hata yok. → [[Düşman Tasarımı]], [[Can ve Hasar Sistemi]]
(önceki: `Health`+`HealthBar` bileşenleri, 100 HP, mermi hasarı 10–30; 4 rün tanıma + renkli mermi.)

## Key Recent Facts
- **Rün Büyücüsü** — dikey 2D dalga savunması. Alt-orta sabit kareye rün çizilir → soldaki büyücü sağdaki düşmana fırlatır. Rünler zincirlenip kombo yapar. → [[Rün Büyücüsü — Konsept]]
- Fark: girdi = üretim (seçim değil), "ben yaptım" hissi. Reklam = oynanış (dilsiz, 6 sn).
- **Onaylı kararlar:** sabit çizim karesi ([[Ekran Düzeni]]), savaşa 4 rün ([[Loadout Kısıtı]]), sessiz başarısızlık yok ([[Sessiz Başarısızlık Yok]]), zaaf bonus %40 ([[Zaaf Bonustur, Kapı Değil]]).
- **Bilişsel yük 4 kolonu:** loadout, çizerken önizleme, sessiz başarısızlık yok, rün formu kısıtları (2–3 çizgi, köşeli, ayrık silüet). → [[Rün Çizim Mekaniği]]
- **Düz çizgi** = temel saldırı + başarısızlık tabanı + komboyu taşır.
- Tanıma: **$1 recognizer** aday (araştırılacak). Karışma matrisine göre rün ayır.
- **Can/hasar var** (`scripts/health.gd`, `health_bar.gd`): tekrar kullanılır `Health`/`HealthBar`. Kombo hasar çarpanı + juice + dalga henüz yok. → [[Can ve Hasar Sistemi]]
- **Tank düşman var** (`scripts/enemy.gd`): yürü + menzilde melee. Stat override ile başka arketipler (swarm) aynı node'dan. Spawn/dalga + silüetten zaaf okuma eksik. → [[Düşman Tasarımı]]

## Open Tasks
- [[Prototip M0]] yap: 4 rün + düz çizgi, tek dalga, swarm+tank, ~30 sn. Telefonda, tek elle.
- Test: birine 20 dk oynat → **20. dk'da düşünerek mi refleksle mi çiziyor?** (D7 tekrar riski ölçümü)

## Open Bugs
- _(none yet)_

## Kararı Verilmeyen (tahmin üretme)
- Para kazanma modeli ([[Para Kazanma — Açık]]) — beceri↔ödeme çelişkisi çözülmedi.
- Uzun vadeli çekim/2. oynanış sebebi, ilerleme/meta, geri dönüş kancası, sosyal.
- 50. dalga kutlama ölçeği. Uzun vadeli dönüşüm planı. (Kombo penceresi süresi artık `data/combo_config.json`'da — prototipte ayarlanacak, mimari karar değil.)
