---
type: design
title: "Rün Çizim Mekaniği"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - design
  - mechanic
status: approved
domain: mechanic
related:
  - "[[Ekran Düzeni]]"
  - "[[Kombo ve Palet]]"
  - "[[Loadout Kısıtı]]"
  - "[[Çizim Tanıma — $1 Recognizer]]"
code_anchors: []
---

# Rün Çizim Mekaniği

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

## Düz çizgi (temel saldırı)

Tek basit jest = düşük hasarlı düz vuruş. Üç iş birden:

1. **Ritim** — büyük büyüler arasında ölü zaman kalmaz.
2. **İlk hamle kazandırır** — yeni oyuncuya ilk saniyeden %100 başarılı eylem.
3. **Başarısızlık tabanı** — tanınmayan her karalama buraya yuvarlanır.

**Denge riski:** çok güçlü → spam; çok zayıf → dekor.

**Önerilen çözüm (hasarda değil işlevde):** düz çizgi komboyu **taşısın**. rün → çizgi → rün zinciri kombo penceresini kırmadan devam etsin. Dolgu olmaktan çıkıp ritim mekaniğine döner.

## Player Experience Goal

Oyuncu tanıma hatasından korkmadan, akış hâlinde şekil üretir.

## Open Questions

- Kombo penceresi süresi.
- Tolerans daralma eğrisinin tam şekli.
