---
type: design
title: "Rün Büyücüsü — Konsept"
created: 2026-09-07
updated: 2026-09-07
verified: 2026-09-07
tags:
  - design
  - concept
status: approved
domain: system
related:
  - "[[Ekran Düzeni]]"
  - "[[Rün Çizim Mekaniği]]"
  - "[[Kombo ve Palet]]"
  - "[[Düşman Tasarımı]]"
  - "[[Prototip M0]]"
code_anchors: []
---

# Rün Büyücüsü — Konsept

## Summary

Dikey, 2D, dalga tabanlı savunma oyunu. Oyuncu ekranın altındaki **sabit bir kareye** parmağıyla rün şekilleri çizer; en soldaki büyücü karakter o büyüyü sağdan gelen düşmanlara fırlatır. Rünler zincirlenerek kombolara dönüşür.

**Karara bağlandı** (2026-09-07): Oyun fikri onaylandı, demo/prototip yapılacak.

## How It Works

- Girdi = üretim, seçim değil. Oyuncu bir şekil çizer → büyücü onu fırlatır.
- Kodekste ~40 rün olabilir; savaşa **4 tanesiyle** girilir (bkz [[Loadout Kısıtı]]).
- Rünler birbiriyle eşleşerek kombo yapar (bkz [[Kombo ve Palet]]).

## Player Experience Goal

- "Konuşurken oynanabilir" — göz savaş alanında kalır, aşağı bakmadan çizilebilir.
- "Ben yaptım" hissi — girdide faillik var, seçim onaylamak değil şekil üretmek.
- Reklam = oynanış. Ekranda şekil çizilir, bir şey patlar. Sessiz, dilsiz, 6 saniyede anlaşılır.

## Strengths (fikrin güçlü tarafları)

- Reklam ile oynanış aynı şey → düşük kullanıcı edinim maliyeti, kreatif-oynanış tutarlılığı.
- Girdinin kendisinde faillik → dokunmayla zor elde edilen "ben yaptım" hissi.
- Üretim ekonomisi lehte → içerik maliyeti lineer, algılanan içerik kombinatoryal (10 rün → 50 kombo). Sanat yönü ucuz (koyu zemin, akkor çizgi, silüet), küçük indirme + düşük cihaz uyumlu.

## Risks (zayıf taraflar)

- **Çizim süresi ölü zaman** — bir rün 0.5–1.5 sn; o sürede dünya devam eder (ilk 5 savaş hariç, yavaşlama efekti). Oyuncu kör olduğu anda cezalanır.
- **Asıl risk D1 değil D7** — çizim tanıdıkça ödülü azalan bir girdi. Test edilen yenilik, ölçülen tekrar. Prototip bunu ölçmeli (bkz [[Prototip M0]]).
- **Fiziksel yorgunluk** — başparmakla 20 dk çizmek dokunmaktan yorucu. Oturum tavanı → gelir tavanı.
- **Beceri ↔ para kazanma çelişkisi** — beceri önemliyse ödeme ilerletmez; ödeme ilerletirse beceri önemsizleşir. En ciddi ticari zayıflık, **çözülmedi**.
- **İlk "vay" anı erken harcanır** — swarm'ı tek büyüyle silmek harika açılış ama ölçek yukarı gitmeli → kutlama enflasyonu, juice bütçesi riski.

## Open Questions

- Para kazanma modeli — bkz [[Para Kazanma — Açık]].
- Uzun vadeli çekim sebebi (2. oynanış sebebi) — düşünülmedi.
- 50. dalgada kutlama ölçeği.
- Kombo penceresi süresi.
- Uzun vadeli dönüşüm/retention planı — **karar yok, tahmin üretme.**
