---
type: meta
title: "Operation Log"
updated: 2026-09-06
---

# Operation Log

Append-only. **New entries go at the TOP.** Format:

```
## [YYYY-MM-DD] <type> | <short title>
- Files changed: list them
- What changed and why (1–3 bullets)
- Any decisions made (link [[Decision Name]] if significant)
```

Types: `fix`, `feature`, `refactor`, `disable`, `config`, `document`

---

## [2026-09-07] feature | Tank melee düşman (yürü + menzilde saldır)
- Files changed: `scripts/enemy.gd` (yeni), `scripts/main.gd`
- Yeniden kullanılabilir `Enemy` davranış node'u (`preload`, `class_name` yok — health.gd pattern'i). `setup(body, target, target_health, self_health)` + `tick(delta)`. Gövdeyi hedefe doğru yatay yürütür; kenar-kenar mesafe `attack_range` altına inince `attack_cooldown` ile melee vurur.
- Tank profili: HP 400 (`ENEMY_MAX_HP`, ~13-40 rün vuruşu), hasar 5, hız 45 px/sn, menzil 24 px, cooldown 1.4 sn — bol can, düşük hasar/hız.
- Önceki auto-attack bug'ı çözüldü: saldırı artık yalnız menzilde tetikleniyor (uzaktan hasar yok). Oyuncu artık gerçekten hasar alıyor → `player_health.take_damage` + `_on_player_died` bağlandı.
- `_place_bar()` helper çıkarıldı; tank yürüdükçe can çubuğu her frame gövdeyi takip ediyor. Test: run_project ile tank yürüdü, vurdu, 400 HP'de öldü, hata yok. → [[Düşman Tasarımı]], [[Can ve Hasar Sistemi]]

## [2026-09-07] fix | Oyuncu kendiliğinden hasar alıyordu (düşman auto-attack kaldırıldı)
- Files changed: `scripts/main.gd`
- Bug: düşmana vurunca oyuncu da hasar yiyor görünüyordu. Gerçek sebep: `_enemy_attack` her 2sn oyuncuya pasif 8 hasar veriyordu (bir önceki commit'te eklenmişti), rün çizimiyle çakışınca "vurunca ben de yiyorum" algısı.
- `_enemy_attack`, `ENEMY_ATTACK_DAMAGE/INTERVAL`, `enemy_attack_left` kaldırıldı. `player_health` + bar duruyor — gerçek düşman saldırısı tasarlanınca `take_damage()` tekrar bağlanacak. → [[Can ve Hasar Sistemi]]

## [2026-09-07] feature | Can + hasar sistemi (health bars, ölüm)
- Files changed: `scripts/health.gd` (yeni), `scripts/health_bar.gd` (yeni), `scripts/main.gd`
- Yeniden kullanılabilir bileşenler: `Health` (HP durumu + `damaged`/`died` sinyalleri), `HealthBar` (greybox yeşil→kırmızı dolum çubuğu, birimin üstünde). Global `class_name` yerine `preload` — headless çalıştırmada global class cache stale olduğu için parse hatası veriyordu.
- Player + Enemy'ye 100 HP. Mermi isabeti düşmana rüne göre hasar (line 10, O 15, V 20, X 25, Yıldırım 30). Düşman her 2sn oyuncuya 8 hasar (`_enemy_attack`) → oyuncu HP'si de gerçek.
- Ölüm: düşman ölünce görsel+bar free + uçan mermiler temizlenir (freed node'a nişan alıp çökme guard'ı); oyuncu ölünce `game_over` → girdi + process durur.
- Godot 4.7.2'de çalıştırıldı, parse temiz, oyuncu HP düştüğü + bar güncellendiği doğrulandı. → [[Can ve Hasar Sistemi]]

## [2026-09-07] fix | Rün algılama gecikmesi azaltıldı (erken commit)
- Files changed: `scripts/main.gd`
- `COMMIT_DELAY` 0.35 → 0.22s.
- Erken commit: tek stroke ve düz çizgi değilse (O/V/Yıldırım) X olamaz → anında tetiklenir, beklemez. Sadece düz çizgi (X'in ilk yarısı olabilir) ve X `COMMIT_DELAY` bekler.
- Bol test edildi, 5 rün de doğru + hızlı. Hasar/can hâlâ yok.

## [2026-09-07] feature | 4 rün tanıma: X / O / Yıldırım / V + renkli mermi
- Files changed: `scripts/main.gd`, `scenes/main.tscn`
- Stroke sınıflandırma eklendi. Çok-stroke tampon + `COMMIT_DELAY=0.35s` (X iki çizgi olduğu için). Kalem kalkınca commit sayacı, süre bitince `_classify`.
- Kurallar: kesişen ≥2 stroke → **X**; kapalı (baş-son/yol < 0.30) → **O**; köşe sayısı (dönüş >55°) 0 → düz çizgi (temel), 1 → **V**, ≥2 → **Yıldırım**. Resample 24 nokta, min uzunluk 60px.
- Her rün farklı renk mermi: düz=beyaz, X=kırmızı, O=camgöbeği, Yıldırım=sarı, V=yeşil. Hareket/hasar aynı — şimdilik sadece renkle ayrım (kullanıcı isteği).
- Rün slotları rünlere hizalandı ve isimlendi (RuneSlotX/O/Lightning/V), renkleri mermiyle eşleşiyor.
- Geometry2D.segment_intersects_segment ile kesişim. Hasar/can hâlâ yok.

## [2026-09-07] feature | Düz vuruş: çizgi algılama + mermi logic
- Files changed: `scripts/main.gd` (yeni), `scenes/main.tscn`
- İlk oyun özelliği. DrawCanvas içinde herhangi yönde düz çizgi çizilince "düz vuruş" tetiklenir → Player'dan Enemy'ye ColorRect mermi gider, isabette yok olur. → [[Düz Çizgi]]
- Çizgi algılama: stroke noktaları toplanır, ilk-son nokta doğrusuna max dik sapma / uzunluk ≤ 0.18 ve uzunluk ≥ 60px → düz. Aksi halde vuruş yok (sessiz değil, print'liyor → [[Sessiz Başarısızlık Yok]]).
- Hasar/can YOK — sadece logic. İsabet `print` ile görünüyor. Test: 3/3 çizgi→mermi→isabet çalıştı.
- tscn: root'a `main.gd`, BattleArea/DrawArea/DrawCanvas'a `mouse_filter=2` (girişi yutmasın, `_unhandled_input`'a geçsin).

## [2026-09-07] refactor | Demo düzeni: büyük çizim alanı + rün slotları + boyut ölçeği
- Files changed: `scenes/main.tscn`
- Çizim/etkileşim alanı büyütüldü: savaş üst 0→1000, çizim alanı 1000→1920 (~48%).
- Player küçültüldü (90×180 — normal büyücü); Enemy tank olarak büyük kaldı (150×300). Boyut = tehdit ölçeği.
- Çizim alanına: sol büyük DrawCanvas (600×600) + sağda 4 RuneSlot (130×130). Slot renkleri: beyaz/sarı/yeşil/mor (rün formu yok, sadece renk placeholder).
- Godot 4.7.2'de temiz çalıştı, hata yok.

## [2026-09-07] feature | Demo sahnesi (rectangle greybox) kuruldu
- Files changed: `scenes/main.tscn` (yeni), `project.godot`
- İlk oynanabilir greybox: assetsiz, sadece ColorRect'ler. Dikey 1080x1920.
- Düzen: üst 2/3 (0→1280) savaş alanı — solda Player (mavi), sağda Enemy (kırmızı), zemin çizgisi y=1280. Alt 1/3 (1280→1920) rün çizim alanı ([[Ekran Düzeni]]).
- `run/main_scene="res://scenes/main.tscn"` set. Godot 4.7.2'de temiz çalıştı, hata yok.
- Script yok — sonraki sprint: düşman scripti + çizim girişi.

## [2026-09-07] config | godot-mcp (editor control) eklendi
- Files changed: `.mcp.json`, `wiki/decisions/engine-godot.md`
- `godot` MCP (Coding-Solo/godot-mcp, npx @coding-solo/godot-mcp) projeye eklendi — Godot editörünü kontrol eder (sahne çalıştır, hata oku).
- GODOT_PATH = `/Users/ahmetbilalozgun/Downloads/Godot.app/Contents/MacOS/Godot` (Godot 4.7.2 stable). Restart gerektirir.
- NOT: Godot.app Downloads'ta — /Applications'a taşınırsa GODOT_PATH kırılır, güncellenmeli.

## [2026-09-07] config | Engine kararı Godot + godot-docs MCP eklendi
- Files changed: `.mcp.json`, `wiki/decisions/engine-godot.md`, `wiki/decisions/_index.md`, `wiki/overview.md`
- Oyun motoru Godot olarak karara bağlandı ([[Engine — Godot]]). Dil: GDScript.
- `godot-docs` MCP (npx @nuskey8/godot-docs-mcp) projeye eklendi — restart gerektirir.

## [2026-09-07] document | Rün Büyücüsü fikri onaylandı, tasarım notları işlendi
- Files changed: `wiki/overview.md`, `wiki/index.md`, `wiki/hot.md`, `wiki/design/**` (6 yeni sayfa + _index), `wiki/decisions/**` (4 yeni sayfa + _index), `wiki/deliverables/**` (Prototip M0 + _index), `wiki/entities/one-dollar-recognizer.md`
- Beyin fırtınası sonucu karara bağlanan oyun fikri (dikey 2D rün-çizme dalga savunması) tam olarak wiki'ye yazıldı: konsept, ekran düzeni, çizim mekaniği, kombo/palet, düşman tasarımı, juice, oturum yapısı.
- Onaylanan kararlar sayfalandı: [[Ekran Düzeni]], [[Loadout Kısıtı]], [[Sessiz Başarısızlık Yok]], [[Zaaf Bonustur, Kapı Değil]]. Açık konular ayrı işaretlendi (para kazanma, kombo penceresi, meta/retention → tahmin üretilmedi).
- Sonraki adım: [[Prototip M0]] (telefonda 4 rün + tek dalga + 2 düşman, 20 dk oyun testi).

## [2026-09-06] document | Wiki memory system scaffolded
- Files changed: `CLAUDE.md`, `wiki/**`, `_templates/**`, `.raw/**`
- Ported the LLM-wiki agent memory system (blank start): governing `CLAUDE.md`, index/hot/log/overview, domain `_index` pages, note templates.
- No game content yet — structure only.
