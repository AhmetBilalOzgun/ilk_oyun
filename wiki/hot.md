---
type: meta
title: "Hot Cache"
updated: 2026-09-10
verified: 2026-09-10  # şarj barlı birleşim becerileri + kombo/füzyon motoru silindi
---

# Recent Context

> [!warning] Staleness
> Any product/build-state claim below older than 14 days is a **hypothesis, not a fact** (see Staleness Contract in `CLAUDE.md`). Verify against code, graph, or the running build before acting, then bump `verified:`.

## Last Updated
2026-09-10 — **Şarj barlı birleşim becerileri + kombo/füzyon motoru SİLİNDİ** (verified 2026-09-10): Beceri modeli yenilendi. Strike kaldırıldı. Her karakter **3 büyü** = 2 rün-özel NORMAL + 1 **BİRLEŞİM** (ultimate). Birleşim yeni şekil getirmez — kaynak rünler QTE'de **peş peşe** çizilir (Kayra Plazma = ember→storm, Derin Fırtına = frost→gale); tümü doğru → büyük buff (bonus ×2.5). **Şarj barı**: hasar ver+al miktarı kadar dolar (`Combatant.charge`, max 100), dolunca birleşim açılır, kullanınca sıfırlanır. **Durum sistemi**: Plazma yakma DoT (sonraki tur %40 tekrar hasar, `Skill.dot_fraction`), Fırtına stun (`applies_stun`, bir tur atla) — ikisi de `TurnManager._begin_turn`'de sıra başında işlenir. **Kombo/füzyon tamamen silindi**: eski gerçek-zamanlı motor (`main.gd`/`combo_resolver`/`damage_rules`/`resolved_spell`/`debug_overlay`), 3 test suite, tüm `deprecated/`; `RuneDB` sadeleşti (runes+shape_to_rune), `combo_config.json` küçüldü. Test 46/46. → [[Turn-Based Savaş ve QTE]]
(önceki: **Turn-based RPG'ye dönüşüm**)

2026-09-10 — **Turn-based RPG'ye dönüşüm** (verified 2026-09-10): Gerçek zamanlı dalga savunması → **turn-based parti RPG**. Rün çizimi kalır ama rolü değişti: sürekli kombo DEĞİL, beceri kullanılırken tetiklenen **sınırlı süreli QTE**. Yeni saf çekirdek `scripts/rpg/`: `TurnManager` (IDLE→SELECTING_ACTION→QTE→RESOLVING→NEXT_TURN, `tick(unscaled_dt)`, motordan bağımsız), `Character`/`Skill`/`Enemy` (Resource), `EnemyAI` stub (en düşük HP → en yüksek hasar), `BattleDamage` (fail-soft + hasar asla sıfır), `TurnDebugOverlay`. `RuneDB`/`IRuneRecognizer` yeniden kullanıldı, `FakeRecognizer` eklendi. Demo: `scenes/battle.tscn`. Eski kombo çekirdeği (`ComboStateMachine`/`ChargeMeter`/`ChainTracker`/`TimeScaleController`) → `deprecated/`. Test 79/79. → [[Turn-Based Savaş ve QTE]]
(önceki: **Yeni sürüm APK telefona kuruldu**)

2026-09-07 — **Yeni sürüm APK telefona kuruldu** (verified 2026-09-07): `build/wizard_game.apk` yeniden export (27MB→37MB, menü+UI assetleri büyüttü), `adb install -r` ile Xiaomi emerald'a kuruldu + launcher intent ile başlatıldı. Toolchain PATH'te değil, sabit yollar: Godot `~/Downloads/Godot.app/Contents/MacOS/Godot`, JDK17 `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`, Android SDK `/opt/homebrew/share/android-commandlinetools` (adb = `platform-tools/adb`). Build: `JAVA_HOME=... Godot --headless --path . --export-debug "Android" build/wizard_game.apk`. → log.md
(önceki: **Ana menü eklendi**)

2026-09-07 — **Ana menü eklendi** (verified 2026-09-07): `scenes/main_menu.tscn` + `scripts/main_menu.gd`. Açılış sahnesi artık menü (`project.godot` main_scene). Başlık + 3 buton (OYNA→oyun, AYARLAR→"yakında" paneli, ÇIKIŞ). Butonlar Kenney UI Pack Pixel Adventure 9-patch tile'ları (`assets/ui/*.png`, StyleBoxTexture). Global texture filter Nearest (pixel-art). → log.md
(önceki: **İlk Android APK build alındı**)

2026-09-07 — **İlk Android APK build alındı** (verified 2026-09-07): `build/wizard_game.apk` (27MB, arm64-v8a, debug-signed). Toolchain sıfırdan kuruldu (OpenJDK 17 + Android SDK build-tools;35 + export şablonları + debug keystore). Prebuilt yol (`use_gradle_build=false`). `project.godot`'a ETC2/ASTC compression zorunlu eklendi. Build komutu: `Godot --headless --path . --export-debug "Android" build/wizard_game.apk` (JAVA_HOME set). → log.md
(önceki: **Çizim juice eklendi** — `scripts/rune_trail.gd`: canlı iz.)
(önceki: **Kombo sistemi çekirdeği çalışıyor**.)

### (arşiv) Kombo sistemi çekirdeği
2026-09-07 — **Kombo sistemi çekirdeği çalışıyor**. İki katman: saf `RefCounted` çekirdek (`scripts/core/`, motordan bağımsız, `unscaled_dt` alır) + motor adaptörü (`main.gd`). Sınıflar: `ComboResolver` (saf: taşıyıcı=ilk rün, etki union+füzyon, hasar ×1.6/rün), `ComboStateMachine` (Idle→Casting→Window, overdrive), `ChargeMeter`, `ChainTracker`, `TimeScaleController`, `RuneDB`, `DamageRules`. **Kritik:** tüm kombo zamanlaması duvar saatinden (`Time.get_ticks_usec`) → `Engine.time_scale`'den bağımsız (pencere yavaşlamaz). Tuning: `data/combo_config.json`. Recognizer null→strike. Debug overlay F1. Test: `godot --headless -s res://tests/run_tests.gd` → 56/56 geçti. → [[Kombo ve Palet]]
(önceki: **Tank melee düşman** — `scripts/enemy.gd`, yürü+menzilde melee, HP 400.)

### (arşiv) Tank melee düşman
2026-09-07 — **Tank melee düşman çalışıyor**. Yeniden kullanılabilir `Enemy` node'u (`scripts/enemy.gd`, preload + `setup`/`tick`, health.gd pattern'i). Gövdeyi oyuncuya doğru yürütür, menzile girince melee vurur. Tank profili: HP 400, hasar 5, hız 45 px/sn, cooldown 1.4 sn. Oyuncu artık gerçekten hasar alıyor; saldırı yalnız menzilde (eski uzaktan-hasar bug'ı yok). Can çubuğu yürüyen tankı takip eder. run_project ile test: yürüdü/vurdu/400 HP'de öldü, hata yok. → [[Düşman Tasarımı]], [[Can ve Hasar Sistemi]]
(önceki: `Health`+`HealthBar` bileşenleri, 100 HP, mermi hasarı 10–30; 4 rün tanıma + renkli mermi.)

## Key Recent Facts
- **YÖN DEĞİŞİKLİĞİ (2026-09-10):** oyun artık **turn-based parti RPG**. Gerçek-zamanlı kombo/dalga motoru **TAMAMEN SİLİNDİ** (`deprecated/` dahil — artık yok). Rün çizimi beceri başına **QTE** olarak kalır. Çekirdek `scripts/rpg/` (`TurnManager`, `Character`/`Skill`/`Enemy`/`Combatant`, `EnemyAI`, `BattleDamage`). Aşağıdaki gerçek-zamanlı satırlar (kombo/dalga/strike/füzyon) **tarihsel — geçersiz**. → [[Turn-Based Savaş ve QTE]]
- **Beceri modeli (2026-09-10):** her karakter 3 büyü = 2 rün-özel + 1 birleşim (ultimate, şarj barı dolunca; QTE'de kaynak rünler peş peşe). Şarj hasar ver+al ile dolar. Durum: yakma DoT (Plazma) + stun (Fırtına). Strike ve füzyon tablosu KALDIRILDI. → [[Turn-Based Savaş ve QTE]]
- **Rün Büyücüsü** — dikey 2D dalga savunması. Alt-orta sabit kareye rün çizilir → soldaki büyücü sağdaki düşmana fırlatır. Rünler zincirlenip kombo yapar. → [[Rün Büyücüsü — Konsept]]
- Fark: girdi = üretim (seçim değil), "ben yaptım" hissi. Reklam = oynanış (dilsiz, 6 sn).
- **Onaylı kararlar:** sabit çizim karesi ([[Ekran Düzeni]]), savaşa 4 rün ([[Loadout Kısıtı]]), sessiz başarısızlık yok ([[Sessiz Başarısızlık Yok]]), zaaf bonus %40 ([[Zaaf Bonustur, Kapı Değil]]).
- **Bilişsel yük 4 kolonu:** loadout, çizerken önizleme, sessiz başarısızlık yok, rün formu kısıtları (2–3 çizgi, köşeli, ayrık silüet). → [[Rün Çizim Mekaniği]]
- **(tarihsel — strike kaldırıldı 2026-09-10)** ~~Düz vuruş (strike) = draw alanına tık → anında taban.~~ Turn-based sistemde strike yok; başarısız QTE zaten fail-soft taban hasar veriyor.
- Tanıma: **$1 recognizer** aday (araştırılacak). Karışma matrisine göre rün ayır.
- **Can/hasar var** (`scripts/health.gd`, `health_bar.gd`): tekrar kullanılır `Health`/`HealthBar`. Kombo hasar çarpanı + juice + dalga henüz yok. → [[Can ve Hasar Sistemi]]
- **Düşman + dalga sistemi var** (`scripts/enemy.gd`, `main.gd`): 3 arketip `ENEMY_TYPES` (tank melee / swarm hızlı-melee / okçu ranged mermi atar). `WAVES` sıralı dalga — temizlenince sonraki spawn, son dalga → `game_won`. Test bölümü: 3 dalga (1t+10s / 3t+2o / 2t+2o+5s). Silüetten zaaf okuma + zafer/yenilgi UI eksik. → [[Düşman Tasarımı]]

## Open Tasks
- Zafer/yenilgi ekranı (şu an sadece `print`); dalga arası nefes/gösterge.
- [[Prototip M0]] yap: 4 rün + düz çizgi, swarm+tank+okçu, ~30 sn. Telefonda, tek elle. (dalga sistemi hazır)
- Test: birine 20 dk oynat → **20. dk'da düşünerek mi refleksle mi çiziyor?** (D7 tekrar riski ölçümü)

## Open Bugs
- _(none yet)_

## Kararı Verilmeyen (tahmin üretme)
- Para kazanma modeli ([[Para Kazanma — Açık]]) — beceri↔ödeme çelişkisi çözülmedi.
- Uzun vadeli çekim/2. oynanış sebebi, ilerleme/meta, geri dönüş kancası, sosyal.
- 50. dalga kutlama ölçeği. Uzun vadeli dönüşüm planı. (Kombo penceresi süresi artık `data/combo_config.json`'da — prototipte ayarlanacak, mimari karar değil.)
