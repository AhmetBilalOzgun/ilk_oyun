---
type: design
title: "Düşman Tasarımı"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - design
  - mechanic
status: approved
domain: mechanic
related:
  - "[[Rün Çizim Mekaniği]]"
  - "[[Zaaf Bonustur, Kapı Değil]]"
code_anchors:
  - repo: game
    symbol: Enemy
    file: scripts/enemy.gd
  - repo: game
    symbol: _spawn_wave
    file: scripts/main.gd
  - repo: game
    symbol: _advance_wave
    file: scripts/main.gd
---

# Düşman Tasarımı

## Kaçınılacak

"Kırmızı düşman ateşe zayıf" tipi tablo = ezber. Şu zinciri geri getirir: düşmanı oku → zaafı hatırla → rünü hatırla → şekli hatırla → çiz. Bilişsel yük için kurulan her şeyi geri alır.

## Kural — zaaf silüetten okunmalı

| Görünen özellik | Gereken cevap |
|---|---|
| Kalabalık + küçük | Geniş alan büyüsü |
| Büyük + zırhlı | Delici |
| Kalkanlı | Kalkan önce kırılır |

## Kural — zaaf bonustur, kapı değildir

Yanlış rün **%40 hasar** verir, sıfır değil. Doğru rün ödüllendirilir, yanlış rün cezalandırılmaz. Akış bozulmaz. → [[Zaaf Bonustur, Kapı Değil]]

## Player Experience Goal

Oyuncu düşmana bakıp refleksle doğru cevabı çizer; hatırlamak değil görmek yeter.

## Uygulanan davranış (verified 2026-09-07)

Yeniden kullanılabilir `Enemy` node'u (`scripts/enemy.gd`), main.gd tarafından `preload` + `setup()` + her frame `tick(delta)` ile sürülür (health.gd pattern'i, `class_name` yok). Görsel/HP yok — Health bileşeni ayrı.

- **Davranış:** gövdeyi hedefe (Player) doğru yatay yürütür; kenar-kenar mesafe `attack_range` altına inince `attack_cooldown` periyoduyla melee vurur, `attacked(damage)` sinyali yayar. Saldırı **yalnız menzilde** (eski uzaktan-hasar bug'ının fix'i).
- **Ranged (okçu):** `is_ranged=true` ise menzilde durur (attack_range büyük, 360 px), yaklaşmaz; cooldown'da `fired(muzzle, damage)` yayar. Hasar melee gibi anında değil — `main._on_enemy_fired` namludan oyuncuya bir mermi doğurur, `_advance_enemy_projectiles` oyuncuya taşır, isabette `player_health.take_damage`.
- Can çubuğu tank yürüdükçe `_place_bar()` ile takip eder.

## Arketipler ve dalgalar (verified 2026-09-07)

`main.gd` `ENEMY_TYPES` sabiti temel istatistikleri ada bağlar; `WAVES` bunlara adla atıfta bulunur. Dalgalar **sırayla** gelir — bir dalga tam temizlenince (`_alive_count()==0`) `_advance_wave` sonrakini spawn eder; son dalga bitince `_on_all_waves_cleared` → zafer (`game_won`).

| Tür | HP | Hız | Hasar | cd | Menzil | Zaaf |
|---|---|---|---|---|---|---|
| tank | 400 | 45 | 5 | 1.4 | melee 24 | Burn |
| swarm | 60 | 120 | 2 | 0.8 | melee | Push |
| archer | 120 | 70 | 4 | 1.6 | ranged 360 | Freeze |

**Test bölümü (WAVES):** Dalga 1 = 1 tank + 10 swarm; Dalga 2 = 3 tank + 2 okçu; Dalga 3 (son) = 2 tank + 2 okçu + 5 swarm. Düşmanlar `SPAWN_X_MIN..MAX` (520–1040) bandına yayılarak spawn olur, sola (oyuncuya) yürür.

## Open Questions

- Dalga sistemi var (sıralı, 3 test dalgası). Zafer/yenilgi `game_won`/`game_over` sadece `print` — UI ekranı yok.
- Silüetten zaaf okuma henüz kodda yok (tank/swarm/okçu görsel ayrımı sadece renk/boyut; rün→zaaf eşlemesi ezber riski).
- Okçu mermisi düz hat, engel/blok yok; swarm sürü davranışı yok (bağımsız yürür).
