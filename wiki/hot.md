---
type: meta
title: "Hot Cache"
updated: 2026-09-07
verified: 2026-09-07  # can/hasar sistemi eklendi
---

# Recent Context

> [!warning] Staleness
> Any product/build-state claim below older than 14 days is a **hypothesis, not a fact** (see Staleness Contract in `CLAUDE.md`). Verify against code, graph, or the running build before acting, then bump `verified:`.

## Last Updated
2026-09-07 — **Can + hasar sistemi çalışıyor**. Yeniden kullanılabilir `Health` + `HealthBar` bileşenleri (preload, `class_name` değil). Player/Enemy 100 HP, üstlerinde greybox can çubuğu (yeşil→kırmızı). Mermi düşmana rüne göre hasar (10–30). **Oyuncu henüz hasar almıyor** — düşman auto-attack denendi, bug yaptı (vurunca oyuncu da yiyor), kaldırıldı; gerçek düşman saldırısı bekliyor. Ölüm: düşman free / oyuncu game_over hazır. Godot 4.7.2 doğrulandı. → [[Can ve Hasar Sistemi]]
(önceki: 4 rün tanıma + renkli mermi, `scripts/main.gd`.)

## Key Recent Facts
- **Rün Büyücüsü** — dikey 2D dalga savunması. Alt-orta sabit kareye rün çizilir → soldaki büyücü sağdaki düşmana fırlatır. Rünler zincirlenip kombo yapar. → [[Rün Büyücüsü — Konsept]]
- Fark: girdi = üretim (seçim değil), "ben yaptım" hissi. Reklam = oynanış (dilsiz, 6 sn).
- **Onaylı kararlar:** sabit çizim karesi ([[Ekran Düzeni]]), savaşa 4 rün ([[Loadout Kısıtı]]), sessiz başarısızlık yok ([[Sessiz Başarısızlık Yok]]), zaaf bonus %40 ([[Zaaf Bonustur, Kapı Değil]]).
- **Bilişsel yük 4 kolonu:** loadout, çizerken önizleme, sessiz başarısızlık yok, rün formu kısıtları (2–3 çizgi, köşeli, ayrık silüet). → [[Rün Çizim Mekaniği]]
- **Düz çizgi** = temel saldırı + başarısızlık tabanı + komboyu taşır.
- Tanıma: **$1 recognizer** aday (araştırılacak). Karışma matrisine göre rün ayır.
- **Can/hasar var** (`scripts/health.gd`, `health_bar.gd`): tekrar kullanılır `Health`/`HealthBar`. Kombo hasar çarpanı + juice + dalga henüz yok. → [[Can ve Hasar Sistemi]]

## Open Tasks
- [[Prototip M0]] yap: 4 rün + düz çizgi, tek dalga, swarm+tank, ~30 sn. Telefonda, tek elle.
- Test: birine 20 dk oynat → **20. dk'da düşünerek mi refleksle mi çiziyor?** (D7 tekrar riski ölçümü)

## Open Bugs
- _(none yet)_

## Kararı Verilmeyen (tahmin üretme)
- Para kazanma modeli ([[Para Kazanma — Açık]]) — beceri↔ödeme çelişkisi çözülmedi.
- Uzun vadeli çekim/2. oynanış sebebi, ilerleme/meta, geri dönüş kancası, sosyal.
- Kombo penceresi süresi. 50. dalga kutlama ölçeği. Uzun vadeli dönüşüm planı.
