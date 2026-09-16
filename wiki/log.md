---
type: meta
title: "Operation Log"
updated: 2026-09-16
---

# Operation Log

Append-only. **New entries go at the TOP.** Format:

## [2026-09-16] feature | Tatlış açık hava assetleri, sekiz form ve okunur ritim
- Files changed: `assets/worlds/*.png`, `assets/wizard/forms/*`, `assets/enemies/*_clean.png`, üç enemy `*_frames.tres`; `scripts/ui/game_look.gd`, `scripts/{home,level_select,characters,battle}.gd`, `scripts/rpg/{rhythm_minigame,turn_manager,damage_breakdown}.gd`, `scripts/rpg/run/{run_content,run_loadout}.gd`, `scripts/meta/mastery_track.gd`; `tests/{run_tests,test_run_manager,test_visual_revision,visual_review}.gd`, `tests/visual_review.tscn`; `export_presets.cfg`, `docs/art/revision-prompts.md`, ilgili wiki sayfaları; `build/wizard_game.apk` ve `output/visual-revision/` üretilmiş çıktılar.
- Kullanıcı revizyonu: normal alev büyücüsünün mevcut tatlış animasyonu korundu; 7 görsel varyant, 5 gündüz/açık hava köprü mekanı, krem/koyu yazılı ana menü-bölüm seçimi-HUD-ekipman ekranı. Eski düşman atlaslarındaki delik şeffaflık temizlendi; orijinal kaynaklar korundu. Görseller built-in imagegen ile üretildi, prompt seti kaydedildi.
- Kayan ritim şeridi kaldırıldı: büyük soluktan belirgine geçen aktif ok/TAP, dolan halka ve ŞİMDİ ipucu; küçük sonraki-hareket kuyruğu. Girdi daima büyük işarete uygulanır. Kör eden plazma düşman saldırısını %35 ihtimalle tamamen ıskalatır; oyuncunun fail-soft taban hasarı korunur. Mevcut arketip ailesi dönüşümde plazma karşılığına taşınır; eski mastery kayıtları uyumludur. → [[Tatlış Büyücüler ve Açık Hava Görsel Dili]]
- Doğrulama: **2037 geçti, 0 başarısız** (seed'li 1000 saldırı örneklemi dahil). Metal renderer ile dört ekran, sekiz form, beş savaş mekanı ve üç ritim durumu incelendi; erken/yanlış/geç jest + çakışan zaman penceresi assertion'ları geçti; son renderer logu `VISUAL_REVIEW_OK`, hata yok. Önceden var olan headless ortam CA sertifikası ve test çıkışı kaynak uyarıları sürüyor. Döngü tween'leri hedef node'a bağlanarak geçişteki sonsuz-loop hatası düzeltildi.
- Android debug APK export/sign/verify başarılı; test/rapor/wiki/QA çıktıları export dışına alındı. Telefona kurulum ve gerçek parmakla timing denemesi yapılmadı. Kod grafiği yeni yapıyla yeniden indekslendi.

## [2026-09-15] config | Android cihaza APK export + install
- Files changed: `build/wizard_game.apk` (yeniden export), `wiki/log.md`.
- Godot 4.7.2 (`~/Downloads/Godot.app`) ile headless `--export-debug "Android"` çalıştırılıp güncel koddan yeni imzalı APK üretildi (~40 MB, Mastery Track + ritim değişiklikleri dahil).
- MacDroid adb çöktü (exit 133) → SDK adb kullanıldı: `/opt/homebrew/share/android-commandlinetools/platform-tools/adb`. Xiaomi 23117RA68G cihaza `install -r` başarılı, monkey ile başlatıldı.
- Kod değişmedi; grafik yeniden indekslenmedi.

## [2026-09-15] document | Kârlılık ve ticari fizibilite raporu
- Files changed: `reports/karlilik-analizi-2026-09-15.md`, `output/pdf/run-buyucusu-karlilik-raporu-2026-09-15.pdf`, `wiki/questions/profitability-analysis-2026-09-15.md`, `wiki/questions/_index.md`, `wiki/index.md`, `wiki/log.md`.
- Kullanıcı isteğiyle tasarım belgeleri, kritik kod akışları ve dış pazar/platform kaynaklarından ayrıntılı kârlılık raporu hazırlandı. Gelir senaryoları, emek dahil maliyet, başa baş, nakit stresi ve ölçüm planı içerir.
- Mevcut test çalıştırıcısı yeniden çalıştırıldı: 253 kontrol geçti, 0 başarısız; ortam sertifika hatası ve çıkış kaynak uyarıları raporda ayrıca belirtildi. Gerçek cihaz/oyuncu ve ödeme verisiyle doğrulama yapılmadığı açıklandı.
- Rapor önerileri yeni ürün kararı veya onaylı bütçe değildir. Oyun kodu değiştirilmedi; oyun yapısı değişmediği için kod grafiği yeniden indekslenmedi. → [[Kârlılık Analizi - 2026-09-15]]

## [2026-09-15] feature | Değişim planı kalan 3 parça: mastery claim + StS node map + endless mode
- Files changed: `scripts/meta/meta_progress.gd`, `scripts/home.gd`, `scripts/battle.gd`, `scripts/rpg/run/run_node.gd`, `stage_def.gd`, `run_manager.gd`, `run_content.gd`, `run_state.gd`; yeni `scripts/rpg/run/run_map.gd`; testler `test_meta_progress.gd`, `test_run_manager.gd`, yeni `tests/test_run_map.gd` + `run_tests.gd`
- **Neden:** wiki'de "ertelendi" işaretli üç parça (kullanıcı istedi). Plan onaylı: `~/.claude/plans/starry-roaming-octopus.md`. → [[Makro Oyun — Yol Haritası]] [[Mastery / Battle-Pass]]
- **(1) Mastery CLAIM butonu:** `add_mastery` artık ödülü SESSİZCE uygulamaz (sadece XP + save). Yeni `claimable_count()` + `claim_next()` (tek tier uygular, dict döner). `home.gd` nabızlı **"🎁 TOPLA (n)"** + ödül popup (aç→topla dopamini). `battle.gd` zaferde "ödül hazır" toast'u. Otomatik-açılış kaldırıldı.
- **(2) StS node map (dallanmalı ilerleme):** `RunNode`'a `next:Array[int]`/`col`/`row` + HEAL/TREASURE türleri. Yeni `RunMap` (sütun DAG kabı + `link_combat`/`link_room`/`extend`). `RunManager` GRAF gezer: 0 haleften→bitir/uzat, 1→otomatik (lineer testler korunur), >1→**AWAITING_ROUTE** + `route_requested` + `choose(i)`. `RunContent.campaign_map(i,rng)` giriş→dallanan orta sütun(lar)→boss→reward (tutorial küçük). `battle.gd` **harita ekranı** (bottom→top sütunlar, Line2D bağlantılar, oda ikon/renk, erişilebilir=parıltı). `StageDef.linear` korundu (chain kenarları) → mevcut testler byte-uyumlu.
- **(3) Gerçek endless mode + adaptive override:** home **"♾ ENDLESS"** girişi (`Meta.endless_run`). `RunContent.endless_map` + `RunMap.extender` (bitince RunManager `extend` çağırır, boss/reward yok). `RunState.endless`/`depth`. Ritim OVERRIDE: `battle._on_input_requested` endless'ta `maxf(adaptive, 1+depth·ENDLESS_RHYTHM_RAMP)` → derinlikle MONOTON hızlanır (adaptive yavaşlatma tabanı ezemez). Düğüm başı altın + ölümde BANKA (fail-soft), `Meta.endless_best_depth` (kalıcı).
- Yeni `class_name RunMap` için global cache `--editor --quit` ile yenilendi. Test **253 geçti** (+24: claim/route/map/endless); home+battle headless smoke temiz. Harita UI + endless ritim + claim popup telefonda elle doğrulanmalı.

## [2026-09-15] feature | Arketip görsel kimlik — CHOICE rozeti + sprite tint
- Files changed: `scripts/rpg/archetype.gd`, `scripts/rpg/run/run_content.gd`, `scripts/battle.gd`
- **Neden:** kullanıcı — arketip kartları daha belirgin olsun (üstte kutu); her arketip karakteri + animasyonları biraz değiştirsin.
- **(1) CHOICE rozeti:** arketip seçeneği artık VBox içinde — üstte "◈ ARCHETYPE ◈" `PanelContainer` (StyleBoxFlat, arketip aksan renginde) + altta kart. `_archetype_badge(accent)`. Diğer kart türleri değişmedi.
- **(2) Sprite tint:** `Archetype.tint` (Alev=kızıl-turuncu, İnfaz=altın-sarı, Patlama=kor-kırmızı). `battle._party_tint(c)` commit edilen arketibin rengini verir; `_process` büyücü modulate'ini boyar — rest = tint, cast = `parlak × tint`. Tüm animasyonlara (idle/cast/hurt) biner → karakter build'e göre görsel değişir. Yoksa WHITE.
- Test **223 geçti**; battle smoke temiz. CHOICE rozeti + tint telefonda elle (headless'ta savaş kazanılmadan tetiklenmez). → [[Build Arketipi — Enhancement, Replacement Değil]]

## [2026-09-15] feature | Battle-pass / Mastery track — arketipler artık AÇILARAK gelir
- Files changed: `scripts/meta/mastery_track.gd` (yeni), `scripts/meta/meta_progress.gd`, `scripts/rpg/run/run_state.gd`, `choice_generator.gd`, `scripts/battle.gd`, `scripts/home.gd`, `tests/test_meta_progress.gd`, `tests/test_run_manager.gd`
- **Neden:** kullanıcı yönü — arketipler/eşyalar rastgele çıkmasın; oynadıkça dolan barla **sırayla açılsın** (battle-pass, retention omurgası). → [[Mastery / Battle-Pass]]
- **`MasteryTrack`** (yeni, pure): kümülatif eşikli sıralı ödül listesi (archetype/equipment/gold/crystal). `reached_tiers`/`next_need`/`next_label`.
- **`MetaProgress`:** `mastery`/`claimed_tiers`/`unlocked_archetypes` + `add_mastery(n)` (dolan tier'ları SIRAYLA claim, ödül uygular, yeni açılanları döndürür) + `is_archetype_unlocked`. to_dict/from_dict'e eklendi (kalıcı, çifte ödül yok).
- **Gating:** `RunState.unlocked_archetypes` (null=sınır yok; Array=yalnız bunlar). `ChoiceGenerator._archetype_candidates` filtreler. `battle.gd` run başında `Meta.unlocked_archetypes`'ı kopyalar + savaş zaferinde `add_mastery` (elite/boss bonus) + yeni açılış toast.
- **UI:** `home.gd` mastery çubuğu (ProgressBar) + "Sıradaki: X (m/need)".
- **Arketip erişimi artık 3 kapı:** açılmış (mastery) + build-bölümü (cadence) + commit edilmemiş (dışlayıcı).
- Yeni class_name için global cache yenilendi. Test **223 geçti**; home+battle smoke temiz. Eşik/kazanç dengesi + claim etkileşimi telefonda/sonra. → [[Mastery / Battle-Pass]]

## [2026-09-15] refactor | Arketip = DIŞLAYICI seçim (buff değil, yön commit'i)
- Files changed: `scripts/rpg/archetype.gd`, `scripts/rpg/run/run_content.gd`, `choice_generator.gd`, `scripts/rpg/turn_manager.gd`, `scripts/battle.gd`, `tests/test_run_manager.gd`, `tests/test_turn_manager.gd`
- **Neden:** kullanıcı geri bildirimi — arketipler "seçimi ifade etmeliydi (burn / tek-hedef infaz / alan)" ama stacklenen buff paketi gibiydi + isim "dönüşüm" vaat edip yapmıyordu. Karar: **dışlayıcı commit** (AskUserQuestion).
- **Dışlayıcı:** `ChoiceGenerator._archetype_candidates` — büyücü zaten bir arketibe commit ettiyse (`archetypes` boş değil) HİÇ arketip sunmaz. "Burn VEYA İnfaz VEYA Patlama", diğer 2 o run kilit.
- **Davranış farkı (sadece +sayı değil):** retheme + yeni hook. 🔥 **Alev** (burn_dmg_amp+dot_amp+burn_spread = DoT), 🎯 **İnfaz** (execute 2.5 + lifesteal = tek hedef bitir), 💥 **Patlama** (yeni `basic_splash` 0.5 + on_kill_aoe = alan/zincir).
- **Yeni motor hook `basic_splash`** (`turn_manager._apply_action`): AoE olmayan party saldırısı komşulara `final_damage×amount` yayılır → Patlama tek-hedef yerine alan oynatır.
- **UI:** `Archetype.icon` (arketip başına 🔥/🎯/💥); `battle._choice_icon` arketipin kendi ikonunu gösterir.
- **Netleştirme:** arketip DÖNÜŞÜM DEĞİL (o kimlik-swap = Storm→Plazma). Arketip = form üstünde dışlayıcı build yönü.
- **Açık kalan:** dokümanın "ayrı arketip-seçim ekranı" (3 seçenek yan yana tek ekran) hâlâ pool üzerinden tekli sunuluyor — ithal edilebilir follow-up. Test **206 geçti** (`build-basic-splash`, dışlayıcı). → [[Build Arketipi — Enhancement, Replacement Değil]]

## [2026-09-15] feature | Build cadence — arketip yalnız build-bölümlerinde (task #4)
- Files changed: `scripts/rpg/run/run_state.gd`, `run_content.gd`, `choice_generator.gd`, `scripts/battle.gd`, `tests/test_run_manager.gd`
- **Ne + neden:** içerik maliyeti dengesi (kullanıcı kararı) — build-değişim (arketip teklifi) her 3-5 bölümde bir; kalan bölümler stat-meta grind. `RunContent.is_build_level(i)` = `i>=3 and (i-3)%BUILD_LEVEL_EVERY(4)==0` → i=3,7,11,15,19.
- **Gating:** `RunState.allow_archetypes` (default true); `ChoiceGenerator._archetype_candidates` false ise boş döner. `battle.gd` run başında `run_state.allow_archetypes = RunContent.is_build_level(Meta.selected_level)`. Relic/dönüşüm/utility her bölümde açık kalır — sadece arketip gate'lenir.
- Test **205 geçti** (`_test_archetype_cadence`); smoke temiz. Yakın-vade task listesi (1-4) TAMAM; #5 (endless adaptive override) endless fazına ertelendi. → [[Makro Oyun — Yol Haritası]]

## [2026-09-15] feature | Elite battle — risk/reward (task #3)
- Files changed: `scripts/rpg/run/run_node.gd`, `run_manager.gd`, `stage_def.gd`, `run_content.gd`, `scripts/battle.gd`, `tests/test_run_manager.gd`
- **Ne + neden:** map'siz risk/reward savaşı (doküman §3). `RunNode.Type.ELITE` + `is_elite()`; `is_battle()` ELITE'i içerir; RunManager ELITE'i battle olarak sunar (`battle_requested`).
- **Yerleşim:** `StageDef.linear`'a opsiyonel `elite_set` (boştan farklıysa boss'tan ÖNCE ELITE + CHOICE ekler; mevcut imza/testler korunur). `RunContent.stage_nodes` tutorial sonrası (i>=3) `_elite_set` (mauler+wraith, HP×1.7 / DMG×1.3) ekler.
- **Ödül:** ELITE yenince orb `ELITE_ORB_MULT=2` ile katlanır (daha güçlü düşman → daha çok orb → relic/arketip alınabilir). `battle.gd` orb ödül dalı `rm.current_node().is_elite()` kontrol eder.
- **UI:** elite savaşta status "☠ ELİT SAVAŞ" + turuncu renk + "çift orb!" flash.
- **Kapsam notu:** doküman §3'teki "build'i sınayan özel kural" (hızlı ritim/direnç) ERTELENDİ — ilk impl sade (daha güçlü + çift orb). Test **198 geçti** (`_test_elite_node`); smoke temiz. → [[Makro Oyun — Yol Haritası]]

## [2026-09-15] feature | Run-end summary ekranı (task #2)
- Files changed: `scripts/battle.gd`
- **Ne + neden:** run kapanış katmanı (doküman §5) — her savaş sonu DEĞİL, run sonu tek özet. Eski `_on_run_ended` sadece status label + home butonuydu; yerine `_show_run_summary(won, cry)`.
- **Gösterir:** başlık (🏆 RUN TAMAMLANDI / 💀 RUN BİTTİ) + **BUILD** (her loadout `form_display_name()` = "Alev Kor Büyücü" + binen arketip adları) + toplanan relikler + **KAZANILAN** (+gold💰 +crystal💎) / kayıpta ilerleme. `_summary_label(text,size,col)` helper (pixel font + kontur). Ödül yazımı (Meta.add_gold/crystal/clear_level) korundu.
- **Kapsam notu:** doküman §5'teki numeric Score + Best Score + New Discovery ERTELENDİ — skor formülü + discovery sistemi henüz karar/faz-2. Şimdilik "kazanılan değer" = gold (gerçek veri, uydurma skor yok). Telefonda elle doğrulanmalı (özet layout). → [[Makro Oyun — Yol Haritası]]

## [2026-09-15] feature | Build arketip sistemi (task #1) — Ember Burn/Crit/Explosion
- Files changed: `scripts/rpg/archetype.gd` (yeni), `scripts/rpg/run/choice_option.gd`, `run_loadout.gd`, `run_state.gd`, `skill_catalog.gd`, `choice_generator.gd`, `run_content.gd`, `scripts/rpg/turn_manager.gd`, `scripts/battle.gd`, `tests/test_run_manager.gd`, `tests/test_turn_manager.gd`
- **Ne + neden:** makro build keşfinin çekirdeği (bkz [[Build Arketipi — Enhancement, Replacement Değil]]). Yeni `Archetype` = run build katmanı; **kimlik-swap'ı DEĞİŞTİRMEZ, üstüne biner** (enhancement). Combat gücü mevcut `RelicSet` kanca mekanizmasıyla akar — `RunState.relic_set()` her loadout'un `archetype_effects()`'ini de ekler → motor değişmeden çoğu efekt çalışır.
- **ChoiceOption.Kind.ARCHETYPE** eklendi (apply → `loadout.add_archetype`); `ChoiceGenerator._archetype_candidates` + COST 24; `generate()` yeniden yapılandırıldı: dönüşüm (kimlik-swap) ana andır → build havuzu (arketip+relic) onu ezmesin diye AYRI tutulur, uygunsa 1 dönüşüm slotu GARANTİ.
- **Ember havuzu (`run_content.ember_archetypes`):** Alev Yükü (burn_dmg_amp×1.6 + dot_amp×1.5 + burn_spread), Öldürücü Ritim (charge_gain_mult×1.5 + execute×2.2), Zincir Patlama (on_kill_aoe×0.6 + burn_spread).
- **Tek yeni motor hook `on_kill_aoe`** (`turn_manager._apply_action` ölüm dalında): party öldürünce komşulara `final_damage×amount` patlama. Diğer efektler mevcut hook'ları yeniden kullanır.
- **UI:** `battle.gd` CHOICE ikon 🔥 + ateş-kırmızı renk + parıltı (dönüşümle birlikte). `RunLoadout.form_display_name()` ön ek verir ("Alev Kor Büyücü").
- **Not:** yeni class_name için `--editor --quit` ile global_script_class_cache yenilendi. Test **189 geçti** (`_test_archetype_choice`, `build-on-kill-aoe`); battle.tscn headless smoke temiz. Telefonda elle: CHOICE'ta arketip kartı + savaşta build hissi. → [[Makro Oyun — Yol Haritası]]

## [2026-09-15] document | Makro oyun yol haritası + build arketip kararı
- Files changed: `wiki/design/macro-game-roadmap.md` (yeni), `wiki/decisions/build-archetype-enhancement.md` (yeni), `wiki/design/_index.md`, `wiki/decisions/_index.md`, `wiki/index.md`, `wiki/hot.md`
- **Neden:** kullanıcı "Makro Oyun — Tasarım Önerileri" dokümanını sundu; kritik + karar oturumu → makro yön netleşti. Kod yok, sadece plan.
- **Kararlar:** (1) Build = **enhancement, replacement değil** — kimlik-swap durur, Burn/Crit/Explosion arketipi üstüne katman, uygulama yolu **B** (ayrı sistem + arketip başına efekt havuzu). (2) İçerik cadence: her **3-5 bölümde bir** build-node; kalan bölümler stat meta (emniyet ağı). (3) Endless'ta ritim **sürekli hızlanır** (adaptive override; campaign'de adaptive kalır). (4) Node map **ertelendi** ama backlog'da kesin. (5) Run-end summary erkene; **orb push-your-luck ertelendi**.
- Karar: [[Build Arketipi — Enhancement, Replacement Değil]] · Yol haritası + task listesi: [[Makro Oyun — Yol Haritası]]

## [2026-09-15] feature | Adaptive ritim zorluğu (piano tiles hızı oyuncuya uyar)
- **Neden:** oyun reflekse dayalı — 20 de 60 yaş da zevk alsın diye piano tiles HIZI oyuncunun gerçek oynayışına göre kendini ayarlar. Adaptive olan tek şey ritim hızı.
- **İki skill (hız çarpanı) — `meta_progress.gd`:** `rhythm_skill` = KALICI global profil (kaydedilir, `RHYTHM_GLOBAL_GAIN=0.020`/cast, yavaş öğrenir) + `_rhythm_session` = OTURUM (RAM, kaydedilmez, `RHYTHM_SESSION_GAIN=0.080`/cast, hızlı tepki → kötü gün / el değişimi). Oturum ilk kullanımda kalıcıdan tohumlanır; uygulama kapanınca sıfırlanır.
- **`record_rhythm_result(combo_score, broke)`:** `err = score − RHYTHM_TARGET_SCORE(0.82)`; kırılınca `err=min(err,−0.30)`. İki EMA'yı clamp'li günceller ([`RHYTHM_SKILL_MIN=0.6`, `MAX=1.6`]) + kaydeder. İyi oynadı→hızlan, zorlandı→yavaşla (fail-soft, kolaylaşma agresif).
- **`rhythm_speed_scale()`:** efektif çarpan = `%40 kalıcı + %60 oturum` (`RHYTHM_SESSION_WEIGHT=0.6`), clamp'li.
- **`rhythm_minigame.gd`:** yeni `SPEED_MIN_SCALE=0.6`; `setup` clamp tabanı `1.0`→`SPEED_MIN_SCALE` (adaptive artık base ALTINA inip yeni/60 yaş için gerçekten yavaşlatabilir).
- **`battle.gd`:** `_on_input_requested` `speed_scale = wave_scale × Meta.rhythm_speed_scale()`; `_on_rhythm_finished` `Meta.record_rhythm_result(score, broke)` çağırır.
- **Kayıt:** `rhythm_skill` `to_dict`/`from_dict`'e eklendi (clamp'li geri yüklenir). Test: `test_meta_progress.gd` `_test_rhythm_adaptive` (default nötr / hızlanma / yavaşlama / clamp / oturum-hızlı-tepki / round-trip). Suite: 179 geçti.
- Files: `scripts/meta/meta_progress.gd`, `scripts/rpg/rhythm_minigame.gd`, `scripts/battle.gd`, `tests/test_meta_progress.gd`. → [[Turn-Based Savaş ve QTE]]

## [2026-09-14] feature | CHOICE ekranı yeniden düzen + yazılar büyütüldü
- **Yazı boyutu (kullanıcı: "çok küçük"):** `project.godot` yeni `[gui] theme/default_font_size=32` (global). Override'lar: `battle` status 18→32, flash 28→40, skill button 18→30 (`_style_button` default font_size param); `rhythm_minigame` hint 16→28; `orb_board` mult 26→34, TOPLAYICI 16→24, HUD 16→26; `home` button 22→34.
- **CHOICE ekranı (kullanıcı: "çok karışık"):** dikey liste → **tek yatay satır** (`HBoxContainer`): **SOL CAN AL** (büyük kırmızı `+`, orb bedeli `HEAL_FIXED_COST=10`, tüm partiyi `HEAL_FIXED_AMOUNT=25` iyileştirir → `_on_heal_fixed` uygular + `skip_choice`) · **ORTA 3 seçenek kutusu yan yana** (ikon üstte `_choice_icon` + ad + bedel; kutu = StyleBoxFlat çerçeve) · **SAĞ PAS** (`»»` şekil + etiket). Reroll ikincil, satır altında.
- **`_style_button`** artık `width`+`font_size` parametreli. `_choice_label` (ölü kod) silindi, yerine `_choice_icon`.
- Files: `scripts/battle.gd`, `scripts/orb_board.gd`, `scripts/home.gd`, `scripts/rpg/rhythm_minigame.gd`, `project.godot`.

## [2026-09-14] fix | Türkçe font: PixelOperator8 → Pixelify Sans Bold
- **Kök neden:** `PixelOperator8-Bold.ttf` (238 glyph) Türkçe `ğ Ğ İ ş Ş` içermiyordu; `allow_system_fallback` bunları pixel-olmayan sistem fontuna düşürüyordu → sanat uyumsuz/kırık. Tüm PixelOperator ailesi (full dahil) bu glyph'leri içermiyor.
- **Çözüm:** Pixelify Sans (chunky pixel, tam Türkçe) — variable font'tan `wght=700` static Bold instance üretildi (`assets/fonts/PixelifySans-Bold.ttf`, OFL). Kullanıcı 3 aday (Pixelify/Jersey10/Handjet) arasından Pixelify seçti.
- **`battle.gd`/`home.gd`/`orb_board.gd`/`rhythm_minigame.gd`:** `PIXEL_FONT` preload yeni fonta.
- **`project.godot`:** yeni `[gui] theme/custom_font=...PixelifySans-Bold.ttf` — global varsayılan font; `characters.gd`/`level_select.gd`/`turn_debug_overlay.gd` (yalnız font_size override eden, önceden default sans kullanan) ekranlar da artık pixel+Türkçe.
- Eski `PixelOperator8-Bold.ttf` + `.import` + cache fontdata silindi. `.import` yeni fontta editör açılınca üretilir.

## [2026-09-14] feature | Ritim (piano tiles) waveler geçtikçe hızlansın
- **`turn_manager.gd`:** yeni `round_index` sayacı — `start_battle`'da 0'a döner, her `_start_round`'da +1. Kaç tur (wave) geçtiğini ölçer.
- **`rhythm_minigame.gd`:** `BEAT`/`SPEED` const → `BEAT_BASE`/`SPEED_BASE` + `_beat`/`_speed` instance. `setup(...)`'a `speed_scale` (default 1.0, tavan `SPEED_MAX_SCALE=2.2`). `_speed=SPEED_BASE*k`, `_beat=BEAT_BASE/k` — uzaysal aralık sabit, notalar daha hızlı gelir.
- **`battle.gd`:** `_on_input_requested` `tm.round_index`'ten `speed_scale = 1 + waves_passed*RHYTHM_SPEEDUP_PER_WAVE (0.12)` hesaplar, `_rhythm.setup(...)`'a geçer. İlk wave 1.0x.

## [2026-09-14] feature | Haptik: mükemmel isabet + hasar verince telefon titret
- **`turn_manager.gd` `_apply_action`:** oyuncu (`by_party`) hasar verince `Input.vibrate_handheld(30)`. Yalnız party tarafı — düşman vuruşu/refleks titretmez.
- **`rhythm_minigame.gd:371`:** MÜKEMMEL isabette `Input.vibrate_handheld(40)` (zaten vardı, doğrulandı).
- **`export_presets.cfg`:** `permissions/vibrate=false→true` (Android VIBRATE izni olmadan `vibrate_handheld` sessizce çalışmaz).
- APK yeniden derlendi + telefona kuruldu (adb, Success).

## [2026-09-14] feature | UX cila: ritim yavaşlatma + ult gösterisi + sembolik beceri butonları + sade buff metni
- **Ritim yavaşlatıldı (`rhythm_minigame.gd`, kullanıcı):** `BEAT 0.52→0.64` (~94 BPM), `SPEED 640→480`, `_lead 0.55→0.72`, pencereler `PERFECT 0.11→0.13`/`GOOD 0.26→0.30`. Piano-tiles daha okunur/yavaş, tolerans biraz geniş.
- **Ultimate gösterisi (`battle.gd`):** ult finisher artık temel finisher'dan **görsel olarak ayrı** — yeni `_ultimate_flourish(rune,is_aoe)`: tam ekran renk flaşı (`_screen_flash`) + kamera sarsıntısı (`_screen_shake`, kökü titret→sıfır) + aoe ise tüm düşman parlaması; finisher patlama ölçeği ult'ta 2.1 (temel 1.5). Yalnız `_combo_skill.requires_charge` iken tetiklenir.
- **Sembolik beceri butonları (`battle.gd` `_build_skill_menu`):** isim yerine büyük **ikon** önce (`_skill_icon`: ember🔥/inferno🌋/plasma⚡/storm🌩/ult🌟), element rengi (`_skill_color`). **Sabit jest dizisi `[◀→▶→●]` KALDIRILDI** butondan (dizi zaten rastgele üretiliyor — "eski fixed şekiller"). Aynı fixed hint `characters.gd._kit_text`'ten de kaldırıldı, yerine `passive_text` cümlesi.
- **CHOICE cila (`battle.gd` `_show_cards`):** menü CHOICE için ayrı konum `y=720`+`separation=20` (spacing hatası), buton `autowrap` + yükseklik 104; tür başına renk (`_choice_color`: mor=dönüşüm/altın=buff/yeşil=iyileş/turuncu=can); **dönüşüm kartı mor parıltı** (`_pulse_button`). Rün etiketi `choice_generator.gd`: "Storm Rünü → X" → **"Storm Rününü Al — X ol"**.
- **Sade buff metni (`run_content.gd`):** relic açıklamalarından jargon (Shatter/DoT/Storm/cast) temizlendi — ör. "Verdiğin hasarın %25'i kadar iyileşirsin.", "Donmuş düşmana 2 kat hasar.", "Düşmanın savunmasını deler."; plazma pasif metni de sadeleşti.
- Files: `scripts/rpg/rhythm_minigame.gd`, `scripts/battle.gd`, `scripts/characters.gd`, `scripts/rpg/run/run_content.gd`, `scripts/rpg/run/choice_generator.gd`. `run_project` runtime temiz (yalnız önceki int-division/scale-shadow uyarıları). Ritim hızı/ult gösterisi/parıltı telefonda elle doğrulanmalı. → [[Turn-Based Savaş ve QTE]]

## [2026-09-14] feature | Ritim minigame → KOMBO dövüşü (rastgele dizi + per-tile büyü + finisher + haptik)
- **Kombo modeli (kullanıcı isteği):** ritim minigame artık tek toplu vuruş değil, **per-tile kombo**. Beceri seçilince **rastgele** jest dizisi (5 yön: `SWIPE_LEFT/RIGHT/UP/DOWN`+`TAP`, sabit `input_sequence.steps` KULLANILMAZ) kayar; her tutturulan tile bir "vuruş" — caster'dan hedefe **escalating fireball** + yükselen hasar sayısı. **Son tile = FINISHER** (en büyük ölçek + `ult` pozu + en büyük hasar; ağırlık `FINISHER_WEIGHT=2.0`). **Yanlış yön VEYA ıska → KOMBO KIRILIR** (kalan tile'lar düşer, finisher kaybolur), erken biter → doğal `NEXT_TURN` ile sıra rakibe. O ana dek vuran tile'lar sayılır (fail-soft floor korunur).
- **Haptik:** her **MÜKEMMEL** tile'da `Input.vibrate_handheld(40)` (Android/iOS; başka platformda no-op).
- **Kombo uzunluğu run içinde uzar:** `battle._combo_length()` = `clampi(2 + int(node_index/2), COMBO_BASE_LEN=2, COMBO_MAX_LEN=6)` — wave/node ilerledikçe 2→…→6.
- **Hasar yolu (motor saflığı korundu):** `RhythmMinigame` kombo başarısını tek `combo_score∈[0,1]`'e indirger (Σ ağırlık×kalite / Σağırlık; PERFECT=1.0, GOOD=0.6). `battle` bunu `mult=max(miss_multiplier, perfect_multiplier·score)` yapıp yeni `TurnManager.submit_input_multiplier(mult, quality)`'e verir → mevcut `_apply_action` (tek olay: şarj/DoT/ölüm/battle-end korunur). Per-tile sayılar `PF·fraction` (PF = "hepsi-PERFECT" nihai hasar, kombo başında `BattleDamage.compute`); toplam ≈ motor `final_damage`, motor otorite. Aggregate FX `_suppress_aggregate_fx` ile bastırılır (projectile/sayı per-tile'da).
- **API:** yeni sinyaller `RhythmMinigame.tile_resolved(index,total,result,is_finisher,fraction)` + `finished({combo_score,broke,tiles})` (eski `finished(result_enum)` + `_aggregate` gitti); `setup(combo_len:int, rect)` (eski `setup(sequence, rect)`). `submit_input(result)` (enum) enemy/no-input yolu için KORUNDU.
- Files: `scripts/rpg/rhythm_minigame.gd` (yeniden yazım), `scripts/rpg/turn_manager.gd` (+`submit_input_multiplier`), `scripts/battle.gd` (`_combo_length`/`_on_tile_resolved`/`_on_rhythm_finished`/aggregate FX bastırma/`_fx_projectile` scale param), `tests/test_turn_manager.gd` (+kombo-çarpan section). Test **172/172**; proje `run_project` runtime temiz (yalnız önceki `run_content.gd:119` int-division uyarısı). Ritim/haptik/finisher telefonda elle doğrulanmalı. Alev büyücüsü asset promptu: `wiki/design/alev-buyucu-asset-prompt.md`. → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] feature | Sol üst debug overlay kaldırıldı + Buton spacing/font düzenlemesi + Ritim dengesi + Top düşürme (Orb Board) rastgele çarpanlar ve UI cilası
- **Sol Üst Debug Overlay (`battle.gd`):** `TurnDebugOverlay` kutusu varsayılan olarak gizlendi (`overlay.visible = false`). F1 ile istenirse açılabilir.
- **Buton Spacing & Taşma Çözümü (`battle.gd`):** `skill_menu` konumu `y=1400`'e çekilerek büyücü sprite'larının üstünü kapatması engellendi; buton aralığı `separation=10` yapıldı; font boyutu `PixelOperator8` 18px ve yüksekliği 78px ayarlanarak uzun kart açıklamalarının taşması önlendi.
- **DOKUN → Nokta (●) Değişimi (`input_sequence.gd`):** Beceri rün ipuçlarında ve ritim notalarında "DOKUN" yazısı yerine piksel nokta `●` simgesi getirildi (`[◀ → ▶ → ●]`).
- **Ritim Minigame Dengeleme (`rhythm_minigame.gd`):** Akıcı ve okunabilir oyun deneyimi için hız `SPEED 640.0`, tempo `BEAT 0.52s` (~115 BPM) ve ilk nota varış süresi `_lead 0.55s` olarak dengelendi.
- **Orb Board Rastgele Çarpanlar ve Piksel UI (`orb_board.gd`):** Çarpan kapıları (x2, x3, x4) her bölüm/tur kurulurken **rastgele dizilir ve konumlandırılır** (`mult_pool.shuffle()`). Çerçeve, HUD ve toplayıcı alanları `PixelOperator8-Bold` piksel fontu ve altın/retro çerçeve stiliyle güncellendi.
- Files: `scripts/battle.gd`, `scripts/rpg/rhythm_minigame.gd`, `scripts/rpg/input_sequence.gd`, `scripts/orb_board.gd`. Test **164/164** geçti.

## [2026-09-13] fix | RhythmMinigame freed instance crash on tap + GDScript warning'leri temizlendi
- **Kök Neden:** GDScript 4'te `var node: Node2D = n["node"]` şeklinde tiplenmiş değişken ataması yapılırken, eğer `n["node"]` nesnesi `queue_free()` ile silinmişse, GDScript henüz `is_instance_valid` satırına gelmeden tip doğrulaması yaparken `Trying to assign invalid previously freed instance` hatası fırlatıyordu. Ayrıca tıklanan/ıskalanan notalar için `_process` döngüsü `if n["hit"]: continue` kontrolü yapmadığı için silinme sürecindeki notaların pozisyonunu güncellemeye devam ediyordu.
- **Çözüm:** `_process` döngüsünde `n.get("hit", false)` olan notalar doğrudan `continue` ile atlandı. Tip ataması öncesinde untyped Variant `raw_node` üzerinden `is_instance_valid` kontrol edilip sonrasında `Node2D` türüne dönüştürüldü.
- **Uyarı Düzeltmeleri:** `skill_catalog.gd`'deki `form` parametre çakışması `p_form` yapıldı, `input_evaluator.gd`'deki gömülü fonksiyon adı olan `exp` değişkeni `expected_steps` olarak değiştirildi.
- Files: `scripts/rpg/rhythm_minigame.gd`, `scripts/rpg/run/skill_catalog.gd`, `scripts/rpg/input_evaluator.gd`. Test **164/164** geçti.

## [2026-09-13] feature | Ritim minigame + orb board yeniden tasarım + görsel cila (6 istek)
- **Ritim minigame (Piano Tiles) — eski kaydırma/basma jesti KALDIRILDI:** yeni `scripts/rpg/rhythm_minigame.gd` (`RhythmMinigame`, Node2D, koddan kurulur). Beceri dizisindeki her adım için bir NOTA sağdan sola kayar, hedef çizgiye gelince BAS → `±0.11s`=PERFECT, `±0.26s`=GOOD, ıska=MISS. Toplu sonuç (fail-soft: hepsi mükemmel→PERFECT, en az bir tuttu→GOOD, hiç→MISS) `finished(result)` ile `InputEvaluator.Result` olarak verilir. `battle.gd._on_input_requested` artık minigame açar (`_on_rhythm_finished`→`tm.submit_input`); `_unhandled_input`/`_classify`/`_record_gesture`/`_finish_input`/`_input_prompt` + `INPUT_TIMEOUT`/`SWIPE_MIN` silindi.
- **Orb board yeniden tasarım (`orb_board.gd`):** NEGATİF/<1 çarpan YOK; çarpanlar artık NOKTA değil YATAY ÇİZGİ (gate); peg sayısı 6 satır→3 (az nokta=strateji>şans). Çizgiden geçen orb PUAN değil TOP SAYISI çarpar (x2→1 klon, x3→2 klon, `MAX_ORBS=90` patlama koruması, klonlar aynı gate'i tekrar tetiklemez). Puan = toplanan orb × `ORB_VALUE` (`OrbBoardResult.score` array-of-1.0 ile korundu → test değişmedi).
- **Savaş görselleri (`battle.gd`):** (1) kazanınca "victory" sevinme animasyonu KALDIRILDI (idle kalır). (2) daha büyük çizim: `WIZARD_SCALE` 0.62→0.9, `ENEMY_SCALE` 1.6→2.15; düşmanlar sağda YATAY DİZİ (arka arkaya, `ENEMY_COL_GAP`), uçanlar (ejderha/okçu) havada durur + hover (`_enemy_floats`/`_hover`). (3) kare impact patlaması → YUVARLAK (`_impact_burst`: dolgu disk + genişleyen halka, `_circle_poly`/`_ring_line`; `fx_impact_spark` kullanımı kaldırıldı). (4) rün dönüşümü artık CHOICE'ta değil, SONRAKİ savaşın ilk turunda reveal animasyonu (`_pending_form_reveal`/`_reveal_transform`, "levelup"→idle).
- Files: yeni `scripts/rpg/rhythm_minigame.gd`; `scripts/battle.gd`, `scripts/orb_board.gd`. Test **164/164**; 3 script headless compile temiz (yeni class cache reimport edildi). Ritim/board/hover telefonda elle doğrulanmalı. → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] feature | SpellFX: büyü efektleri (mermi/ışın/AoE) carrier+element'e göre + hasar sayısı
- **Efekt assetleri (hibrit, sheet'ten çıkarıldı):** kaynak JPEG'lerden flood-fill ile 6 efekt sprite: `fx_fireball` (ember mermi), `fx_plasma_orb`, `fx_fire_comet` (rainbow meteor=Inferno), `fx_plasma_beam` (yatay plazma ışın shaft), `fx_impact_spark` (mavi impact yıldızı), `fx_storm` (mor şimşek AoE; "Atlama" yazısı kırpılarak temizlendi). `assets/wizard/fx_*.png` + .import.
- **SpellFX sistemi (`battle.gd`):** `Skill.carrier` (Projectile/Beam/Area/Storm) + `rune_id` (renk) efekti seçer. `_spawn_spell_fx` → `_fx_projectile` (caster elinden hedefe tween), `_fx_beam` (uzatılmış beam sprite + fade), `_fx_area` (comet düşer + tüm düşman ateş parlaması), `_fx_storm_aoe` (storm sprite + elektrik parlaması). Element rengi `_fx_color` (ember=turuncu, storm=mor, ""=pale). Düşman mermisi sola (flip).
- **Impact senkron:** `_on_damage_resolved` artık hurt/hasar-sayısını efekt VARIŞINDA gösterir (`_schedule_impact` tween interval). `_impact_burst` (spark küçük→büyük fade) + `_float_damage` (yükselen hasar sayısı, outline). `_next_turn_delay` impact süresini kapsar.
- Files: `scripts/battle.gd`, yeni `assets/wizard/fx_*.png`. Editör import + headless run temiz (sadece alakasız eski warning). Savaş-içi görsel telefonda/elle doğrulanmalı. → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] fix | Savaş-sonu + saldırı animasyonları görünmüyordu (timing) + ayrı ULT anim
- **Kök sorun:** `TurnManager._apply_action` `damage_resolved`→`battle_ended`'i **senkron** atıyor; `battle.gd._on_battle_ended` anında `rm.report_battle_result` çağırıp sıradaki node'u kuruyordu → son vuruş cast/ult + ölüm animasyonları oynayacak frame bulamıyordu (wave/oyuncu ölünce hiçbir şey görünmüyor).
- **Çözüm (deferred battle-end):** `_on_battle_ended` artık report'u hemen çağırmaz — `_pending_end`+`_end_delay=BATTLE_END_PAUSE(1.6s)` kurar, zafer pozunu başlatır. `_process` bekleme boyunca sadece `_update_bodies`/overlay günceller (ölüm anim'i burada oynar), süre bitince `_finalize_battle` (orb+HP kaydı+`report_battle_result`). `_start_battle` flag'leri sıfırlar.
- **Ayrı ULT animasyonu:** `tm.action_selected`→`_on_action_selected` son beceriyi (`_last_skill`) yakalar; `_on_damage_resolved` party saldırısında ultimate(`requires_charge`) ise **"ult"**, değilse "cast" oynatır. `_on_sprite_anim_finished` listesine "ult" eklendi (bitince idle).
- Files: `scripts/battle.gd`. 4 sahne headless temiz (alakasız eski warning'ler). Savaş-içi görünüm telefonda/elle doğrulanmalı. → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] feature | Gerçek büyücü sprite'ları (Ember=fire, Plazma=arcane) + form→sprite bağlama
- **Assetler:** Gemini pixel-art sprite sheet'lerinden (turuncu ateş + mor arcane büyücü, 2048² JPEG, beyaz zemin) temiz atlas üretildi. Python pipeline (scratchpad `extract.py`): köşelerden flood-fill ile SADECE zemin beyazı saydamlaştırıldı (sakal/göz beyazı korunur), her animasyon karesi bbox'a kırpıldı, global sabit ölçekle 256px hücreye alt-orta hizalandı. Çıktı: `assets/wizard/wizard_fire_sheet.png` + `wizard_arcane_sheet.png` (1024×1536, 4 sütun × 6 satır).
- **SpriteFrames:** `wizard_fire_frames.tres` + `wizard_arcane_frames.tres` üretildi. Anim'ler: idle(3,loop), cast(4), hurt(3), death(4→ceset), victory(3=LvlUp), ult(4), walk(=idle), levelup(=victory). battle.gd'nin beklediği tüm isimler mevcut.
- **Form→sprite bağlama:** `run_content.gd` sprite_key: ember→`wizard_fire`, plasma→`wizard_arcane`. `battle.gd` yeni `PLAYER_FRAMES` dict + `_player_frames(c)` (güncel `RunLoadout.current_form.sprite_key`, fail-soft fire). `_on_transformed` canlı party sprite'ını yeni forma çevirip "victory" (dönüşüm) animasyonu oynatır. `wizard.tscn` yeni fire frames'e yönlendirildi.
- Silindi: eski placeholder `wizard_sheet.png`/`Sprite-0001.png`/`wizard_frames.tres` (+.import). Godot editör import ile .ctex üretildi; 4 sahne headless temiz (sadece alakasız eski shadow/exp warning).
- **Bekleyen:** LvlUp→transform'da mor ULT beam'in "plazma" transform efekti olarak ayrı overlay'i (kullanıcı planı "sonra"). → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] refactor | REDESIGN: kimlik-swap formlar + aktif girdi (tap/swipe) + Ember→Plazma dilim + ekipman
- **Yön (yeni source of truth — spec):** oyun = Cup Heroes tarzı roguelite RPG. Çekirdek döngü FIGHT → EXECUTE (aktif girdi) → KILL → EARN ORBS → MULTIPLY (board) → CHOOSE → TRANSFORM → FIGHT. Önceki oturum çizim/rün/QTE'yi zaten silmişti (doğru); bu refactor 3 kullanıcı kararını uyguladı.
- **(1) Kimlik-swap dönüşüm (combo matrisi KALDIRILDI):** yeni `scripts/rpg/mage_form.gd` (`MageForm` = temel büyü + ultimate + pasif + aktif girdi + sprite). Storm rünü alınca form KOMPLE değişir (Ember→Plazma): temel büyü, girdi, ultimate hepsi yeni. `SkillCatalog` forms+transforms'a döndü (add_form/transform_for/acquirable_runes); `RunLoadout.current_form` + `acquire_rune`/`transform_to`; `ChoiceOption.DRAFT_RUNE→ACQUIRE_RUNE` (hedef form params'ta); `RunManager.combo_discovered→transformed`; `RunState._init(party, start_forms)`.
- **(2) Aktif girdi geri geldi (çizim DEĞİL):** yeni `input_sequence.gd` (TAP/SWIPE_L/R/U/D + window) + `input_evaluator.gd` (saf: PERFECT/GOOD/MISS, fail-soft). `TurnManager` `AWAITING_INPUT` state + `select_action`→`input_requested`→`submit_input(result)`; `BattleConfig` perfect/good/miss çarpanları (1.5/1.25/1.0), `qte_hit_threshold/qte_speed_floor` silindi. `battle.gd` jesti `_unhandled_input`'ta yakalar (butonlar çalışsın diye), 3s timeout fail-soft. `Skill` çizim alanları silindi (rune_sequence/qte_*), `input_sequence` eklendi; `DamageBreakdown.qte_*→input_*`. Ember pasifi (yakma) temel büyünün `dot_fraction`'ıyla ifade edilir. Ultimate `aoe` bayrağı (Inferno/Plazma Fırtınası).
- **(3) Ember→Plazma dilime daraltıldı:** `run_content.gd` tek Kor(Ember) büyücü, `[BATTLE,CHOICE]×3→BOSS→REWARD`, 3 arketip (grunt/archer/brute, brute Burn-dirençli→Plazma ödülü) + Kül Ejderi boss, `LEVEL_COUNT` 20→5. 3-büyücü + 6-combo + 20-seviye tablosu PARK edildi.
- **(4) Ekipman (spec Part 17):** yeni `scripts/rpg/equipment.gd` (9 parça, 3 slot HELMET/ARMOR/BOOTS, Relic ile aynı hook deseni). Meta `owned_equipment`/`equipped` + kaydet + al/tak. Savaş: takılı ekipman `RelicSet`'e duck-typed eklenir (`battle.gd`); yeni hook'lar `burn_dmg_amp`/`shatter_dmg_amp` (BattleDamage), `reflect` (TurnManager), `speed_flat`/`max_hp_flat` (kurulumda). Shop UI `characters.gd`'de.
- Yeni dosyalar: `mage_form.gd`, `input_sequence.gd`, `input_evaluator.gd`, `equipment.gd`, tests `test_input_evaluator.gd`/`test_mage_form.gd`/`test_equipment.gd`. Silindi: `scripts/rpg/test_battle_data.gd` (eski combo fixture). `home.gd`/`level_select.gd` değişmedi (uyumlu).
- **Orb terminolojisi:** "draft puanı" → "orb" (board çarpılmış orb üretir, kart bedeli orb). Mekanik aynı.
- Test **113→164 geçti**, 0 kaldı. Dört sahne (battle/characters/home/level_select) headless smoke temiz. Fizik board + jest telefonda elle test edilmeli. → [[Turn-Based Savaş ve QTE]]

## [2026-09-13] feature | Core loop yeniden tasarım: çizim kaldırıldı, orb board + relic'ler
- Files changed (çekirdek): `scripts/rpg/turn_manager.gd` (QTE state SİLİNDİ → anında çöz), `battle_damage.gd` (cast_bonus + relic hook: frozen_amp/execute/shatter_pierce), `combatant.gd` (`pending_amp`, `heal`), `battle_config.gd` (qte alanları kaldı ama kullanılmıyor).
- Files changed (run): `run_state.gd` (`orbs`, `relics`, `relic_set()`), `run_content.gd` (6-combo TAM MATRİS + `relic_catalog()` 8 relic), `skill_catalog.gd` (relics), `choice_option.gd` (RELIC kind + `cost`), `choice_generator.gd` (relic adayları + cost), `run_manager.gd` (`combo_discovered`, `reroll_choices`, `skip_choice`).
- Yeni: `scripts/rpg/relic.gd`, `scripts/rpg/run/relic_set.gd`, `scripts/rpg/run/orb_board_result.gd` (saf skorlama), `scripts/orb_board.gd` (fizik Plinko board, kod-kurulu).
- Silindi: `qte_minigame.gd`, `core/rune_templates.gd`, `core/rune_recognizer.gd`, `core/fake_recognizer.gd`, `core/rune_db.gd`, `recognizer_adapter.gd`, `rune_trail.gd`, `charge_button.gd`, `tests/test_rune_templates.gd`.
- **Ne değişti (kullanıcı yönü):** oyun "hangi build'i kurup nasıl kullanırım" etrafına döndü. (1) **Çizim/QTE tamamen kaldırıldı** — beceri menüden seçilince ANINDA çözülür, cast çarpanı hep uygulanır (ıska yok). (2) **Combo TAM MATRİSİ** — 6 element çifti (ember/frost/gale/storm), iki farklı rün tutulunca EMERGENT açılır + "YENİ BİRLEŞİM" flash (`combo_discovered`). (3) **Orb ekonomisi = Cup Heroes board** — yenilen düşman başına 1 orb, CHOICE'ta fizik Plinko board'a DOKUN-BIRAK ile dökülür → çarpanlar → DRAFT PUANI → kart seç/reroll/pas. Combat orb HARCAMAZ. (4) **Relic kartları** — 8 kural-değiştiren relic (Wildfire/Overcharge/Permafrost/Kondansatör/Köz/Kan Bağı/İnfaz/Delici), run boyu kalıcı, savaş motoru hook noktalarında `RelicSet`'e sorar.
- **Ertelendi:** aktif savunma (dodge/block), beceri-başına mikro-oyun.
- Test 94→**113 geçti** (QTE testleri anında-çöz API'sine yazıldı; relic hook + orb skor + reroll/skip + combo keşfi eklendi). Runtime smoke: battle.tscn headless temiz. Fizik board telefon/masaüstünde elle test edilmeli (headless girdi yok). → [[Turn-Based Savaş ve QTE]]

## [2026-09-12] config | Düşman yön flip + yeni APK telefona kuruldu
- Files changed: `scripts/battle.gd` (enemy `flip_h=true`), `build/wizard_game.apk` (yeniden export, 38MB).
- Düşman sprite'ları party'nin tersine bakıyordu → `flip_h=true` ile party'e döndürüldü.
- Export: JAVA_HOME=openjdk@17, `Godot --headless --path . --export-debug "Android" build/wizard_game.apk`. `adb install -r` ile cihaza (to4dzpk7kzmzcadm) kuruldu + monkey LAUNCHER ile başlatıldı. Paket `com.example.wizardgame`.

## [2026-09-12] feature | Düşman sprite'ları + İngilizce grade övgüsü + pixel font
- Files changed: `assets/enemies/{dragon,goblin,dev}.png` (+ `_frames.tres`, yeni), `assets/fonts/PixelOperator8-Bold.ttf` (yeni), `scripts/battle.gd`.
- **Düşman assetleri:** kullanıcı etiketli referans sheet verdi (572×1024, 3 düşman × 4 satır: yürüyüş/attack/hurt/ölüm, gri grid arka plan). Python ile: satır bandları gri-yoğunlukla + satır-içi x-segmentasyonla frame'lere bölündü, gri global key + koyu kenar-flood ile şeffaflaştırıldı, 96px hücrelere taban-ortalandı → 3 temiz atlas (384×384, satır=anim). Frame: dragon[idle4,hurt1,death2], goblin[idle4,attack4,hurt1,death4], dev[idle4,attack3,hurt1,death4] (dragon attack/death dağınık → o anim'ler atlandı, idle fallback).
- **Savaşta:** düşman ColorRect → AnimatedSprite2D. `_enemy_sprite_key`: boss→dragon, brute/mauler/warden/golem→dev, diğer→goblin. Sağda zeminde, sola bakar (party'e). Wiring: saldırı→attack, hasar→hurt, KO→death (`_enemy_play` has_animation guard, yoksa idle). Üstünde can barı.
- **Grade övgüsü:** sayı kaldırıldı, İngilizce (`GRADE_TEXT`: PERFECT!/GREAT!/NICE!/GOOD/MISS), font PixelOperator8-Bold (96px) + outline10 + shadow → sanat temalı. Test 112/112, runtime temiz.

## [2026-09-12] feature | Karakter statları: yazı → can + enerji barı (isim yok)
- Files changed: `scripts/battle.gd`.
- Parti üstündeki `Label` metni kaldırıldı (isim/HP/şarj yazısı yok). Yerine 2 ColorRect bar: **can** (yeşil→sarı→kırmızı `_hp_color`) + **enerji/şarj** (mavi, dolunca altın). `_make_bar` (bg + child fill) / `_set_bar` (oran+renk) helper'ları. Düşman kutusu da yazısız, üstünde tek can barı.
- max HP kaynağı `c.source.max_hp` (Combatant'ta `max_hp` yok — ilk denemede crash, düzeltildi). Durum ipuçları sprite modulate'e taşındı (stun mavi, yanma turuncu). Runtime temiz.
- BEKLEYEN: kullanıcı "iki çeşit düşman asseti" dedi ama arka plan resmini (battle_bg) tekrar attı — düşman spritesheet'i gelmedi, düşmanlar hâlâ ColorRect.

## [2026-09-12] feature | Savaş arka planı + karakterler zemine oturtuldu
- Files changed: `assets/battle_bg.png` (yeni, 572×1024), `scripts/battle.gd`.
- `_ready` başında `Sprite2D` bg: `centered=false`, pos (0,0), viewport 1080×1920'ye ölçekle doldur (~1.89×1.88, en-boy neredeyse özdeş), `z_index=-10` → her şeyin arkasında.
- Konumlar yeniden: eski y=700 karakterleri gökyüzünde uçuruyordu. Yeni `GROUND_Y=1330` (tuğla döşeme üstü ~y1275 + gömülü), `BODY_GAP=175`. Parti sprite ayak çizgisine basar (sol x140 merkezli), düşman kutusu tabanı zemine oturur (sağ x830). Ek üyeler yukarı istiflenir. Offline PIL önizleme ile doğrulandı, runtime temiz.

## [2026-09-12] feature | Wizard sprite savaşa bağlandı (parti ColorRect → AnimatedSprite2D)
- Files changed: `scripts/battle.gd`.
- `_build_bodies` PARTİ üyeleri için artık `wizard.tscn` instantiate eder (ölçek 0.62, gövde kutusunda ortalı); DÜŞMANLAR hâlâ ColorRect. HP/şarj label sprite üstünde (z_index 1).
- Animasyon olayları: saldıran büyücü→`cast`, hasar/DoT alan→`hurt`, KO→`death` (bir kez, `dead_played` guard), zafer→`victory`. `cast/hurt/walk` bitince `animation_finished`→`idle`. Aktif sıra sprite modulate ile parlar, ölü gri.
- `_clear_bodies`/`_update_bodies` sprite+box iki dalı işler. Test 112/112, battle.tscn runtime temiz (sadece eski `mini` isim uyarısı).

## [2026-09-12] feature | Wizard animasyonlu sprite (16-frame sheet → SpriteFrames)
- Files changed: `assets/wizard/wizard_sheet.png` (yeni, arka plan şeffaflaştırıldı), `assets/wizard/wizard_frames.tres` (yeni SpriteFrames), `scenes/wizard.tscn` (yeni AnimatedSprite2D).
- Kaynak `Sprite-0001.png` 1024×1024, 4×4 grid, 256px hücre, opak lacivert (18,18,30) arka plan. Kenarlardan flood-fill ile bg → alpha 0 (iç koyu outline'lar korundu, ~70% şeffaf).
- 6 animasyon eşlendi: idle(0-3 loop), cast(4-7), hurt(8-9), walk(10-11 loop), victory(12-13 loop), death(14-15). AtlasTexture bölgeleri tek sheet'e bakar. Godot 4.7.2'de headless çalıştırıldı, hata yok, idle autoplay.

## [2026-09-12] feature | 20 seviyelik zorluk eğrisi (tutorial 1-3 korundu)
- Files changed: `scripts/rpg/run/run_content.gd` (LEVEL_COUNT 3→20, hp_scale/dmg_scale ayrıldı, arketip+tema veri-tablosu `_LEVELS` i=3..19, `_mob`/`_mobs`/`_boss_mob` kurucular), `scripts/level_select.gd` (20 buton için ScrollContainer).
- **İlk 3 bölüm DEĞİŞMEDİ:** tutorial builder'ları (`_battle_1/_battle_2/_boss`, nötr, s=1+0.15i) i<3 için aynen kullanılır → byte-özdeş çıktı (headless probe ile doğrulandı: L1 Goblin hp30/dmg6, Kül Ejderi hp100/dmg12).
- **Zaaf temaları (mono büyücü adil):** oyuncu tek element taşır (Kor=Burn, Buz=Freeze, Yel=Push) + herkesin draft ettiği storm=Shatter. Temalar: `storm`(Shatter-zayıf→storm draft+shatterwave+combo ödüllenir), `elem`(tüm element-zayıf→kendi elementin), `ward`(Shatter-dirençli→kendi elementine dön), `aegis`(tüm element-dirençli+Shatter-zayıf→storm/shatterwave ŞART, combo bile element-etiketi taşıdığı için yarılanır). Hiçbir tema tek büyücüyü duvara toslatmaz (draftla her rün açılır; zaaf bonus, kapı değil).
- **Zorluk kolları (karakter geliştirmeye iter):** HP ölçeği dik (1.30+0.18/lv → boss DPS-check → POWER upgrade + combo), hasar ölçeği yumuşak (1.30+0.12/lv → CAN upgrade + heal), düşman sayısı (kalabalık → hayatta kalma), zaaf teması (kit genişletme/draft baskısı). Tier'ler: T1(4-6) zaaf tanıtımı, T2(7-10) combo+hayatta kalma, T3(11-15) karışık tehdit, T4(16-20) ustalık, L20 capstone Boşluk Devi (aegis, hp~785/dmg~53).
- **Arketipler:** grunt/runner/archer/brute/wraith/warden/mauler + bosslar drake/warlord/golemking/frostcrone/stormlord/voidtitan. Tests 112/112. → [[Turn-Based Savaş ve QTE]]

## [2026-09-12] feature | 3 mono büyücü seçimi + tek-karakter tutorial (3 bölüm) + wave-arası şarj decay
- Files changed: `scripts/rpg/run/run_content.gd` (3 mono büyücü + 3 combo + 3 kolay bölüm), `scripts/rpg/run/run_loadout.gd` (`charge` taşıma + `store_charge`), `scripts/meta/meta_progress.gd` (`selected_character` + `select_character`), `scripts/battle.gd` (tek seçili karakterle run + wave-arası şarj taşı/decay), `scripts/home.gd` (varsayılan seçim + aktif büyücü göster), `scripts/characters.gd` (SEÇ butonu + rün/kombo ipucu), `tests/test_run_manager.gd` (charge_carry testi + kayra→kor).
- **Karakter modeli (kullanıcı):** oyun başı 3 mono-element büyücüden biri seçilir: **Kor**(Ateş/ember), **Buz**(Frost/frost), **Yel**(Rüzgar/gale). İlk 3 bölüm TEK karakterle, kolay. Her büyücü element rünüyle başlar; **storm (yıldırım)** rününü draft edince kendi birleşimi açılır (ortak katalizör): ember+storm→Plazma(yakma), frost+storm→Buz Fırtınası(stun), gale+storm→Siklon(push). `tempest`(frost+gale) kaldırıldı.
- **Wave-arası şarj decay (kullanıcı düzeltmesi):** Şarj eskiden her savaşta yeni `Combatant` ile **sıfırdan** başlıyordu (waveler arası taşınmıyordu). Artık HP gibi `RunLoadout.charge`'da **savaşlar (wave) arası taşınır**, ama her geçişte **%20 düşer** (`store_charge`, bileşik, asla<0: 100→80→64...). Savaş-içi tur-sonu decay YOK (önce yanlış anlaşılıp eklenmişti, geri alındı). Düşen üye şarjını sıfırlar. `WAVE_CHARGE_DECAY=0.20` battle.gd'de.
- **Tutorial dengesi:** `LEVEL_COUNT` 5→3, ölçek 0.30→0.15/seviye, düşmanlar NÖTR (zaaf/direnç yok — hangi büyücü seçilirse adil), boss HP 180→100. Zaaf mekaniği tutorial sonrasına ertelendi.
- Test 112/112, home/characters/battle sahneleri headless temiz.

## [2026-09-12] config | Çizim minigame kutusu aşağı taşındı — parmakla erişim
- Files changed: `scripts/battle.gd` (`MINI_RECT` y 680 → 1180), `scripts/rpg/qte_minigame.gd` (fallback `rect` aynı).
- **Sorun (kullanıcı):** Çizim kutusu ekranda çok yukarıda — parmakla (başparmak) erişmek zor.
- **Düzeltme:** Kutu 1080×1920 portre ekranda alt üçlüğe indirildi: y=1180, yükseklik 560 → alt kenar 1740 (~180px margin). `_clear_menu()` QTE'den önce çalıştığı için skill_menu (y=1320) ile çakışma yok.

## [2026-09-12] config | Rün skorlama toleransı gevşetildi — MAX_DIST 0.40 → 0.60
- Files changed: `scripts/core/rune_templates.gd` (`MAX_DIST` sabiti).
- **Sorun (kullanıcı):** Çizim toleransı çok düşük — özensiz ama doğru şekil çizimler çok düşük puan alıyordu.
- **Ölçüm (headless probe, 40 deneme/amp):** MAX_DIST=0.40'ta %12-16 parmak titremesi (touch için normal) sadece 0.53-0.79 skor. 0.60'ta 0.68-0.86'ya çıktı. Yanlış şekil hâlâ ~0.06-0.11 (eşik altı, ayrıştırma korundu — çünkü stroke-sayısı cezası ayrı katman). 108 test geçti.
- **Not:** `MAX_DIST` skor eğiminin eğimidir (score = 1 - dist/MAX_DIST); büyütmek doğru-şekil özensiz çizimleri ödüllendirir, yanlış şekli değil (o COUNT_PENALTY ile ikinci kez korunur).

## [2026-09-10] config | APK export Desktop'a — editor settings Android yolları tamir
- Files changed: `~/Library/Application Support/Godot/editor_settings-4.7.tres` (proje dışı), YENİ `~/Library/Application Support/Godot/keystores/debug.keystore`. Çıktı: `~/Desktop/run_buyucusu.apk` (36M, arm64-v8a, debug-signed).
- **Sorun:** export "A valid Java SDK path required" + "Invalid Android SDK path / missing platform-tools/build-tools" + keystore yok — editor settings sıfırlanmış (önceki 2026-09-07 build'den beri).
- **Düzeltme (3):** `export/android/java_sdk_path` = `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`; `export/android/android_sdk_path` = `/opt/homebrew/share/android-commandlinetools` (eski `~/Library/Android/sdk` yoktu); debug keystore `keytool -genkeypair ... -storepass android -alias androiddebugkey -keypass android` ile üretildi (`keystores/debug.keystore`, ayarda yol zaten işaret ediyordu).
- Komut: `JAVA_HOME=<jdk17> Godot --headless --path . --export-debug "Android" ~/Desktop/run_buyucusu.apk`. `cannot connect to daemon tcp:5037` zararsız (adb auto-install, cihaz bağlı değil). SDK: build-tools 35.0.0, platform-tools mevcut.

## [2026-09-10] fix | Wave-sonu crash — _process'te stale/null tm erişimi
- Files changed: `scripts/battle.gd` (_process yeniden kurgulandı).
- **Semptom (kullanıcı):** Godot'ta oynarken bölüm wave sonlarında ara sıra crash.
- **Kök neden:** `_process` içinde `tm.tick()` / `advance_turn()` / `submit_drawing()` savaşı bitirebiliyor → sinyal zinciri (`battle_ended` -> `report_battle_result` -> `_on_choice_requested`/`_on_run_ended`/`_on_battle_requested`) aynı frame içinde `tm`'i null'a VEYA yeni bir TurnManager'a atıyor. Sonraki satır `if tm.state == ...` stale/null `tm`'e erişince crash (DoT son düşmanı öldürdüğünde advance_turn, ya da submit son vuruş olduğunda — o yüzden "bazen").
- **Çözüm:** yerel `cur_tm := tm` ile çalış; her savaş-bitirebilen çağrıdan (`tick`/`advance_turn`/`submit_drawing`) SONRA `if tm != cur_tm: return` ile frame'den çık (member `tm` sinyal handler'ında değiştiyse). Önceki `TurnDebugOverlay.update_view` null-guard'ı yerinde duruyor (ikincil savunma). Test 108/108, runtime temiz.

## [2026-09-10] feature | QTE skorlama — doğruluk+hız kalitesi, çoklu-stroke, övgü + maks hasar
- Files changed: YENİ `scripts/core/rune_templates.gd`, `tests/test_rune_templates.gd`. DÜZENLENDİ `scripts/recognizer_adapter.gd` + `scripts/core/{rune_recognizer,fake_recognizer}.gd` (score eklendi), `scripts/rpg/{turn_manager,battle_damage,damage_breakdown,battle_config,qte_minigame,turn_debug_overlay}.gd`, `scripts/rpg/run/run_content.gd`, `scripts/battle.gd`, `tests/{run_tests,test_turn_manager}.gd`.
- **Kök sorun:** recognizer KATEGORİK (sadece "X mi O mu"), skor yok → özensiz X bile TAM bonus. Ayrıca finger-up = anında submit → X'in 2. çizgisine fırsat yok. Menü `base_damage` (en düşük) gösteriyordu.
- **QTE artık SKORLU (kullanıcı isteği):** `RuneTemplates.score(strokes, rune)` = $1-ruhu geometrik doğruluk (ortak kutuya normalize → konum/ölçek bağımsız, stroke'ları yön-bağımsız eşle, ortalama nokta mesafesi → [0,1]; yanlış stroke sayısı cezalı). Kimlik hâlâ `recognize` (doğru rün mü), `score` özeni ölçer. `TurnManager`: kalite = `accuracy*(speed_floor + (1-floor)*hız_oranı)`; **eşik** (`BattleConfig.qte_hit_threshold`=0.45) altı = ıska (fail-soft taban), üstü = **kaliteyle ölçekli bonus** (1.0 → `qte_bonus_multiplier`). `submit_qte(rid)` identity yolu kalite 1.0 (testler korunur). `BattleDamage.compute` artık `qte_bonus: float` alır (bool değil).
- **Çoklu-stroke (X kapanma bug'ı):** `battle.gd` anında submit ETMEZ; parmak kalkınca `SUBMIT_DEBOUNCE`=0.55s idle bekler, yeni stroke iptal eder → X iki çizgiyle çizilebilir. QTE süreleri artırıldı (ember 3.2s vb.).
- **Övgü + puan:** `qte_scored(quality, grade)` sinyali → çizimden HEMEN sonra ekranda "MÜKEMMEL/HARİKA/GÜZEL/FENA DEĞİL/IŞKA + N puan" (renkli). Menü artık **maks potansiyel hasar** gösterir (`base*qte_bonus_multiplier`, "doğru+hızlı çizimde").
- **Bug fix:** `TurnDebugOverlay.update_view` null-güvenli — savaş bitince (`tm=null`) aynı frame'de çağrılıp `tm.active` null erişimiyle her savaş sonu CRASH ediyordu.
- Test: **108/108 geçti** (+skorlama: mükemmel yüksek / yanlış şekil+yarım X düşük / konum-ölçek bağımsız; +QTE kalite: düşük accuracy ıska, iyi accuracy ölçekli bonus, tam→MÜKEMMEL). `run_project` runtime temiz (savaş sonu crash gitti). → [[Turn-Based Savaş ve QTE]], [[Rün Çizim Mekaniği]]

## [2026-09-10] feature | Meta ilerleme — home/characters/level select + 2 para + kalıcı kayıt
- Files changed: YENİ `scripts/meta/meta_progress.gd` (autoload `Meta`), `scripts/{home,level_select,characters}.gd`, `scenes/{home,level_select,characters}.tscn`, `tests/test_meta_progress.gd`. DÜZENLENDİ `scripts/rpg/run/run_content.gd` (seviye-bilinçli), `scripts/battle.gd` (meta bağlama), `tests/{run_tests,test_run_manager}.gd`, `project.godot` (autoload + main_scene=home).
- **Meta katman (kullanıcı spec'i):** kalıcı `MetaProgress` = autoload `Meta`, `user://meta.json`'a JSON kayıt. İki para: **Altın** (soft, bölüm sonu kazanılır, TÜM upgrade'ler bununla) + **Kristal** (premium, nadir, gerçek-para IAP stub). **Kristal ayrı sink YOK** — `convert_crystal` ile altına çevrilir (1 kristal = 100 altın, kullanıcı kararı).
- **Upgrade:** karakter başına 2 track — CAN (+15 max HP/lv) ve HASAR (+4 flat hasar/lv), altınla, maliyet `base*(lv+1)` (CAN base 50, HASAR base 75). CAN savaş başında parti max HP'sine, HASAR becerilere (duplicate + flat) baklanır — katalog mutasyona uğramaz.
- **Sayfalar (kod-içi UI, main_menu/battle pattern'i):** `home` (para çubuğu + OYNA→level select + KARAKTERLER + KRİSTAL→ALTIN + KRİSTAL AL test stub + ÇIKIŞ), `level_select` (RunContent.level_count()=5 seviye, `Meta.is_level_unlocked` ile kilit, seçince `Meta.selected_level`→battle), `characters` (karakter seç → stat paneli + CAN/HASAR yükselt butonları, altın yetersizse kilitli). main_scene artık `home` (eski main_menu duruyor, bağlı değil).
- **Seviye sistemi:** `RunContent` seviye-bilinçli — `stage_nodes(i)` zorluk ölçekli (düşman HP+hasar ×(1+0.30i)), `reward_gold(i)=80+40i`, `reward_crystal(i)=1`. Bölüm kazanınca `battle.gd` ödülü Meta'ya yazar + `clear_level` (sonraki açılır) + ANA EKRAN butonu.
- Test: **95/95 geçti** (+meta: maliyet/satın alma/bonus/çevrim/kilit/serileştirme; `persist=false` + node `free()` → sızıntı yok). `run_project`: home/characters/battle runtime TEMİZ. → [[Turn-Based Savaş ve QTE]], [[Para Kazanma — Açık]]

## [2026-09-10] feature | Run host entegrasyonu — battle.gd RunManager'ı sürüyor (oynanır)
- Files changed: YENİ `scripts/rpg/run/run_content.gd`; DÜZENLENDİ `scripts/battle.gd` (tek-savaş → run host), `scripts/rpg/run/run_loadout.gd` (`available_skills` -> `Array[Skill]`), `tests/test_run_manager.gd` (+içerik entegrasyon testi).
- **`battle.gd` artık run host:** RunManager omurgasını sürer. BATTLE/BOSS'ta her RunLoadout'tan GEÇİCİ Character kurar (draft edilmiş `available_skills(catalog)` + run max HP), `TurnManager` ile savaşır; savaş bitince HP'yi loadout'a geri yazıp `report_battle_result(won)`. CHOICE'ta rün-draft/boost butonları gösterir (`_combo_hint`: seçtiğin rün bir birleşimi tamamlıyorsa "⚡AÇILIR!" ipucu) -> `apply_choice`. REWARD/bitiş -> kazanma/kaybetme ekranı. Her savaşta `tm` yeniden kurulur; CHOICE sırasında `tm=null` (gövde/minigame temizlenir).
- **HP taşıma:** `RunLoadout.current_hp` savaşlar arası taşınır (start_battle max_hp ile doldurduktan sonra Combatant.hp override edilir). Kazanınca düşen parti üyesi `REVIVE_FRACTION`=%25 ile dirilir (run soft-lock önleme, MVP). Tüm parti ölürse TurnManager `battle_ended(ENEMY)` -> `report_battle_result(false)` -> RUN_LOST.
- **`RunContent`:** demo bölüm (TestBattleData'nın run karşılığı) — katalog (ember/storm/frost/gale normal + Plazma/Fırtına combo), parti (skills BOŞ, base_runes kayra=ember/derin=frost), `[BATTLE,CHOICE]×2 -> BOSS -> REWARD(100)` (goblin / golem+wraith / Kül Ejderi).
- **Dikkat (Godot tip sistemi):** `Array` değişkeni tipli property'ye (`Array[String]`/`Array[Skill]`) atanmıyor — literal coerce olur, değişken olmaz. `_enemy` param tiplerini ve `available_skills` dönüşünü tipledim. Ayrıca yeni `class_name` -> global cache için `--headless --editor --quit` tarama şart.
- Test: **71/71 geçti** (+içerik entegrasyonu: hep-kazan + Kayra'ya storm draft -> RUN_WON, ödül 100). `run_project` ile sahne runtime TEMİZ (tek zararsız uyarı: `mini` built-in gölgeleme, değişiklik öncesinden var). → [[Turn-Based Savaş ve QTE]]

## [2026-09-10] feature | Run omurgası — roguelite bölüm akışı + rün draftı
- Files changed: YENİ `scripts/rpg/run/{run_node,stage_def,skill_catalog,run_loadout,choice_option,run_state,choice_generator,run_manager}.gd`, `tests/test_run_manager.gd`, `tests/run_tests.gd` (+TestRunManager).
- **Yön kararı (kullanıcı):** retention omurgası = Cup Heroes tarzı bölüm ilerleme (Last War şehir kurma REDDEDİLDİ — DNA'ya ters). Bölüm deseni: `[BATTLE, CHOICE]×N → BOSS → REWARD` → ana ekran → kalıcı güçlenme → tekrar.
- **Rün-draft modeli (kullanıcı seçti):** büyücüler bölüme temel rünle girer, CHOICE düğümlerinde rün DRAFT eder; kit her run sıfırlanır (roguelite). **Birleşim EMERGENT açılır:** bir büyücü kaynak çiftini toplarsa (ember+storm → Plazma, frost+gale → Fırtına) combo otomatik kite eklenir (`RunLoadout.available_skills`). RNG yalnız seçim katmanında (`ChoiceGenerator`, deterministik/seed'li) — çizim anı saf beceri.
- **Mimari:** `RunManager` saf/headless host-callback'li (TurnManager gibi, savaşı kendi sürmez): BATTLE/BOSS'ta düşman seti verir → host `report_battle_result(won)`; CHOICE'ta `current_choices()`/`apply_choice(i)`; REWARD terminal → para RunState'e. Kayıp → RUN_LOST. HP savaşlar arası taşınır (`RunLoadout.current_hp`). Meta katman (kalıcı para/açılan rünler) henüz YOK — ayrı katman, sonra.
- **Dikkat:** yeni `class_name`'ler global script cache'e kaydolmadan headless test parse hatası verdi; `Godot --headless --editor --quit` ile tarama gerekti. Test: `godot --headless -s res://tests/run_tests.gd` → **68/68 geçti** (46 savaş + 22 run omurgası). → [[Turn-Based Savaş ve QTE]]

## [2026-09-10] feature | Şarj barlı birleşim becerileri + kombo/füzyon motoru SİLİNDİ
- Files changed: DÜZENLENDİ `scripts/rpg/{skill,combatant,battle_config,turn_manager,test_battle_data,turn_debug_overlay,qte_minigame}.gd`, `scripts/battle.gd`, `scripts/core/rune_db.gd`, `data/combo_config.json`, `tests/{run_tests,test_turn_manager}.gd`. SİLİNDİ (tam): `scripts/main.gd`, `scenes/main.tscn`, `scripts/debug_overlay.gd`, `scripts/core/{combo_resolver,damage_rules,resolved_spell}.gd`, `tests/{test_resolver,test_state_machine,test_meters}.gd`, tüm `deprecated/` (chain_tracker/charge_meter/combo_state_machine/time_scale_controller + README).
- **Beceri modeli yenilendi (kullanıcı kararı):** strike kaldırıldı; her karakter 3 büyü = 2 rün-özel NORMAL + 1 BİRLEŞİM (ultimate). Birleşim yeni şekil GETİRMEZ — kaynak rünleri QTE'de PEŞ PEŞE çizilir (Plazma = ember→storm, Fırtına = frost→gale). Tümü doğru → normal skillerden BÜYÜK buff (`qte_bonus_multiplier` 2.5 vs 1.4–1.6).
- **Şarj barı (yeni sistem):** `Combatant.charge`/`charge_max` (varsayılan 100, `BattleConfig.charge_max`). Hasar VER + AL → miktar kadar dolar (vurana+yiyene). Dolunca birleşim seçilebilir (`select_action` şarjsız birleşimi reddeder); kullanınca sıfırlanır (başarısız olsa da tüketilir).
- **Durum sistemi (birleşim kimliği):** `Skill.dot_fraction` (Plazma yakma: hedef sonraki tur son hasarın %40'ını tekrar yer) + `Skill.applies_stun` (Fırtına: hedef bir tur atlar). İkisi de sıra BAŞINDA işlenir (`TurnManager._begin_turn`): önce `pending_dot` uygulanır (şarj da doldurur), sonra `stunned` turu atlatır. Yeni sinyaller: `dot_applied`, `stun_skipped`; `qte_started` artık sıradaki `rune_id`'yi taşır (dizi-QTE için adım adım yeniden emit).
- **Füzyon/kombo tamamen kaldırıldı:** `combo_config.json` sadece `runes` (4, strike yok) + `shape_to_rune`. `RuneDB`'den fusion/timeScale/pencere/şarj(eski)/overdrive/chain alanları + `fusion_for`/`time_scale_for`/`window_for` silindi. `TurnManager` füzyon iskeleti (`recent_effects`/`_push_effect`) ve `BattleConfig.enable_elemental_reactions` silindi. Eski gerçek-zamanlı motor menüden zaten erişilemiyordu (OYNA→battle.tscn).
- Test: `godot --headless -s res://tests/run_tests.gd` → **46/46 geçti** (eski 3 kombo suite silindi; turn-based + şarj/kilit/dizi-QTE/DoT/stun eklendi). → [[Turn-Based Savaş ve QTE]]

## [2026-09-10] feature | Turn-based RPG'ye dönüşüm — TurnManager + QTE
- Files changed: YENİ `scripts/rpg/{character,skill,enemy,combatant,battle_config,damage_breakdown,battle_damage,enemy_ai,turn_manager,turn_debug_overlay,test_battle_data}.gd`, `scripts/core/fake_recognizer.gd`, `scripts/battle.gd`, `scenes/battle.tscn`, `tests/test_turn_manager.gd`, `tests/run_tests.gd` (+TestTurnManager). TAŞINDI: `scripts/core/{combo_state_machine,charge_meter,chain_tracker,time_scale_controller}.gd` → `deprecated/` (+`deprecated/README.md`).
- Gerçek zamanlı dalga savunması → turn-based parti RPG. Rün çizimi KALIR ama artık beceri kullanılırken tetiklenen sınırlı süreli QTE (sürekli kombo değil). `TurnManager`: IDLE→SELECTING_ACTION→QTE→RESOLVING→NEXT_TURN, saf RefCounted, motor zamanı okumaz (`tick(unscaled_dt)`). Sıra `speed`'e göre (stabil, ATB yok). `EnemyAI` stub: en düşük HP hedefe en yüksek hasarlı beceri.
- İki ilke kodda: **fail-soft QTE** (başarısızlık saldırıyı iptal etmez, sadece bonusu kaybettirir — recognizer null→taban hasar) ve **hasar asla sıfır** (direnç ×0.5 ama max(1); zaaf ×1.5). `RuneDB`/`IRuneRecognizer` yeniden kullanıldı; `FakeRecognizer` eklendi (testlerde deterministik QTE). Faz 2 elementel reaksiyon iskeleti `BattleConfig.enable_elemental_reactions=false` arkasında kapalı.
- Menü OYNA butonu yeni savaşa bağlandı: `scripts/main_menu.gd` `GAME_SCENE = res://scenes/battle.tscn` (eski `scenes/main.tscn`). main_scene hâlâ menü; eski gerçek-zamanlı sahne referans olarak duruyor ama menüden erişilmiyor.
- `battle.gd`'ye savaşçı görselleri eklendi (`_build_bodies`/`_update_bodies`): her Combatant için kutu + isim/HP (parti sol mavi, düşman sağ kırmızı, aktif sıra parlak, ölen soluk). Demo başta gövde çizmiyordu — ekran boş görünüyordu (hata değil).
- **Yandan bakış + ortada QTE minigame** (kullanıcı isteği): karakterler SOL sütun, düşmanlar SAĞ sütun, orta boş. Yeni `scripts/rpg/qte_minigame.gd` (`QteMinigame`, Node2D): oyuncu sırasında ekranın ORTASINDA (`MINI_RECT` 260,680 560×560) açılır. Hedef rünün SOLUK ŞABLONU çizilir (`GUIDES`: ember=X, frost=O, gale=şimşek, storm=V, strike=çizgi — RecognizerAdapter şekilleriyle uyumlu) + başlangıç noktası işareti. Oyuncu parmakla takip ettikçe ELEMAN RENGİNDE canlı iz belirir (girdi görünür → "renk kazanır"). `battle.gd` çizim alanını alt-1/3 canvas'tan ortadaki minigame'e taşıdı; eski `RuneTrail` sahnede kullanılmıyor (dokunulmadı). Compile temiz, test 79/79.
- Test: `godot --headless -s res://tests/run_tests.gd` → **79/79 geçti** (56 eski + 23 yeni; sıra/QTE bonus/fail-soft/zaaf-direnç). Not: yeni class_name'ler için `godot --headless --import` bir kez çalıştırılmalı (global class cache). → [[Turn-Based Savaş ve QTE]]

## [2026-09-07] config | Yeni sürüm APK telefona kuruldu
- Files changed: `build/wizard_game.apk` (yeniden export, 27MB → 37MB), `build/wizard_game.apk.idsig`.
- Menü + dalga sistemi + okçu dahil güncel build export edildi (`--export-debug "Android"`, prebuilt yol, arm64-v8a, debug-signed). Boyut büyüdü: ana menü + Kenney UI assetleri eklendi.
- Telefona kuruldu (`adb install -r`, Xiaomi emerald/23117RA68G) ve launcher intent ile başlatıldı. Toolchain: Godot `~/Downloads/Godot.app`, JDK17 `/opt/homebrew/opt/openjdk@17`, Android SDK `/opt/homebrew/share/android-commandlinetools`, adb `platform-tools/adb`, keystore `~/.android/debug.keystore`.

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
