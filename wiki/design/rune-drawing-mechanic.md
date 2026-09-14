---
type: design
title: "Rün Çizim Mekaniği"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-12  # skorlama toleransı MAX_DIST 0.60; gizli çapa grid snap + strike standalone
tags:
  - design
  - mechanic
  - deprecated
status: deprecated
verified: 2026-09-13  # ÇİZİM/QTE KALDIRILDI — bu sayfa tarihsel
domain: mechanic
related:
  - "[[Ekran Düzeni]]"
  - "[[Kombo ve Palet]]"
  - "[[Loadout Kısıtı]]"
  - "[[Çizim Tanıma — $1 Recognizer]]"
code_anchors:
  - repo: game
    symbol: RecognizerAdapter.classify_shape
    file: scripts/recognizer_adapter.gd
  - repo: game
    symbol: ComboStateMachine.on_finger_up
    file: scripts/core/combo_state_machine.gd
---

# Rün Çizim Mekaniği

> [!warning] TARİHSEL — KALDIRILDI (2026-09-13)
> Rün çizimi ve QTE **tamamen kaldırıldı** ("çizime baybay"; kullanıcı). Combat
> artık tap-to-cast; recognizer/rune_templates/qte_minigame/rune_trail dosyaları
> silindi. Bu sayfa yalnızca tasarım geçmişi olarak durur. Güncel model:
> [[Turn-Based Savaş ve QTE]].

Çizim mekaniği, dokunmadan **yapısal olarak daha ağır**: hatırlama ister, tanıma değil. Aşağıdaki kararlar bu bilişsel yükü **sabit** tutmak için var.

## Bilişsel yükü kontrol eden 4 karar

1. **Loadout** — 40 rün kodekste, savaşa 4'üyle girilir. Yük sabit, koleksiyon büyür, rün seçimi meta katman olur (deste kurma). → [[Loadout Kısıtı]]
2. **Çizerken önizleme** — parmak ekrandayken oluşan rün soluk belirir. Oyuncu parmağını kaldırmadan ne çıkacağını görür → hamle öncesi telegraf + tanıma hatası korkusu sıfırlanır.
3. **Sessiz başarısızlık yok** — sistem asla "anlaşılmadı" demez. Her çizgi en yakın rüne yuvarlanır; hiçbir şeye benzemiyorsa **düz vuruşa** düşer. "Oyun beni anlamadı" hissi hiç yaşanmaz. → [[Sessiz Başarısızlık Yok]]
4. **Rün formu kısıtları:**
   - En fazla 2–3 çizgi.
   - Köşeli, açısal formlar (başparmak dikey ekranda karmaşık eğri çizemez).
   - Silüet olarak birbirine benzemeyen formlar.
   - İlk 20 dk tanıma toleransı gizlice çok geniş, sonra yavaşça daralır.

## Çizim tanıma — ham iz (snap YOK) (verified 2026-09-07)

Çapa/snap sistemi **denendi ve kaldırıldı** (kötü his). Tanıma doğrudan ham parmak izinde: `RecognizerAdapter.classify_shape` resample + köşe/kesişim geometrisiyle line/X/O/V/lightning ayırır. Görünen iz de ham/akıcı (`RuneTrail`, `draw_polyline`). Tek çizim kendini keserse X. → [[Çizim Tanıma — $1 Recognizer]]

## Doğruluk skorlaması — tolerans (verified 2026-09-12)

Kimlik (hangi rün) `RecognizerAdapter`'da; **özen/doğruluk** ayrı katman: `RuneTemplates.score` ($1 ruhu, normalize + şablon eşleme). Skor `= 1 - dist/MAX_DIST`. `MAX_DIST` tolerans eğiminin eğimidir — büyütmek doğru-şekil özensiz çizimi ödüllendirir, yanlış şekli değil (o ayrıca `COUNT_PENALTY` stroke-sayısı cezasıyla korunur). **2026-09-12:** `MAX_DIST` 0.40 → 0.60 (kullanıcı: tolerans çok düşük). Headless ölçüm: %12-16 parmak titremesi 0.53-0.79 → 0.68-0.86; yanlış şekil hâlâ ~0.06-0.11.

## Düz vuruş (temel saldırı) — tık, standalone (verified 2026-09-07)

Çizim alanına **tık** (kaydırma değil) = düşük hasarlı düz vuruş, **anında** (parmak kalkınca bekleme yok). Tanınmayan her karalama + çizilen düz çizgi de buraya düşer. Üç iş birden:

1. **Ritim** — büyük büyüler arasında ölü zaman kalmaz.
2. **İlk hamle kazandırır** — yeni oyuncuya ilk saniyeden %100 başarılı eylem.
3. **Başarısızlık tabanı** — tanınmayan her karalama buraya yuvarlanır.

**Denge riski:** çok güçlü → spam; çok zayıf → dekor.

**Karar (değişti 2026-09-07):** strike artık komboyu **taşımaz** — **standalone** sabit taban hasar. Neden: peş peşe tık depth'i artırıp hasarı katlıyordu (kombo istismarı) ve strike'ın açtığı pencere/yavaşlama sonraki çizimi yanlışlıkla 2. kombo vuruşu yapıyordu. Strike artık pencere açmaz, depth'i artırmaz, süren komboyu da bozmaz. Sadece gerçek rünler (ember/frost/gale/storm) zincirlenir. → `ComboStateMachine.on_finger_up`

## Player Experience Goal

Oyuncu tanıma hatasından korkmadan, akış hâlinde şekil üretir.

## Open Questions

- Kombo penceresi süresi.
- Tolerans daralma eğrisinin tam şekli.
