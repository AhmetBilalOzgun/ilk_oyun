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
code_anchors: []
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

## Open Questions

- Kombo penceresi süresi (bkz [[Rün Çizim Mekaniği]]).
- Kombo eşleşme tablosunun ilk seti (4 rün prototipinde hangi eşleşmeler).
