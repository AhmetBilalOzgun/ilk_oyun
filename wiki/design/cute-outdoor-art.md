---
type: design
title: "Tatlış Büyücüler ve Açık Hava Görsel Dili"
status: implemented
created: 2026-09-16
updated: 2026-09-16
verified: 2026-09-16
tags: [art, ui, rhythm, forms]
code_anchors:
  - repo: game
    symbol: GameLook.form_key
    file: scripts/ui/game_look.gd
  - repo: game
    symbol: RhythmMinigame._process
    file: scripts/rpg/rhythm_minigame.gd
  - repo: game
    symbol: RunContent.plasma_archetypes
    file: scripts/rpg/run/run_content.gd
  - repo: game
    symbol: TurnManager._apply_action
    file: scripts/rpg/turn_manager.gd
---

# Tatlış Büyücüler ve Açık Hava Görsel Dili

Kullanıcının 16 Eylül revizyonu: mevcut alev büyücüsünün sevimli, küçük ve okunur karakteri korunacak. Karanlık/korkunç, aşırı detaylı sanat yönü istenmiyor; 16×16 hissinde sade pixel art yeterli. Normal alev atlası ve animasyonu korundu; diğer yedi varyant ona referansla üretildi. Kaynak atlaslar gerçek 16×16 dosyalar değildir; büyük çözünürlüklü, iri pikselli raster çizimlerdir.

## İstenen görsel kimlikler

- Alev: normal, kritik (yıldız), yakma (küçük korlar), patlama (yuvarlak büyü).
- Plazma: normal, kritik (yıldız), patlama (pembe küre), kör eden (açık mint/krem ve güneş).
- Duruş, büyü, incinme, yenilgi, zafer ve büyük büyü animasyonları aynı sevimli karakter dilini taşır.
- Arketipler yalnız renklendirme yerine ayrı atlaslarla görünür. Mevcut İnfaz ailesi UI'da Kritik olarak adlandırılır; düşük canlı hedef bonusu ve can çalma davranışı korunur, yeni bir rastgele kritik sistemi eklenmez.

## Mekan ve arayüz

Beş açık hava mekanı: Papatya Köprüsü, Çiçek Bahçesi, Deniz İskelesi, Altın Yaprak Korusu, Pamuk Kar Vadisi. 20 bölüm dörderli görsel gruplar; endless yolculukta mekanlar dönüşümlü. Köprü yürüyüş yüksekliği her çizime göre ayarlanır.

Ana menü, mekan önizlemeli bölüm kartları, savaş butonları, karakter/ekipman ekranı krem yüzeyler ve koyu yazılarla yenilendi. Ekipman listesi kaydırılır. Mevcut ustalık/ödül toplama ve meta ilerleme korunur. Test kristal düğmesi hâlâ test düğmesidir; gerçek ödeme değildir.

## Ritim okunabilirliği

Yatay kayan şerit yerine ortada büyük tek hareket: ok veya daire içinde TAP. Hareket zamanına yaklaştıkça soluktan belirgine geçer; dış halka dolar, “ŞİMDİ” yazısı belirir. Sonraki hareketler altta küçük sırada durur. Jest sadece büyük aktif harekete uygulanır; hızlı tempoda zaman pencereleri çakışsa bile kuyruktaki hareket seçilmez. Erken giriş bekler, yanlış yön/gecikme komboyu kırar. Mevcut uyarlanabilir hız ve taban hasar korunur.

## Kör eden plazma

Kullanıcının istediği olasılık tam %35: her düşman saldırısında bir kez sınanır. Iskalayan saldırı hasar, yanma, sersemletme, yansıma veya şarj üretmez. Oyuncunun ritim ıskası bundan ayrıdır; oyuncunun taban hasarı devam eder.

Dönüşüm sırasında seçili aile korunur: alev yakma ailesi plazmada kör etme varyantına geçer. Kritik ve patlama aileleri kendi plazma varyantına geçer. Eski kayıtların ustalık aile kimlikleri korunur; aynı açılış hem alev hem plazma varyantını sunabilir. Bu eşleme, sekizli istenen form listesini mevcut dışlayıcı arketip sistemiyle birleştiren uygulama kararıdır.

Eski goblin/ejder/dev atlaslarının gövdelerindeki şeffaflık delikleri de yeni açık zeminlerde okunabilirlik için onarıldı; eski PNG kaynakları korundu.

## Doğrulama ve kaynaklar

Headless suite; kör etme olasılığı ve yan etkileri, dönüşümde aile taşıma, sekiz atlas ve beş mekan kaynak kontrolü. Gerçek Metal renderer ile ana menü/bölüm/ekipman/savaş/form galerisi ve ritim soluk-belirgin-ok ekran görüntüleri. Erken/yanlış/geç jest ve çakışan pencereler ayrıca sınanır. Gerçek telefonda parmakla his/timing kontrolü yapılmadı.

Görseller built-in imagegen ile üretildi; promptlar `docs/art/revision-prompts.md`, assetler `assets/worlds/`, `assets/wizard/forms/`. Görsel QA: `output/visual-revision/`. Bkz [[Turn-Based Savaş ve QTE]].

Android debug APK üretildi ve imza doğrulaması geçti. Headless kontroller: 2037 başarılı / 0 başarısız; Metal renderer son doğrulaması hatasız. Ortam kaynaklı CA sertifikası ve önceden var olan test kapanış kaynak uyarıları headless logunda sürüyor.
