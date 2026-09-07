---
type: design
title: "Can ve Hasar Sistemi"
status: active
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags: [combat, health, damage, greybox]
code_anchors:
  - repo: game
    symbol: Health
    file: scripts/health.gd
  - repo: game
    symbol: HealthBar
    file: scripts/health_bar.gd
  - repo: game
    symbol: _advance_projectiles
    file: scripts/main.gd
---

# Can ve Hasar Sistemi

İlk savaş katmanı. Player + Enemy artık HP taşır, hasar alır, ölür.

## Bileşenler (yeniden kullanılabilir)

- **`Health`** (`scripts/health.gd`) — Node. `max_hp`/`hp` durumu, `take_damage()`, `heal()`, `is_alive()`, `ratio()`. `damaged(amount, hp)` ve `died` sinyalleri yayar. Görsel yok. Bir birime child olarak eklenir.
- **`HealthBar`** (`scripts/health_bar.gd`) — Node2D. Greybox çubuk (koyu bg + dolum ColorRect). `set_ratio(r)` → dolum daralır, yeşil→kırmızı lerp. Fare girdisini engellemez.

> [!note] Neden `class_name` yok
> Bileşenler `preload` ile kullanılıyor (`HealthScript`, `HealthBarScript` main.gd'de). Global `class_name` headless çalıştırmada stale global class cache yüzünden "Could not find type" parse hatası veriyordu. Editör olmadan çalışması için preload.

## Değerler (verified 2026-09-07)

- Player HP: 100 · Enemy HP: 100
- Rün mermi hasarı: line 10, O 15, V 20, X 25, Yıldırım 30 (`RUNE_DAMAGE`)
- **Oyuncu hasar kaynağı yok** (henüz). Düşman auto-attack denendi ama "vurunca ben de yiyorum" bug'ına yol açtı, kaldırıldı. Player bar duruyor, gerçek düşman saldırısı bekliyor.

## Akış

- Mermi düşman merkezine ulaşınca `enemy_health.take_damage(meta.damage)`. Hasar mermide `set_meta("damage", ...)` ile taşınır.
- Düşman ölünce: bar + görsel `queue_free`, uçan mermiler temizlenir (freed node'a nişan → çökme guard'ı `_advance_projectiles` başında).
- Oyuncu ölünce: `game_over = true` → `_process` ve `_unhandled_input` durur.

## Açık / eksik

- **Oyuncu henüz hiç hasar almıyor** — düşmanın gerçek saldırı davranışı tasarlanmalı (menzil, animasyon, sıklık) → [[Düşman Tasarımı]]. Bağlanınca `player_health.take_damage()` + `_on_player_died` zaten hazır.
- Tek düşman (punching bag). Dalga/spawn yok → [[Prototip M0]], [[Düşman Tasarımı]].
- Ölümde restart/game-over ekranı yok, sadece durur.
- Kombo hasar çarpanı yok → [[Kombo ve Palet]].
- Juice yok (hasar flash, sarsıntı, sayı) → [[Juice ve Geri Bildirim]].
