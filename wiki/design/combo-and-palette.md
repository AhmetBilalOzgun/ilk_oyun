---
type: design
title: "Kombo ve Palet"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - design
  - system
status: approved
domain: system
related:
  - "[[Rün Çizim Mekaniği]]"
  - "[[Juice ve Geri Bildirim]]"
code_anchors:
  - repo: game
    symbol: ComboResolver.resolve
    file: scripts/core/combo_resolver.gd
  - repo: game
    symbol: ComboStateMachine
    file: scripts/core/combo_state_machine.gd
  - repo: game
    symbol: RuneDB
    file: scripts/core/rune_db.gd
  - repo: game
    symbol: DebugOverlay
    file: scripts/debug_overlay.gd
---

# Kombo ve Palet

## Sorun

"Ateş + rüzgar = alev fırtınası" ekranda görünmeyen bir kuraldır. Oyuncu ya wiki'den öğrenir ya hiç öğrenmez; gerçekte işe yarayan tek komboyu bulup oyunun geri kalanını onu tekrarlayarak geçirir.

## Çözüm — palet aynı zamanda kombo öğretmeni

İlk rün tamamlandığı anda, onunla eşleşen rünler palette **parlar**. Sistem kendini oynarken öğretir.

## Palet solması (ustalık hissi)

Bir rün **10 kez** başarıyla çizildikten sonra palet o rünün çizgi yolunu göstermeyi bırakır — sadece ikon + renk kalır. Oyuncu bir gün artık bakmadığını fark eder. Maliyeti sıfır olan ustalık anı.

## Player Experience Goal

Kombo sistemi kendi kendini öğretir; ustalık görünür ama ödülsüz değil, sessizce kazanılır.

## Uygulama (2026-09-07)

Kombo çekirdeği kodlandı — bkz `code_anchors`. Prensipler:

- **İki katman:** çekirdek saf `RefCounted` (motor zamanı okumaz, `unscaled_dt` alır → headless test). Motor adaptörü `main.gd` girdi + `Engine.time_scale` uygular.
- **Zaman:** kombo/pencere/casting/overdrive süreleri duvar saatinden (`Time.get_ticks_usec`) ölçülür — `Engine.time_scale`'den bağımsız. Dünya yavaşlarken pencere yavaşlamaz (çift avantaj çökmesi yok).
- **Birleştirme (elle değil, kurallardan):** taşıyıcı = ilk rün; etkiler union + füzyon tablosu (ör. Burn+Freeze→Steam); hasar = taban × 1.6^(ek rün). Zıt rünler iptal etmez.
- **Strike** = tanınmayan çizim tabanı (recognizer null → strike), etkisiz ama komboyu taşır.
- **Overdrive** aynı resolver'ı kullanır (ayrı kod yolu yok): biriken rünler tek çıktı + hasar çarpanı.
- **Tuning** `data/combo_config.json`'da: rün seti, füzyon, timeScale merdiveni, pencere merdiveni, şarj, overdrive, zaaf çarpanı. Prototipte buradan ayarlanır.

## Open Questions

- Palet parlaması/solması UI'ı henüz yok (bu iş çekirdek + overlay; palet görseli sonra).
- 4 rün prototipinde nihai füzyon eşleşme seti (şu an 2 girdi: Burn+Freeze→Steam, Push+Shatter→Vacuum).
