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
- **Tank profili (@export defaults + `ENEMY_MAX_HP`):** HP 400, hasar 5, hız 45 px/sn, menzil 24 px, cooldown 1.4 sn → öldürmesi zor (~13-40 rün), tehlikesi yavaş birikir. Stat'lar override edilebilir → başka arketipler (swarm: düşük HP, hızlı) aynı node'dan.
- Can çubuğu tank yürüdükçe `_place_bar()` ile takip eder.

## Open Questions

- Prototip 2 düşman tipiyle başlıyor: swarm (kalabalık+küçük) + tank (büyük+zırhlı). Tank var; swarm eksik.
- Spawn/dalga sistemi yok — tek tank, punching-bag değil ama tek. → [[Prototip M0]]
- Silüetten zaaf okuma henüz kodda yok (tank/swarm görsel ayrımı, rün→zaaf eşlemesi).
