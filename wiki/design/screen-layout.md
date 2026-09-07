---
type: design
title: "Ekran Düzeni"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - design
  - ux
status: approved
domain: ux
related:
  - "[[Rün Büyücüsü — Konsept]]"
  - "[[Rün Çizim Mekaniği]]"
code_anchors: []
---

# Ekran Düzeni

**Karara bağlandı.**

## Layout

| Bölge | İçerik |
|---|---|
| Üst ~2/3 | Savaş alanı. Solda büyücü, sağdan düşman akını. |
| Alt orta | Çizim karesi. **Sabit konum, sabit ölçek.** İçi neredeyse boş. |
| Çizim karesinin solu | Rün paleti. Savaşa getirilen rünler. |

## Neden bu düzen

- Parmak savaş alanını kapatmıyor — girdi ve dünya mekânsal ayrıldı.
- Kare hep aynı yer + aynı boyut → oyuncu zamanla aşağı bakmadan çizer → **göz savaş alanında kalır** ("konuşurken oynanabilir").
- Sabit ölçek → tanıma doğruluğunda ciddi artış. Serbest ekrana çizmeye göre çok daha az hata.

## Kural

Karakter animasyonu çizim karesinin **içinde değil**, savaş alanında oynar. Mürekkebin arkasında hareket eden hiçbir şey olmamalı — hem tanımayı zorlaştırır hem görsel olarak yarışır.
