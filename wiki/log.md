---
type: meta
title: "Operation Log"
updated: 2026-09-06
---

# Operation Log

Append-only. **New entries go at the TOP.** Format:

## [2026-09-07] refactor | Menü Kenney assetiyle yeniden tasarlandı
- Files changed: `scenes/main_menu.tscn`, `assets/ui/{panel_cream,banner_red,btn_normal,btn_pressed}.png` (+.import). Eski düz `button_*`/`panel_wood` silindi.
- İlk sürüm asseti neredeyse kullanmıyordu (3 düz tile). Yeniden: süslü krem panel (Large/Thick tile #7 NinePatchRect), kırmızı kurdele banner başlık (tile #43/44/45 PIL ile 96x32 şeride birleştirilip 3-slice NinePatchRect, patch_left/right=32), kahve butonlar (normal #5 / pressed #1 StyleBoxTexture). Örnek Sample.png estetiğine uygun.
- Banner + panel node isimleri değişti ama script (`main_menu.gd`) node yolları güncellendi; sinyaller `Panel/Buttons/*`. Doğrulama: headless load 0 warning, viewport screenshot ile menü + ayar paneli onaylandı.

## [2026-09-07] feature | Ana menü + Kenney buton assetleri
- Files changed: `scenes/main_menu.tscn` (yeni), `scripts/main_menu.gd` (yeni), `assets/ui/{button_normal,button_pressed,panel_wood}.png` (+.import, Kenney UI Pack Pixel Adventure'dan kopya), `project.godot` (main_scene → main_menu.tscn; `default_texture_filter=0` nearest).
- İlk menü ekranı: başlık "RÜN BÜYÜCÜSÜ" + 3 buton (OYNA → main.tscn, AYARLAR → "yakında" paneli aç/kapa, ÇIKIŞ → quit). Butonlar Kenney "Large tiles/Thick outline" 9-patch tile'lar (tile_0000 ahşap+krem = normal, tile_0001 kahve = pressed) StyleBoxTexture ile, texture_margin=6.
- Pixel-art keskin dursun diye global canvas texture filter Nearest yapıldı (oyun şu an salt ColorRect, güvenli). Not: kopyalanan `panel_blue` aslında kahve render etti → `panel_wood` olarak yeniden adlandırıldı.
- Doğrulama: headless load temiz (0 warning/error), viewport screenshot ile menü + ayar paneli görsel onaylandı.


```
## [YYYY-MM-DD] <type> | <short title>
- Files changed: list them
- What changed and why (1–3 bullets)
- Any decisions made (link [[Decision Name]] if significant)
```

Types: `fix`, `feature`, `refactor`, `disable`, `config`, `document`

---

## [2026-09-07] feature | Wave sistemi + okçu (ranged) düşman
- Files changed: `scripts/main.gd`, `scripts/enemy.gd`, `wiki/design/enemy-design.md`
- `main.gd`: düz `ENEMY_PROFILES` → `ENEMY_TYPES` (tank/swarm/archer arketipleri) + `WAVES` (sıralı dalgalar). `_advance_wave`/`_spawn_wave`: dalga temizlenince (`_alive_count()==0`) sonraki spawn; son dalga → `_on_all_waves_cleared` (`game_won`). Sahne `Enemy` node'u artık kullanılmıyor, `_ready`'de free — hepsi koddan spawn. Düşmanlar SPAWN_X bandına yayılır.
- Okçu: `enemy.gd`'ye `is_ranged` + `fired(muzzle,damage)` sinyali + `_muzzle()`. Menzilde durur, mermi atar; `main._on_enemy_fired`/`_advance_enemy_projectiles` mermiyi oyuncuya taşır, isabette hasar.
- Test bölümü: Dalga1 = 1 tank+10 swarm, Dalga2 = 3 tank+2 okçu, Dalga3 = 2 tank+2 okçu+5 swarm.
- Doğrulama: MCP run_project → "Dalga 1/3 başladı — 11 düşman", parse temiz (yalnız combo_resolver.gd eski uyarıları).

## [2026-09-07] refactor | Snap sistemi TAMAMEN kaldırıldı
- Files changed: `scripts/recognizer_adapter.gd`, `scripts/rune_trail.gd`, `scripts/main.gd`, `scripts/core/rune_db.gd`, `data/combo_config.json`
- Kullanıcı: snap hissi kötü → geri al. Çapa grid + snap (setup_anchors, snap_stroke, _snap_all/_nearest_anchor, anchor_cols/rows, draw_anchors config) ve `RuneTrail` Catmull-Rom smooth/glow SÖKÜLDÜ.
- `classify_shape` yine ham izde; `RuneTrail` yine ham `draw_polyline`; `main` trail'e ham strokes/current verir. `grep snap|anchor|catmull` = 0.
- KORUNAN: tık=düz vuruş + bekleme yok, strike standalone, tek-stroke self-cross X. Doğrulama: MCP run, parse temiz.
- Sonuç: aşağıdaki iki snap feature girişi (aynı gün) etkisiz — geçmiş için bırakıldı.

## [2026-09-07] feature | Snapped iz ekranda görünür (smooth) — çapa grid
- Files changed: `scripts/rune_trail.gd`, `scripts/main.gd`, `scripts/recognizer_adapter.gd`
- Düzeltme (kullanıcı): görünen iz **snapped** olmalı, ham değil. `main._process` her frame `recognizer.snap_stroke` ile snapped diziyi üretip trail'e verir. `RuneTrail` çapa dizisini **Catmull-Rom** smooth eğriye çevirir + halo/çekirdek glow → snapped ama akıcı/parlayan; uçta çapa işaretçisi (manyetik his). `recognizer.snap_stroke` public eklendi.

## [2026-09-07] feature | Gizli çapa grid — snap'li ayrık tanıma
- Files changed: `scripts/recognizer_adapter.gd`, `scripts/core/rune_db.gd`, `scripts/main.gd`, `data/combo_config.json`, `wiki/design/rune-drawing-mechanic.md`
- Çizim karesine gizli sabit grid (`draw_anchors.cols/rows`, vars. 5×5). TANIMA ham izi en yakın çapaya snap'leyip ardışık tekrarları tekilleştirerek **ayrık anchor dizisi** üstünde yapılır → kanonik şekil, daha net rün.
- `RecognizerAdapter`: `setup_anchors(rect,cols,rows)` + `_snap_all/_snap_stroke/_nearest_anchor`; `classify_shape` snapped dizide çalışır. Grid kurulmazsa ham noktalar (headless güvenli).
- `RuneDB`: `anchor_cols/anchor_rows` parse. `main._ready`: `setup_anchors(canvas_rect, ...)`.
- Doğrulama: MCP Godot 4.7.2 sahne run — tüm rünler + füzyonlar tanındı, strike'lar 10 sabit, parse temiz.

## [2026-09-07] fix | Strike standalone — peş peşe tık hasarı büyümesin
- Files changed: `scripts/core/combo_state_machine.gd`, `tests/test_state_machine.gd`
- Bug: strike komboya giriyordu → peş peşe tık depth'i artırıp hasarı ×1.6/rün büyütüyordu; ayrıca strike pencere açıp time-scale yavaşlatınca sonraki çizim 2. kombo vuruşu oluyordu ("önce düz vuruş, sonra çizim" hissi).
- Fix: `on_finger_up`'ta STRIKE artık **standalone** — komboya eklenmez, pencere açmaz/uzatmaz, depth artmaz. `recognized = ... and rune_id != STRIKE`, yani hem tık (null) hem çizilen düz çizgi (`line`->`strike`) sabit taban hasar verir. Süren kombo bozulmaz (neutral).
- Test: `tanınmayan-strike` bölümü güncellendi — peş peşe strike aynı hasar, depth 0.

## [2026-09-07] feature | Tık = düz vuruş + commit beklemesi kaldırıldı
- Files changed: `scripts/main.gd`, `scripts/recognizer_adapter.gd`
- `COMMIT_DELAY` (0.22s) / `commit_left` zamanlayıcı silindi. Parmak kalkınca `_unhandled_input` anında `_commit()` çağırıyor — bekleme yok. Hareketsiz/kısa stroke → tanıma `none` → `null` → strike, yani draw alanına **tıkla = düz vuruş**.
- Bekleme kalkınca iki-stroke X birleştirme imkânsız; kaybetmemek için `recognizer_adapter.classify_shape`'e tek-stroke kendini-kesme (`_self_crosses`) → `X` eklendi. Sıra: multi-cross→X, O, self-cross→X, köşe sayısı→line/V/lightning.
- Çekirdek (`scripts/core/`) ve testler değişmedi; SM `on_finger_down/up` aynı.

## [2026-09-07] config | İlk Android APK build (prebuilt debug)

- Files changed: `project.godot`, `export_presets.cfg`, `.gitignore`
- **Android toolchain kuruldu** (bu makinede sıfırdı): OpenJDK 17 (`brew openjdk@17`), Android cmdline-tools + platform-tools + build-tools;35.0.0 + platforms;android-35 (`/opt/homebrew/share/android-commandlinetools`), Godot 4.7.2 Android export şablonları, debug keystore (`~/.android/debug.keystore`, alias `androiddebugkey`). Godot editor ayarlarına SDK/Java/keystore path yazıldı.
- **project.godot:** `rendering/textures/vram_compression/import_etc2_astc=true` eklendi — Android export zorunlu kılıyor.
- **export_presets.cfg:** `version/name="1.0"`, `package/unique_name="com.example.wizardgame"`, `package/name="Wizard Game"` dolduruldu.
- Çıktı: `build/wizard_game.apk` (27MB, arm64-v8a, debug-signed). Prebuilt template yolu (`use_gradle_build=false`). `build/` gitignore'a eklendi.
- Komut: `Godot --headless --path . --export-debug "Android" build/wizard_game.apk` (JAVA_HOME set).

---

## [2026-09-07] feature | Çizim izi (canlı trail juice)

- Files changed: `scripts/rune_trail.gd` (yeni), `scripts/main.gd`
- **Canlı iz:** parmak çizerken stroke'ların arkasında parlak mavi hat + uç noktasında nokta. "Ben yaptım" hissini güçlendirir, [[Rün Çizim Mekaniği]] "çizerken önizleme" kolonunu karşılar.
- `RuneTrail` ayrı `Node2D`, ana sahnenin EN SON child'ı olarak eklenir → `_draw` DrawCanvas ColorRect'inin üstüne çizer (parent Node2D `_draw` child'ların arkasında kalırdı). main her frame `set_live()` iter.
- **Vazgeçilen:** rün hayaleti (commit'te çizilen şeklin ekranda solması) — tasarımcı kararıyla iptal, kod eklenmedi/geri alındı. İlgili: [[Kombo ve Palet]]

---

## [2026-09-07] feature | Ekranda Overdrive şarj tuşu

- Files changed: `scripts/charge_button.gd` (yeni), `scripts/main.gd`
- Çizim karesinin **hemen sağında** dokunmatik şarj tuşu. Dolum **alttan yukarı** dolar (ne kadar kaldığı görünür), yüzde yazar; dolunca altın renge döner, kenarlık nabız gibi parlar, "BAS!" yazar.
- Dokunuş YALNIZ halka doluyken dinlenir (spec kuralı) → `triggered` sinyali → `_trigger_overdrive()`. Sağ tık masaüstü kolaylığı olarak korundu; ikisi de aynı helper'dan geçer.
- `ChargeMeter.ratio()/is_full()` canlı okunur; `Control` + `_draw`, konumu `canvas.get_global_rect()`'ten hesaplanır (tscn'e dokunulmadı). İlgili: [[Kombo ve Palet]]

---

## [2026-09-07] feature | Çok düşmanlı dalga (kombo/zincir test için)

- Files changed: `scripts/main.gd`
- Tek düşman → **5 düşmanlı karışık dalga** (`ENEMY_PROFILES`): 2 tank (HP 400) + 1 orta + 2 swarm (HP 150, hızlı). İlk profil sahne `Enemy` node'unu kullanır, kalanları koddan spawn.
- Her düşmanın **ayrı zaafı** (Burn/Freeze/Shatter/Push) → zaaf %40 kuralı ve renk seçimi canlı test edilebilir. Mermiler **en yakın canlı** düşmanı hedefler (`_nearest_enemy`), isabette o düşmanın zaafı uygulanır.
- Enemy AI/Health/HealthBar giriş başına ayrı; ölüm sinyali `_on_enemy_died.bind(entry)`. Her ölüm zinciri artırır → çok düşmanla zincir sayacı gerçekten test edilir.
- Test: 56/56 geçti, oyun 150 kare headless temiz. İlgili: [[Düşman Tasarımı]], [[Kombo ve Palet]]

---

## [2026-09-07] feature | Kombo sistemi çekirdeği + motor entegrasyonu

- Files changed: `data/combo_config.json` (yeni), `scripts/core/{rune_db,combo_resolver,resolved_spell,combo_state_machine,time_scale_controller,charge_meter,chain_tracker,damage_rules,rune_recognizer}.gd` (yeni), `scripts/{recognizer_adapter,debug_overlay}.gd` (yeni), `tests/{run_tests,test_resolver,test_state_machine,test_meters}.gd` (yeni), `scripts/main.gd` (yeniden yazıldı)
- **İki katman:** çekirdek saf `RefCounted` (motordan bağımsız, `unscaled_dt` alır, headless test edilebilir); motor tarafı adaptör (`main.gd`) girdi + `Time.get_ticks_usec` ölçeklenmemiş dt + `Engine.time_scale` uygular.
- **Kritik kısıt çözüldü:** kombo/pencere/casting/overdrive süreleri duvar saatinden ölçülür → `Engine.time_scale`'den bağımsız. Dünya yavaşlarken pencere yavaşlamaz (çift avantaj yok). Test bunu kanıtlıyor (en önemli test).
- **ComboResolver saf/deterministik:** taşıyıcı=ilk rün, etkiler union+füzyon tablosu, hasar=taban×1.6^(ek rün). Strike = tanınmayan çizim tabanı (null→strike), etkisiz ama komboyu taşır. Zaaf = %40 (sıfır değil, `DamageRules`).
- **Overdrive:** aynı ComboResolver, biriken rünler tek çıktı + hasar çarpanı. Şarj isabetten dolar, taşma birikmez.
- **Zincir & kombo bağımsız** iki sayaç. Debug overlay (F1) canlı okur.
- Tuning tek dosyada: `data/combo_config.json` (rün seti, füzyon, timeScale/pencere merdiveni, şarj, overdrive).
- Testler: `godot --headless -s res://tests/run_tests.gd` → 56 geçti, 0 kaldı. Oyun 90+ kare headless, script hatası yok.
- İlgili: [[Kombo ve Palet]], [[Zaaf Bonustur, Kapı Değil]], [[Rün Çizim Mekaniği]]

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
