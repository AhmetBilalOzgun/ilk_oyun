---
type: report
title: "Rün Büyücüsü - Kârlılık ve Ticari Fizibilite Raporu"
status: analysis
created: 2026-09-15
updated: 2026-09-15
verified: 2026-09-15
tags: [profitability, strategy, economy, mobile, research]
---

# Rün Büyücüsü
## Kârlılık ve Ticari Fizibilite Raporu

**Ahmet Bilal Özgün için | 15 Eylül 2026**

**Karar önerisi: Sınırlı bütçeyle doğrulamaya devam et. Büyük içerik yatırımı ve ücretli büyüme için henüz yeterli kanıt yok.**

Bu proje, küçük bir geliştirici ekibinin sınayabileceği bir mobil oyun fırsatı taşıyor. Ritimle büyü yapma, form değiştirme ve koşu içinde karakter geliştirme aynı üründe anlaşılır biçimde birleşirse oyuncuya farklı bir deneyim sunabilir. Ancak bugün kârlılığın önündeki asıl engel oyun motoru veya özellik sayısı değil: oyuncunun geri dönmesi, para harcamak istemesi ve edinilme maliyetinden daha fazla gelir üretmesi henüz ölçülmedi.

**Önemli ayrım:** Çalışan mekanik, oyuncuların sevdiği ürün ve kârlı işletme üç ayrı aşamadır. Proje ilk aşamada anlamlı ilerleme kaydetmiş; son iki aşama henüz doğrulanmamıştır.

### Yönetici özeti

| Soru | Değerlendirme |
|---|---|
| Bu oyundan para kazanılabilir mi? | Evet, mümkün. Eldeki kanıt kâr tahmini veya başarı olasılığı vermeye yetmiyor. |
| Mevcut sürüm para kazanmaya hazır mı? | Hayır. Gerçek ödeme, reklam ve oyuncu ölçümü entegrasyonu bu depoda bulunmadı. |
| En güçlü ticari yön | Ritim girdisinin doğrudan büyü etkisine dönüşmesi ve görünür form değişimi. |
| En ciddi ürün riski | Ayırt edici build deneyimine erişimin geç, rastlantısal ve dönüşüm sırasına bağlı olması. |
| En ciddi ekonomi riski | Kristalin yalnız altına dönüşmesi; tekrarlı bölüm ödüllerinin ve ucuz ekipmanın satın alma gerekçesini zayıflatması. |
| Önerilen ilk model | Ücretsiz giriş, isteğe bağlı ödüllü reklam, küçük ve açık içerikli satın almalar. |
| Şimdi yapılacak yatırım | 4-6 haftalık ilk doğrulama dönemi; örnek 1.200 USD nakit tavanı ve 80-120 saat emek. |
| Sonraki yatırımın koşulu | Gerçek oyuncu geri dönüşü, cihaz kalitesi ve aynı pazarda pozitif oyuncu başı ekonomi. |

**Finansal örnek:** Tamamı ücretli edinilen 100.000 kurulum, zayıf senaryoda yaklaşık **23.146 USD**, orta senaryoda **34.249 USD zarar**; güçlü senaryoda **31.838 USD pozitif katkı** üretir. Bunlar 90 günlük kullanıcı kohortu hesaplarıdır. Sabit işletme giderleri, geliştirme yatırımı ve gelir/kurumlar vergisi ayrıca düşülür. Güçlü senaryo bir satış tahmini değildir.

### Okuma sırası

1. İncelemenin kapsamı ve kanıt düzeyi
2. Mevcut ürün ve ticari konumu
3. Pazar ve rekabet
4. Kârlılığı etkileyen proje bulguları
5. Gelir modeli ve fiyat denemeleri
6. Birim ekonomi ve satış senaryoları
7. Aylık gelir hedefleri ve nakit ihtiyacı
8. Geliştirme bütçesi ve fırsat maliyeti
9. Ölçüm ve doğrulama planı
10. Önceliklendirilmiş yol haritası
11. Alternatif iş modelleri ve nihai karar
12. Kanıt dizini, kaynaklar ve sınırlamalar

## 1. İncelemenin kapsamı ve kanıt düzeyi

### Neler incelendi?

Projenin wiki kataloğu, güncel bağlamı, ilk ham tasarım notları, konsept ve mekanik belgeleri, para kazanma kararı, arketip kararı, mastery ve makro yol haritası, teslimat notları ve yakın dönem değişiklik kayıtları incelendi. Kod keşfi mevcut codebase-memory grafiği üzerinden yapıldı. Ekonomi, içerik kataloğu, seçim üretimi, form değişimi, savaş çözümü, ritim girdisi, kayıt sistemi ve ana ekran akışları kaynak kod üzerinden ayrıntılı değerlendirildi. Proje ve Android dışa aktarma ayarları ayrıca okundu.

Bu çalışma satır satır eksiksiz bir güvenlik denetimi veya tüm cihazlarda oyun testi değildir. Değerlendirme ticari sonuca etkisi yüksek sistemlerde derinleşir. Eski tasarım niyeti, mevcut uygulama ve geleceğe yönelik öneri ayrı tutulmuştur.

**İncelenen sürüm:** `8982279f954a4bd14b985542156e1df89e9f2933`. İnceleme başında oyun kodunda takip edilen yerel değişiklik yoktu; `AGENTS.md` ve `.codex/` takip edilmeyen öğelerdi. Hazır Android APK yaklaşık 38 MiB idi; dosyanın varlığı, güncel kaynakla aynı sürüm olduğunu veya mağazada yayımlandığını kanıtlamaz.

### Doğrulama sonucu

Godot 4.7.2 ile mevcut headless test çalıştırıcısı yeniden çalıştırıldı: **7 test grubu, 253 başarılı kontrol, 0 başarısız kontrol**. Çıkış kodu 0. Bunun yanında macOS sertifika okuma hatası ve çıkışta 6 ObjectDB örneği / 1 kaynak kullanım uyarısı görüldü. Sonuç “tüm çalışma ortamı hatasız” şeklinde yorumlanmamalıdır. Bu testler reklam, gerçek ödeme, dokunmatik kullanılabilirlik veya oyuncu geri dönüşünü ölçmez.

### Rapordaki dört bilgi türü

| İşaret | Anlamı |
|---|---|
| Kod bulgusu | İncelenen kaynakta doğrudan görülen davranış veya ayar. |
| Dış veri | Kaynağı ve dönemi belirtilmiş pazar veya platform bilgisi. |
| Çıkarım | Kod ve tasarımdan hareketle beklenen ticari etki; oyuncu testi gerektirir. |
| Varsayım / öneri | Finansal hesap veya deney tasarımı için bu raporda seçilmiş değer; proje kararı değildir. |

**Eksik işletme verileri:** Hedef ülke dağılımı, aktif kullanıcı, D1/D7/D30 geri dönüşü, oturum süreleri, satın alan oranı, gerçek reklam geliri, edinim maliyeti, harcanan toplam emek ve bütçe sağlanmadı. Bu yüzden rapor Android öncelikli, tek geliştiricili başlangıcı esas alır; tüm parasal hesaplar USD ile gösterilir. TL kuru ve kişisel vergi durumu varsayılmaz.

## 2. Mevcut ürün ve ticari konumu

### Bugün satılabilecek fikir

**“Doğru anda dokunup kaydırarak büyü yap; topladığın güçlerle büyücünü değiştir ve bir sonraki koşuda farklı bir oyun tarzı dene.”**

Bu tanım mevcut yönü ilk rün çizimi fikrinden daha doğru yansıtır. Kodda serbest rün çizimi üzerinden çalışan bir oyun bulunmuyor. Mevcut döngü: savaşta beceri seçimi, kısa ritim dizisi, büyü geri bildirimi, orb toplama/çoğaltma, kart seçimi, rota ve kalıcı ilerleme.

### Ürün envanteri

| Katman | Mevcut kod bulgusu | Ticari anlamı |
|---|---|---|
| Platform | Godot/GDScript; dikey 1080×1920 temel görünüm; Android export ayarı | Android'de doğrulama yapmak mevcut yatırımı kullanır. |
| Karakter | Bir başlangıç büyücüsü: Kor | Karakter ekranı çok karakterli içerik genişliği anlamına gelmez. |
| Form | Kor ve Plazma; tek dönüşüm yolu | Güçlü bir erken gösteri anı var; uzun vadeli keşif genişliği sınırlı. |
| Savaş | Temel büyü, ultimate, şarj, yakma, sersemletme, direnç/zaaf | Kısa vadeli taktik ve geri bildirim için yeterli prototip temeli. |
| Aktif girdi | Rastgele tap/swipe ritim dizisi; 2-6 notalık kombo | Farklılaşma adayı; tekrar ve parmak yorgunluğu riski. |
| Koşu | Dallanan rota; savaş, elit, dinlenme, hazine, boss | Tek içeriği farklı kararlarla yeniden kullanabilir. |
| İçerik | 20 seviye; 6 normal düşman arketipi; 5 boss profili | Sayısal bölüm sayısı, 20 ayrı oynanış deneyimi demek değildir. |
| Build | Kor için 3 arketip; 8 relic; 9 ekipman / 3 slot | Deney yapılabilir; sınırsız içerik veya olgun bir koleksiyon ekonomisi değil. |
| Kalıcı ilerleme | Altın, kristal, can/hasar yükseltmeleri, 7 basamaklı mastery | Retention için araçlar var; etkileri ölçülmemiş. |
| Endless | Genişleyen harita, ölümde altın aktarımı, yerel en iyi derinlik | Yeniden oynama alanı sunar; tek başına uzun ömür garantilemez. |
| Ticaret/ölçüm | Kristal alma test düğmesi; üretim reklam/IAP/analitik akışı bulunmadı | Mevcut projeden doğrulanmış gelir hesabı çıkarılamaz. |

**Konumlandırma önerisi:** Kısa oturumlu, büyü temalı, aktif girdili bir hybrid-casual roguelite. “Hybrid-casual” burada kolay giriş ile daha derin ilerlemeyi birleştiren mobil oyun yaklaşımını anlatır; hem reklam hem satın alma denenebilir. Henüz bir pazar kategorisi başarısı iddiası değildir.

Başlangıç hedef kitlesi için “20-60 yaş herkes” fazla geniştir. Test edilecek ilk çekirdek: tek elle oynanan büyü/roguelite oyunlarına aşina, kısa oturum isteyen ve dokunma-kaydırma girdisini rahat kullanan oyuncular. Daha düşük refleks hızına sahip oyuncular ayrı bir test grubu olmalı. Campaign'in adaptif ritmi ve endless'ın hız baskısı farklı ihtiyaçlara hizmet ediyor.

## 3. Pazar ve rekabet

### Talep var; erişim otomatik değil

En yakın örnek **Cup Heroes**. Google Play sayfasında VOODOO yayıncısı, reklam ve uygulama içi satın alma, 10 milyon üzeri Android indirme görünür. Bu, savaş + top çoğaltma + seçim döngüsünün geniş kitleye ulaşabildiğine işaret eder. İndirme eşiği toplam geçmiş kurulumdur; aktif kullanıcı, gelir, kâr veya bağımsız geliştiricinin beklenen sonucu değildir. [Cup Heroes mağaza kaydı](https://play.google.com/store/apps/details?hl=en_US&id=com.studio501.cuphero)

| Referans | Gözlenen pazar sinyali | Bu proje için çıkarım |
|---|---|---|
| Cup Heroes | 10M+ Android indirme; reklam + IAP; yakın savaş/çoğaltma örneği | Orb kısmında anlaşılabilirlik avantajı; benzerlik nedeniyle ayırt edici ritim ve büyü kimliği gerekli. |
| Archero 2 | Habby; 5M+ Android indirme; reklam + IAP; çoklu mod ve etkinlikler | İlerleme ve tekrar oynama beklentisi yüksek; içerik hacmi yarışına girmek pahalı. |
| Magic Survival | leme; 5M+ Android indirme; büyü teması, tek elle kontrol; reklam + IAP | Büyü fantezisi ve nispeten odaklı kontrol düzeni de kitle bulabilir. |

Archero 2 ve Magic Survival bilgileri resmi mağaza kayıtlarından alınmıştır; rakiplerin gelirleri bu çalışmada doğrulanmamıştır. [Archero 2](https://play.google.com/store/apps/details?hl=en_US&id=com.xq.archeroii), [Magic Survival](https://play.google.com/store/apps/details?gl=gb&hl=en-GB&id=com.vkslrzm.Zombie)

Cup Heroes'ın mağaza sayfasında ilerleme baskısı ve reklam yoğunluğundan yakınan yorumlar da görünür. Bu yorumlar temsili araştırma değildir; yalnızca test edilecek bir konumlandırma fikri verir: kısa oturum, anlaşılır ödül, kontrollü reklam. Bir rakibin eleştirilen yanını hafifletmek, tek başına oyuncunun oyun değiştireceğini kanıtlamaz.

### Retention çıtası

GameAnalytics'in 2026 raporu, 2025 takvim yılı verisinde 16.000'den fazla mobil oyunu inceler; örneklem en az 1.000 aylık aktif kullanıcı eşiğini kullanır. Mobil medyan D1 yaklaşık %22, D7 %4'ün biraz altındadır. En iyi %10'da D1 yaklaşık %40, D7 yaklaşık %11-12 görünür. Bunlar bütün türler ve iki platformu birleştiren değerlerdir; bu oyun için tahmin değildir. Tür kırılımı bu raporda yoktur. [GameAnalytics 2026 raporu](https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks)

Çıkarım: Sadece “ortalama bir mobil oyun kadar iyi” olmak, ücretli reklamla büyümeyi güvenli kılmayabilir. Bu nedenle ileride önerilen %35 D1 / %12 D7 hedefleri temkinli yatırım kapılarıdır; evrensel başarı standardı değildir.

### Gelir ve dağıtım yapısı

AppsFlyer'ın 2024 monetizasyon araştırmasında Android mid-core örnekleminde hibrit modeller daha yüksek D90 ROAS göstermiştir. Bu ilişki, aynı oyuna reklam eklemenin kârı nedensel olarak artıracağını kanıtlamaz. Reklam ve ödeme birlikte, oyuncu geri dönüşünü bozmadan çalışmalıdır. [AppsFlyer monetizasyon raporu özeti](https://www.appsflyer.com/company/newsroom/pr/app-monetization-report/)

Appodeal'in 2025 eCPM raporu **Ekim-Aralık 2024** verisini kullanır. Ödüllü video, interstitial ve banner arasında; ayrıca ülke ve platformlar arasında ciddi farklar bildirir. Bu eski ve mevsimsel örneklem, 2026 Türkiye eCPM tahmini olarak kullanılmamıştır. Finansal bölümdeki eCPM değerlerinin tamamı test varsayımıdır. [Appodeal eCPM raporu](https://appodeal.com/wp-content/uploads/2025/03/Appodeal-The-Latest-eCPM-Report-2025.pdf)

AppsFlyer'ın 2025 kreatif çalışmasında oyun reklamlarının en üst %2'si toplam harcamanın %53'ünü alır. Örneklem 1,1 milyon kreatif varyasyonu ve en az 200 varyasyonu olan uygulamalara dayanır. Küçük geliştirici için ders: tek video hazırlayıp sürekli çalıştırmak yerine farklı vaatleri sınırlı bütçeyle sınamak gerekir. Büyük yayıncıların üretim hacmini taklit etmek gerekmez. [AppsFlyer kreatif raporu](https://www.appsflyer.com/resources/reports/creative-optimization-report-2025/)

### Pazar seçimi

İlk Türkçe kullanılabilirlik testi yakın çevreden yapılabilir. Ancak arkadaşların katılımı gerçek pazar retention'ı sayılmamalıdır. Sonraki testte İngilizce sürümle, hedeflenen ülkelerde bağımsız oyuncu kohortu gerekir. Daha ucuz edinim görülen bir ülkedeki CPI ile başka ülkenin yüksek reklam gelirini aynı modelde birleştirmek hatalıdır. Her ülke + işletim sistemi + edinim kaynağı için ayrı LTV/CPI tutulmalıdır.

## 4. Kârlılığı etkileyen proje bulguları

### 4.1. Arketipler oyuncuya erken ve güvenilir biçimde ulaşmıyor

**Kod bulgusu:** Campaign'de arketip teklifleri yalnız 4, 8, 12, 16 ve 20. seviyelerde açıktır. Arketip ayrıca mastery ile açılmış olmalı, ana ekrandan alınmalı ve o koşuda başka arketip seçilmemiş olmalıdır. Üstelik mevcut arketip kataloğu yalnız Kor formuna bağlıdır. Plazma'ya önce dönüşen oyuncuya henüz seçilmemiş arketip sunulmaz. Önceden seçilen arketip ise form değişince loadout üzerinde kalır.

Seçim üretiminde uygun dönüşüm bir slotu, yardımcı seçenek son slotu alır. Geriye arketip ve relic'lerin karıştığı **bir slot** kalır. Hiç relic alınmamış ve yalnız ilk arketip açılmışsa bu slotta arketip görme olasılığı **1/9, yaklaşık %11,1**; üçü de açıksa **3/11, yaklaşık %27,3** olur. Bunlar bu belirli havuz durumunun matematiğidir; tüm koşu boyunca arketip edinme oranı değildir. Orb yetmesi ve oyuncunun seçimi ayrıca gerekir. [Seçim üretimi](../scripts/rpg/run/choice_generator.gd), [İçerik kataloğu](../scripts/rpg/run/run_content.gd), [Form taşıma](../scripts/rpg/run/run_loadout.gd)

**Ticari çıkarım:** “Her koşuda farklı build keşfet” vaadi, ilk oyuncunun gördüğü ürünle örtüşmeyebilir. İçerik zaten yapılmışken oyuncuya göstermemek, üretim yatırımının getirisini düşürür.

**Öneri:** Yeni bir büyük sistem eklemekten önce, ilk koşuda geçici ve öğretici arketip denemesi tasarla. Kalıcı açılma korunabilir. Dönüşüm ile arketip sırası anlaşılır olmalı; garanti edilmiş bir karar anı ile mevcut rastlantısal teklif karşılaştırılmalı. Bu, mevcut cadence kararına önerilen bir deneydir; onaylanmış tasarım değişikliği değildir.

### 4.2. Kristal ekonomisinde satın alma gerekçesi zayıf

**Kod bulgusu:** 1 kristal = 100 altın. Can artışı +15 ve hasar artışı +4. Sıradaki can yükseltmesi 50×(mevcut seviye+1), hasar yükseltmesi 75×(mevcut seviye+1) altın. Campaign zaferi 80+40×seviye_indeksi altın ve 1+floor(seviye_indeksi/5) kristal verir. Zafer ödülünde “yalnız ilk tamamlamada” kontrolü bulunmuyor. [Meta ekonomi](../scripts/meta/meta_progress.gd), [Koşu sonu](../scripts/battle.gd:493)

| Örnek | Koddan hesaplanan değer | Ekonomik yorum |
|---|---|---|
| 1. seviye zaferi | 80 altın + 1 kristal = 180 altın eşdeğeri | Erken ödül güçlü; aynı bölüm tekrarlandıkça kristal de üretilebilir. |
| İlk can + ilk hasar yükseltmesi | Toplam 125 altın | İlk zafer iki yükseltmeyi karşılayabilir. |
| 9 ekipmanın toplam katalog bedeli | 1.130 altın | Harcama alternatifi sınırlı; hepsini almak için uzun bir ekonomi gerekmiyor. |
| İlk seviyenin 7 zaferi | 1.260 altın eşdeğeri | Dönüştürme yapılıp başka harcama yapılmazsa tüm katalog bedelini aşar; süre bilinmiyor. |
| 20 seviyeyi birer kez kazanma | 9.200 altın + 50 kristal = 14.200 altın eşdeğeri | Mastery ödülleri hariç; tamamlamanın zorluğu ve zamanı ölçülmedi. |
| Her iki yükseltmeyi 10. seviyeye çıkarma | 6.875 altın | Sürekli stat harcaması var; oyuncunun satın almayı tercih edeceği henüz bilinmiyor. |

Bu değerler “oyun kesin kolay” demek değildir. Ödül üretim hızı, başarısızlık oranı ve bölüm süresi birlikte ölçülmelidir. Kristal hem tekrar oynayarak elde edilip hem yalnız stat hızlandırıyorsa satış için iki zayıf yol kalır: ya oyuncu almaya ihtiyaç duymaz ya ilerleme baskısı artırılarak ödeme zorlanır. İkincisi retention ve güveni düşürebilir.

**Öneri:** Önce ilk-tamamlama ve tekrar ödüllerini ayrı ölç; altın/dakika ile yükseltme başına bekleme süresini çıkar. Kristale görünür ve isteğe bağlı bir değer önerisi oluştur. Ödülleri doğrudan kısmak, oyuncunun sevdiği akışı bozabilir; fiyat ve ödül kararını gözlenen davranışla ver.

### 4.3. Mastery, henüz satılabilir bir sezon sistemi değil

Mevcut mastery 40, 110, 200, 320, 470, 650 ve 900 XP eşiklerinde **7 ödülden** oluşur. Elle toplama vardır; ücretli hat, sezon, yenilenen içerik takvimi ve satın alınmış hak sistemi yoktur. “Battle-pass” adını gelir kaynağı olarak saymak erken olur. Bir normal savaş 12, elit 27, boss 32 XP verir. İlk üç seviyenin iki normal savaş + boss içeren başarılı rotası 56 XP üretebilir; yalnız bu rotaların tekrarıyla 900 eşiği yaklaşık 17 başarılı koşuda aşılır. Bu süre veya retention tahmini değildir. [Mastery](../scripts/meta/mastery_track.gd), [XP verme](../scripts/battle.gd:1249)

**Öneri:** Önce mevcut ödüllerin ne kadar sürede tüketildiğini ölç. Haftalık içerik üretim kapasitesi kanıtlanmadan ücretli sezon sözü verme. Aynı ekipmanın oyuncuda zaten bulunması halinde mastery ödülünün algılanan değerini de kontrol et.

### 4.4. Mobil oturum kesintisi gelir kaybettirebilir

Kalıcı kayıt altın, kristal, ilerleme, ekipman ve mastery gibi meta verileri tutuyor. Aktif koşunun haritası, mevcut düğümü, canı, seçilmiş relic'leri ve koşu içi altını bu kayıtta bulunmuyor. Yeni battle açılışı yeni RunState ve harita kuruyor. Dolayısıyla eski belgelerdeki “uygulamadan çıkınca koşu kaybolmaz” vaadi mevcut kayıttan doğrulanmıyor. [Kayıt](../scripts/meta/meta_progress.gd:257), [Battle başlangıcı](../scripts/battle.gd:127)

Özellikle endless'ta altın, koşu normal biçimde sona erince Meta'ya aktarılır. İşletim sisteminin uygulamayı sonlandırması, ölüm ekranından çıkmakla aynı akış değildir. Telefon çağrısı, arka plana alma ve yeniden başlatma testleri release önceliğidir.

**Öneri:** Güvenli oda sınırlarında koşu kaydı, geri yükleme, sürümleme ve ödülün çift yazılmasını engelleyen tamamlanma kaydı. “Daha sonra devam edebilirim” duygusu, yeni mod eklemek kadar önemli olabilir.

### 4.5. İlerleme düğmesinde görünür alan taşması var

Ana ekrandaki mastery TOPLA düğmesi x=920 konumunda ve en az 280 piksel genişlikte kuruluyor. Temel görünüm genişliği 1080 olduğundan sağ kenarı **1200'e**, görünümün 120 piksel dışına uzanıyor. Bu statik yerleşim bulgusudur; farklı cihaz oranlarındaki gerçek görüntü ayrıca test edilmeli. [Ana ekran](../scripts/home.gd:86)

Ödülün alınmasını zorlaştıran böyle bir hata, arketip erişimini de etkiler. Bu nedenle kozmetik bir düzeltme olarak değil, ilk oturum ve progression hunisinin parçası olarak önceliklendirilmeli.

### 4.6. Ritim fark yaratabilir; kalite test edilmeden avantaj sayılamaz

Ritim hızında adaptasyon var. Fakat rastgele yön dizisini sürekli takip etmek, görsel savaşı izlemekle rekabet edebilir. İncelenen script ve sahne yapısında ses oynatma entegrasyonu bulunmadı; ritim duygusunun görsel zamanlama ve haptikle ne kadar güçlü olduğu cihaz testinde ölçülmelidir.

Endless için derinlikle artan hız girişi, minigame içinde **2,2× tavanına** kırpılır. Dolayısıyla belgelerdeki “sürekli hızlanma” ifadesi sınırsız artış değildir. İlk tur çarpanı 1 iken derinlik 20 tabanı zaten 2,2'ye getirir; savaş içi tur çarpanı tavanı daha önce de doldurabilir. [Ritim kurulumu](../scripts/rpg/rhythm_minigame.gd:70), [Hız bağlama](../scripts/battle.gd:865)

**Öneri:** Sesli/sessiz, farklı yenileme hızları, düşük performanslı cihaz, tek elle 10-15 dakika, arka plana geçiş ve farklı dokunma hızlarını kapsayan test. Müzik senkronizasyonu olmayan deneyimi, mağazada müzik ritim oyunu beklentisiyle satmamak gerekir.

### 4.7. Teknik yapı hızlı denemeye elverişli; ticari altyapı eksik

Savaş ve koşu mantığının çoğu sahneden ayrılmış; içerik ve ödül değerleri okunabilir. Bu, küçük denge deneylerinin maliyetini azaltır. Buna karşılık battle ekranı yaklaşık 1.532 satırda görselleri, girdiyi, ekonomi bağlantılarını ve ekran geçişlerini toplar. Bu bir yeniden yazım gerekçesi değildir; yeni ödeme ve analitik işlerini aynı yere yığmak değişiklik riskini artırabilir.

Gerçek ödeme öncesi satın alma doğrulama, bekleyen işlem, tekrar bildirim, iade ve kalıcı haklar; reklam öncesi ödülün yalnız tamamlanan gösterimde verilmesi; ölçüm öncesi olay tanımları ve veri tercihleri gerekir. Büyük bir oyun sunucusu peşinen şart değildir. Gereken en küçük güvenilir ödeme/ödül altyapısı tasarlanmalıdır.

### 4.8. Belgelerdeki çelişki geliştirme parasını boşa harcatabilir

Overview ve bazı tasarım sayfaları hâlâ rün çizimini, üç başlangıç büyücüsünü veya artık geçerli olmayan bölüm eğrilerini anlatıyor. Güncel savaş sayfasında bile eski tap-to-cast anlatımı ile yeni ritim anlatımı birlikte duruyor. Örneğin eski metindeki son boss yaklaşık 785 HP iken mevcut formül 20. seviyede **750×4,42 = 3.315 HP** üretir.

Rapor eski iddiaları güncel oyun gerçeği olarak kullanmaz. Wiki'yi tümüyle yeniden yazmak bu incelemenin kapsamı değildir; bir sonraki geliştirme planında güncel ürün özeti ile tarihsel kararları ayırmak küçük ama değerli bir iştir.

## 5. Gelir modeli ve fiyat denemeleri

### Önerilen ilk ticari model

**Ücretsiz giriş + sınırlı isteğe bağlı ödüllü reklam + az sayıda açık satın alma.** Gerekçe: mevcut oyun kısa tekrar döngüsüne ve kalıcı ilerlemeye sahip; girişte ücret istemeden eğlenceyi göstermek mümkün. Bu yaklaşımın uygunluğu ölçümle sınanmalı.

| Gelir öğesi | İlk deney | Korunacak sınır |
|---|---|---|
| Ödüllü reklam | Koşu sonunda ek altın veya isteğe bağlı bir ek hak | Savaşın veya ritim dizisinin ortasında gösterilmez. |
| Küçük destek paketi | Görünür kozmetik + açıkça belirtilmiş sınırlı içerik | Satın almadan oynanabilen anlamlı build yolları korunur. |
| Kozmetik paket | Büyücü görünümü, büyü etkisi veya kullanıcı profili görseli | Mağaza önizlemesiyle oyundaki görünüm uyuşur. |
| Zorunlu reklam kaldırma | Ancak zorunlu reklamlar daha sonra gerçekten eklenirse | Reklam yokken “reklamları kaldır” satılmaz; ödüllü reklama etkisi açık yazılır. |
| Premium mastery | İlk sürümde ertelenir | Yenilenen içerik üretimi ve retention kanıtlandıktan sonra düşünülür. |

Mevcut oyunda bu satın almalar uygulanmış değildir. Tablodaki maddeler öneridir; mevcut özellik gibi gelir hesabına alınmamıştır.

### Fiyat aralıkları

USD bazında **2,99-4,99 destek paketi**, **1,99-4,99 kozmetik**, gelecekte gerekiyorsa **4,99-7,99 zorunlu reklam kaldırma** ilk fiyat denemesi aralıkları olabilir. Bunlar rakipten alınmış fiyatlar veya doğrulanmış ödeme isteği değildir. Ülke fiyatı, mağaza vergi uygulaması, içerik değeri ve fiyat deneyi sonucu ayrıca belirlenmelidir. Birden fazla ürünü aynı anda kurmak, hangi teklifin neden çalıştığını öğrenmeyi zorlaştırır.

İlk iki deneme için büyük bir kristal paket mağazası yerine **tek açık paket** öneririm. Kozmetik üretim maliyeti de hesaba katılmalı: 400 USD'lik bir görsel paket, iadeler ve mağaza payı sonrası satış başına 3 USD katkıyla yaklaşık 134 satış ister; satış sayısı küçükse “kozmetik ucuz gelir” varsayımı yanlış olur.

### Beceri ve ödeme dengesi

Campaign'de oyuncunun hataları öğrenerek aşabilmesi ve para harcamadan anlamlı ilerlemesi korunmalı. Satılan gücün endless skoruna etkisi, ileride rekabetçi sıralama eklenirse ayrıca değerlendirilmelidir. Eşit koşullu challenge/seed modu daha sonra seçenek olabilir; bugünkü yerel endless'ı büyütmek için hemen leaderboard yapmak gerekmez.

### Mağaza kesintisi

Finansal modelde **%15 etkili mağaza/billing kesintisi** varsayılmıştır. Google Play'in güncel ücret tablosu bölge, işlem türü, kurulum durumu ve programa göre farklılaşır; EEA/UK/US için 30 Haziran 2026 sonrası ayrımlar da vardır. Kalan pazarlardaki %15 kademesi kayıt koşullarına bağlıdır. Bu yüzden “her durumda %15” kabul edilmemelidir. Apple Small Business Program da uygunluk ve kayıt gerektirir. [Google ücret tablosu](https://support.google.com/googleplay/android-developer/answer/112622?hl=en), [Apple Small Business Program](https://developer.apple.com/app-store/small-business-program/)

Reklam gelirine bu modelde ayrıca mağaza komisyonu uygulanmaz. Kullanılan eCPM, reklam ağının yayıncıya ödeyeceği net geliri temsil eder. IAP harcaması tüketim vergileri hariç alınır; ülke fiyatı vergi dahilse önce vergi ayrılmalıdır. Gelir/kurumlar vergisi hesaplanmamıştır.

## 6. Birim ekonomi ve satış senaryoları

### Önce doğru ölçü

**Kurulum sayısı tek başına ticari başarı değildir.** 0,60 USD'ye getirilen oyuncu 90 günde 0,26 USD değişken gider sonrası değer bırakıyorsa, reklam bütçesini artırmak zararı artırır.

- **CPI:** Reklam harcaması / ücretli kurulum.
- **D1, D7, D30:** Aynı ilk-kurulum kohortunun 1., 7. veya 30. gün tekrar oynayan oranı. Ölçüm günü tanımı sabit tutulur.
- **A90:** Kurulum başına ilk 90 gündeki toplam beklenen aktif gün; 90 takvim günü veya ortalama oturum sayısı değildir. Gün 0 dahil, gün 0-89 aktiflik oranlarının toplamıdır.
- **eCPM:** Gerçekleşmiş 1.000 reklam gösterimi başına yayıncı geliri.
- **p90:** İlk 90 günde en az bir kez ödeme yapan kurulum oranı.
- **ARPPU90:** Ödeme yapan oyuncunun bu dönemdeki toplam harcaması; işlem fiyatı veya aylık harcama değildir.
- **Net LTV90:** Bu raporda mağaza/iade ve kullanıcıya bağlı teknik gider sonrası, edinim ve sabit gider öncesi 90 günlük değer.

Gösterim sayısı tüm aktif kullanıcı günleri üzerinden ortalamadır; reklam kabul etmeyenleri de içerir. Gerçekleşen gösterim kullanıldığı için fill-rate veya kabul oranı ikinci kez çarpılmaz. Ayrı ölçüm yapılırsa gerçekleşen gösterim = fırsat × kabul × doluluk × gerçekleşme oranı olarak hesaplanır.

### Formüller

`Reklam90 = A90 × (ödüllü_gösterim × ödüllü_eCPM + ara_reklam_gösterim × ara_reklam_eCPM) / 1000`

`IAP90_net = p90 × ARPPU90 × (1 - iade_oranı) × (1 - mağaza_kesintisi)`

`Net_LTV90 = Reklam90 + IAP90_net - kullanıcıya_bağlı_teknik_gider`

`Ücretli_kurulum_katkısı = Net_LTV90 - CPI`

Basit model aktif gün başına reklam verimini sabit kabul eder. Gerçek uygulamada ülke, kullanıcı yaşı ve kohort gününe göre değişen gelir kullanılarak günlük toplam alınmalıdır. 90 gün sonrası gelir bu hesapta sıfır sayılmıştır; ölçülmeden sonsuz ömür veya yüksek kuyruk geliri eklenmez.

### Girdi varsayımları

**Bu tablonun bütün değerleri varsayımdır. “Orta” senaryo en olası sonuç anlamına gelmez.** Senaryolara olasılık atanmadığı için beklenen kâr hesaplanamaz. Her sütun kendi içinde aynı ülke/platform/edinim karmasını temsil eden varsayımsal bir kohorttur.

| Girdi | Zayıf | Orta | Güçlü |
|---|---:|---:|---:|
| A90: toplam aktif gün / kurulum | 2,5 | 5 | 10 |
| Ödüllü gösterim / aktif gün | 1 | 2 | 3 |
| Ödüllü eCPM, USD | 3 | 8 | 16 |
| Ara reklam gösterimi / aktif gün | 0,5 | 0,8 | 1 |
| Ara reklam eCPM, USD | 1 | 3 | 6 |
| p90: ödeme yapan oranı | %0,3 | %1,5 | %3 |
| ARPPU90, USD, vergi hariç | 8 | 15 | 25 |
| İade payı | %3 | %3 | %3 |
| Etkili mağaza/billing kesintisi | %15 | %15 | %15 |
| Teknik gider / kurulum, USD | 0,01 | 0,02 | 0,04 |
| Ücretli CPI, USD | 0,25 | 0,60 | 0,80 |

Ara reklam gösterimi, bu formatın ileride kontrollü denemede korunması halinde geçerlidir. Önerilen ilk deneyde ara reklamı **0** kabul et. Ara reklam kaldırılınca, diğer her şey aynı kalırsa, Net LTV90 zayıfta 0,0173; ortada 0,2455; güçlüde 1,0584 USD olur. Retention iyileşirse gerçek fark daha iyi olabilir; bu etki burada varsayılmamıştır.

### Kurulum başına sonuç

| Sonuç, USD | Zayıf | Orta | Güçlü |
|---|---:|---:|---:|
| Reklam geliri, 90 gün | 0,0088 | 0,0920 | 0,5400 |
| IAP net geliri, 90 gün | 0,0198 | 0,1855 | 0,6184 |
| Toplam net gelir, teknik gider öncesi | 0,0285 | 0,2775 | 1,1584 |
| Net LTV90, teknik gider sonrası | **0,0185** | **0,2575** | **1,1184** |
| Ücretli edinim gideri | 0,2500 | 0,6000 | 0,8000 |
| Ücretli kurulum başına katkı | **-0,2315** | **-0,3425** | **+0,3184** |
| D90 net-gelir ROAS, teknik gider öncesi | %11,4 | %46,3 | %144,8 |

ROAS satırı toplam net geliri reklam harcamasına böler; geliştirici emeğini veya sabit giderleri içermez. Brüt mağaza cirosunu kullanan başka bir kaynağın ROAS değeriyle doğrudan karşılaştırılmaz.

### 100.000 ücretli kurulumun sonucu

| Kalem, USD | Zayıf | Orta | Güçlü |
|---|---:|---:|---:|
| Reklam + net IAP geliri | 2.854 | 27.751 | 115.838 |
| Teknik değişken gider | 1.000 | 2.000 | 4.000 |
| Edinim bütçesi | 25.000 | 60.000 | 80.000 |
| Sabit gider öncesi kohort katkısı | **-23.146** | **-34.249** | **+31.838** |

Bu kurulumların gerçekleşeceği öngörülmüyor. Tablo ölçek etkisini görünür kılan aritmetiktir. Daha büyük kitleye gidildiğinde CPI artabilir ve LTV düşebilir; 1.000 kişilik denemenin verimini 100.000 kişiye sabit taşımak güvenli değildir.

### Duyarlılık: en etkili kaldıraçlar

Orta senaryoda diğer girdiler sabitken:

| Değişim | Net LTV90 / katkı etkisi |
|---|---:|
| CPI 0,10 USD düşer | Ücretli kurulum katkısı +0,10 USD |
| Ödeme yapan oranı %1,5'ten %2,5'e çıkar | Net LTV +0,1237 USD |
| A90, 5'ten 7'ye çıkar | Yalnız reklam etkisiyle Net LTV +0,0368 USD |
| Ödüllü eCPM 8'den 10 USD'ye çıkar | Net LTV +0,0200 USD |
| Aktif gün başına 1 ek ödüllü gösterim | Net LTV +0,0400 USD |
| Mağaza kesintisi %15'ten %30'a çıkar | Net LTV -0,0327 USD |

Retention artışı IAP'yi de etkileyebilir; tabloda bu etki iki kez sayılmaması için sabit tutuldu. Ek reklamın oyuncu kaybettirmesi halinde gelir artışı daha düşük veya negatif olabilir. Orta senaryodaki zarar birkaç banner veya küçük bir fiyat değişikliğiyle kapanmıyor.

Örnek güvenlik payı olarak **Net LTV90 / CPI ≥ 1,30** istenirse ödenebilecek CPI yaklaşık zayıfta 0,014; ortada 0,198; güçlüde 0,860 USD olur. Bu %30 oranı net kâr marjı değil, edinim üzerinde seçilmiş bir tampon hedefidir. Sabit giderler hâlâ ayrıca karşılanmalıdır.

## 7. Aylık gelir hedefleri ve nakit ihtiyacı

### Nakit kârı ve ekonomik kâr

**Nakit faaliyet sonucu:** Gelirden reklam, teknik gider ve o ay gerçekten ödenen işletme faturalarını çıkarır.

**Ekonomik faaliyet sonucu:** Buna geliştiricinin emeği için belirlenen karşılığı da ekler. Maaş çekilmese bile zamanın maliyeti vardır. Gerçek maaş zaten nakit giderlerdeyse ikinci kez düşülmez.

Örnek aylık gider: **700 USD nakit işletme gideri + 2.500 USD geliştirici emeği = 3.200 USD ekonomik sabit gider.** Bunlar kullanıcı bütçesi değildir. Edinim harcaması bu 700 USD'nin içinde değildir; aşağıda ayrıca hesaplanır.

### Aylık ölçek hesabı

Her ay N yeni kurulumun geldiği, bunun p kısmının ücretli olduğu ve hem ücretli hem organik kullanıcıların aynı LTV'ye sahip olduğu basitleştirilmiş durumda:

`Aylık ekonomik sonuç ≈ N × (Net_LTV90 - ücretli_payı × CPI) - 3.200`

Bu, 90 günlük gelir eğrisi olgunlaştıktan sonra sabit kurulum akışına sahip işletmenin yaklaşık çalışma düzeyidir. İlk ayın geliri değildir. Yeni oyunda geçmiş kohortlar olmadığı için erken nakit girişi daha düşüktür. Organik ve ücretli oyuncular gerçekte farklı değer üretebilir; veri gelince ayrı hesaplanmalıdır.

| Durum | Aylık yeni kurulum | Ücretli payı | Ekonomik sonuç, USD/ay |
|---|---:|---:|---:|
| Orta ekonomi, tamamı organik | 10.000 | %0 | -625 |
| Orta ekonomi, yarısı ücretli | 10.000 | %50 | -3.625 |
| Güçlü ekonomi, çoğu ücretli | 5.000 | %80 | -808 |
| Güçlü ekonomi, çoğu ücretli | 10.000 | %80 | +1.584 |
| Güçlü ekonomi, çoğu ücretli | 20.000 | %80 | +6.368 |

Tamamı organik kurulumun reklam gideri sıfır varsayılmıştır, üretim ve topluluk emeği sıfır değildir. Bu emek mevcut sabit bütçeyi aşıyorsa ayrıca eklenmelidir. Ayda 10.000 organik kurulumun gerçekleşeceğine dair mevcut kanıt yoktur.

**Güçlü senaryo, %80 ücretli payında:**

- Nakit giderleri karşılamak: yaklaşık **1.464 yeni kurulum/ay**.
- Geliştirici emeği dahil başa baş: yaklaşık **6.690 yeni kurulum/ay**.
- Geliştirici emeği çıktıktan sonra ilave **3.000 USD/ay**, gelir/kurumlar vergisi öncesi: yaklaşık **12.961 yeni kurulum/ay**.
- 10.000 kurulumda ücretli edinim bütçesi: **6.400 USD/ay**. Beklenen olgun dönem net gelir yaklaşık 11.584 USD; teknik gider 400 USD; nakit sabit gider 700 USD; emek karşılığı 2.500 USD.

Ara reklamı sıfırlayıp diğer güçlü varsayımları korursak 10.000 kurulumdaki ekonomik sonuç yaklaşık **984 USD/ay** olur. İlk önerilen reklam politikası için daha uygun karşılaştırma budur.

Orta senaryoda yalnız değişken gider düzeyinde başa baş olmak için organik payının **%57,1'in üzerinde** olması gerekir. Bu eşik sabit giderleri veya organik üretim emeğini karşılamaz. Tamamı organik orta senaryoda ekonomik başa baş yaklaşık **12.427 kurulum/aydır**.

### Başlangıç yatırımının geri dönüşü

Örnek 12.000 USD ekonomik geliştirme yatırımı, güçlü senaryoda tamamı ücretli edinim üzerinden yaklaşık **37.692 kurulumun katkısını** gerektirir. Bu hesap aradaki sabit faaliyet giderlerini içermez. Daha gerçekçi olarak 10.000 aylık kurulum ve %80 ücretli payı örneğindeki 1.584 USD ekonomik faaliyet fazlasıyla yatırımın geri kazanılması, olgun gelir düzeyine ulaşıldıktan sonra yaklaşık **7,6 ay** sürer. Lansmana hazırlık, kohortların olgunlaşması ve ödeme gecikmeleri bu süreye eklenir.

### Nakit tamponu

10.000 aylık kurulumlu güçlü örnekte, ilk üç ay hiç tahsilat olmayacağını varsayan muhafazakâr stres testi:

- Edinim + teknik değişken gider + nakit sabit: (6.400 + 400 + 700) × 3 = **22.500 USD**.
- Geliştirici için aylık 2.500 USD gerçek nakit çekilişi gerekiyorsa: **30.000 USD**.

Bu tutar “zorunlu sermaye” değildir; ödeme vadeleri ve gelir gerçekleşme eğrisi bilinmediği için verilen sıfır-tahsilat üst stresidir. Geliştirme nakdi ayrıca gerekir. Ölçüm olmadan ilk gün bu ölçeğe çıkmak önerilmiyor.

## 8. Geliştirme bütçesi ve fırsat maliyeti

### Küçük bir ticari denemeye kalan iş

| İş paketi | Planlama aralığı, saat | Ticari gerekçe |
|---|---:|---|
| İlk oturum, erken build, görünür alan düzeltmeleri | 30-50 | Oyuncu kaybını azaltma; ürün vaadini gösterme |
| Olay ölçümü ve basit raporlama | 20-35 | Retention ve ekonomi kararlarını mümkün kılma |
| Kayıt, devam etme, ödül güvenilirliği | 25-45 | Mobil kesintilerde ilerleme kaybını önleme |
| Tek ödeme ürünü ve ödüllü reklam | 35-65 | Gerçek gelir isteğini sınama |
| Ekonomi, bölüm süresi ve içerik tekrar dengesi | 30-60 | Öğütme hissi ile aşırı hızlı tüketim arasını bulma |
| Ses, görsel okunurluk, İngilizce, cihaz QA, mağaza hazırlığı | 60-145 | Hedef pazarda anlaşılır ve kararlı sürüm |
| **Toplam** | **200-400** | Taahhüt veya teklif değil; entegrasyon belirsizliği içerir |

Süreler kodun incelenmesine dayalı planlama tahminidir. Godot mobil plugin uyumluluğu, hedef cihaz sayısı, görsel revizyon ve mağaza süreci süreyi değiştirebilir. Örnek 300 saat, haftada 25 saat ayrıldığında yaklaşık 12 haftadır; mağaza ve kohort bekleme süreleri ayrı veya kısmen paraleldir.

### Üç bütçe seviyesi

| Bütçe | Emek varsayımı | Nakit dış alım/test | %20 belirsizlik payı | Toplam ekonomik maliyet |
|---|---:|---:|---:|---:|
| Dar kapsam | 200 saat × 15 USD = 3.000 | 1.500 | 900 | **5.400 USD** |
| Çalışma örneği | 300 saat × 20 USD = 6.000 | 4.000 | 2.000 | **12.000 USD** |
| Daha kapsamlı | 400 saat × 30 USD = 12.000 | 6.000 | 3.600 | **21.600 USD** |

Bu bütçeler bugünden sonraki iş içindir. Önceden harcanmış para ve zaman batık maliyettir: gelecekteki devam kararını tek başına haklı çıkarmaz. Tüm projenin yatırım getirisini hesaplamak istenirse geçmiş maliyetler ayrıca eklenmelidir.

4.000 USD çalışma örneğinin dağılımı: görsel 1.000, ses 250, çeviri 250, cihaz/test desteği 650, oyuncu edinim denemeleri 1.200, mağaza/hazırlık 250, araç/hizmet 400 USD. Bunlar piyasa teklifi değil bütçe zarflarıdır. %20 rezerv oransal ayrılırsa nakit ihtiyacı yaklaşık **4.800 USD**, emek karşılığı yaklaşık **7.200 USD** olur. İlk doğrulamadaki harcama bu bütçenin parçasıdır; tekrar eklenmez.

### Lisans ve platform giderleri

Godot MIT lisanslıdır; oyunun geliri üzerinden motor telifi gerektirmez. Lisans bildirimleri yükümlülüğü sürer. Bu maliyet avantajı vardır ama oyuncu edinim sorununu çözmez. [Godot lisansı](https://godotengine.org/license/)

Google Play yeni geliştirici kaydı için tek seferlik 25 USD; Apple Developer üyeliği yılda 99 USD olarak listelenir. Zaten geçerli hesap varsa bu kalem yeniden doğmayabilir. iOS'a geçişteki asıl ek maliyet hesap ücretinden çok cihaz, entegrasyon ve QA zamanıdır. [Google Play başlangıç](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en-AU), [Apple üyelik](https://developer.apple.com/support/compare-memberships/)

Depodaki iki Kenney paketinde ticari kullanımı kapsayan CC0 lisans metni var. Bu, diğer tüm görsellerin, fontların ve gelecekte eklenecek seslerin kaynağını otomatik doğrulamaz. Satın alma, kaynak ve izin kayıtlarını tek asset listesinde toplamak mağaza hazırlığı işinin parçası olmalıdır.

## 9. Ölçüm ve doğrulama planı

### İlk 4-6 hafta için önerilen tavan

**80-120 saat ve 1.200 USD nakit.** Kullanıcının bütçe onayı verilmiş değildir; bu bir öneridir ve rapor kapsamında harcama yapılmamıştır.

Örnek dağılım: katılımcı/test desteği 200, kreatif üretimi 200, ücretli test trafiği 600, teknik araç ve beklenmeyen ihtiyaç 200 USD. 600 USD trafik, gerçekleşen CPI 0,60 ise yaklaşık 1.000; CPI 2 USD ise 300 kurulum getirir. Kurulum garantisi değildir. Yeterli örneklem çıkmazsa bütçe otomatik artırılmaz.

### Aşama A: Anlaşılabilirlik ve eğlence

Yaklaşık 15-20 bağımsız katılımcı. İlk oynayışta yardım etmeden gözlemle; ardından kısa görüşme yap. Farklı telefonlar ve refleks rahatlığı olan oyuncuları dahil et.

- İlk doğru büyüye ulaşma süresi.
- İlk ritim hatasında oyuncunun ne olduğunu anlayıp anlamaması.
- Orb sonucunun ve kart bedelinin anlaşılması.
- İlk form/arketip deneyimine ulaşma.
- Yardımsız ikinci koşuya başlama isteği.
- 10-15 dakika sonunda fiziksel rahatsızlık veya sıkılma.
- Uygulamayı kapatıp açınca beklenen ve gerçekleşen ilerleme.

Bu küçük grup nitel sorunları bulur; D7 veya satın alma oranını güvenilir tahmin etmez. “Oyunu beğendin mi?” yanıtından çok, oyuncunun kendi isteğiyle yeniden oynaması önemlidir.

### Aşama B: İlk gerçek kohort

Mümkünse aynı sürüm ve hedef pazarda **en az 300-500 kurulum**. Organik, tanıdık, teşvikli testçi ve ücretli kullanıcıları ayrı etiketle. D7 için yedi günü tamamlamış kohort kullan; yeni kurulumları paydaya ekleme.

| Metrik | İlk karar hedefi | Hedef kaçarsa yapılacak iş |
|---|---|---|
| İlk savaşın tamamlanması | ≥%80 | İlk girdi, anlatım ve erken zorluk |
| İlk oturumda form/build deneyimi | ≥%70 | Kilitler, teklif havuzu, orb erişimi |
| D1 | ≥%35 | İlk değer anı, kesinti, okunurluk |
| D7 | ≥%12 | Tekrar kalitesi, build çeşitliliği, ilerleme |
| D30 | ≥%5 | İçerik tüketimi ve kalıcı hedefler |
| Çökmesiz oturum | ≥%99,5 | Cihaz/OS bazlı hata düzeltme |
| Aktif koşuya güvenli dönüş | Test matrisindeki senaryolarda başarı | Kayıt ve ödül tutarlılığı |

Bunlar analistin seçtiği yatırım eşikleridir; pazarın değişmez kuralları değildir. D30, ilk gerçek kohort başladıktan en az 30 gün sonra görülebilir. Hazırlık birkaç hafta alırsa 4-6 haftalık ilk dönem yalnız D1/D7 ve ilk gelir sinyallerini üretir; D30 kararı sonraya taşar. D90 ise 90 gün veya belirsizliği açıklanmış bir tahmin modeli gerektirir.

### Örneklem gerçeği

500 kişide %12 D7 yaklaşık 60 geri dönen oyuncudur. Basit normal yaklaşımla %95 güven aralığı yaklaşık **%9,2-%14,8** olur. Böyle bir kohortta %11 ile %12 arasındaki farkla büyük yatırım kararı verilmez. İki varyantı küçük gruplara bölmek belirsizliği artırır; düşük bütçede önce tek sürümün temel sorunlarını düzeltmek daha verimlidir.

%1,5 ödeme oranı 500 kurulumda yaklaşık **7-8 ödeme yapan** kişi demektir. Bir yüksek harcayan ortalamayı ciddi değiştirebilir. D90 ödeme oranı için henüz olgunlaşmamış ilk haftayı kullanma. Ödeme davranışı için mümkünse 2.000-5.000 kurulumluk olgunlaşan kohort, yeterli ödeme yapan ve dağılım analizi gerekir; bu hacim bile gelir garantisi vermez.

### Aşama C: Para kazanma deneyi

Önce ödüllü reklamı tek bir doğal duruşta test et. Ardından tek açık ürün ekle. Aynı anda reklam sıklığı, fiyat, zorluk ve ödül miktarını değiştirme. Her deney için önceden şu soruyu yaz: “Hangi davranış değişirse bu değişikliği koruyacağız?”

- Reklam fırsatı → kabul → yüklenme → tamamlanma → ödül verilme.
- Mağaza gösterimi → ürün inceleme → satın alma başlangıcı → doğrulanmış ödeme.
- Reklam veya mağaza sonrasındaki oturum sonlanması ve sonraki gün dönüşü.
- Reklam izleyen/izlemeyen ve ödeme yapan/yapmayan grupların ilerleme hızı.
- Platformdaki gerçek net ödeme ile analitik gelir olaylarının mutabakatı.

### Minimum olay seti

`first_open`, `session_start`, `session_end`, `run_start`, `battle_end`, `rhythm_result`, `form_transform`, `archetype_offer`, `archetype_pick`, `orb_board_result`, `run_end`, `mastery_claim`, `currency_source`, `currency_sink`, `ad_impression`, `reward_granted`, `purchase_verified`, `run_resume`.

Her olayda gerekli olan sürüm, platform, ülke/edinim kohortu, anonim oyuncu/koşu kimliği ve ilgili ilerleme alanları bulunmalı. Her kareyi kaydetmek gerekmez. Örneğin `rhythm_result`, kombo skoru, uzunluk, hız ve kırılmayı özetleyebilir. Gelir olaylarında işlem kimliğiyle tekrar kayıt önlenir. Toplanan veriye uygun bilgilendirme ve kullanıcı tercihleri uygulamaya eklenir.

### Durdur / düzelt / büyüt

- **Durdur veya kapsamı küçült:** İki anlamlı ürün düzeltmesine rağmen hedef oyuncular oyunu yardımsız anlayamıyor veya tekrar oynamak istemiyorsa.
- **Düzelt:** D1 iyi, D7 zayıfsa yeni reklam almak yerine tekrar kalitesini ve build erişimini iyileştir.
- **Küçük ticari sürümü koru:** Organik topluluk olumlu ama ücretli LTV/CPI negatifse düşük nakit giderli niş model düşünülebilir.
- **Kademeli büyüt:** Hedef ülke/platformda ölçülmüş gelir, tutarlı retention ve temkinli Net LTV/CPI hesabı olumluysa. Seçilmiş 1,30 tamponunu ve sabit gider başa başını birlikte kontrol et.
- **Bütçeyi geri çek:** CPI yükselir, kohort geliri düşer veya D7/D30 kötüleşirse önceki ölçeğe dön. Büyümenin kendisi başarı ölçüsü değildir.

## 10. Önceliklendirilmiş yol haritası

### P0: Yeni oyuncuya para harcamadan önce

1. Mastery TOPLA taşmasını, kart okunurluğunu ve güvenli ekran alanlarını düzelt.
2. İlk ritim, ilk dönüşüm ve ilk build anını gözlenebilir hale getir; öğretici deneme kurgula.
3. Koşu kaydı ve mobil devam etme akışını doğrula.
4. Minimum olay ölçümünü ve cihaz hata takibini kur.
5. Kullanıcı testinde test kristal düğmesini açıkça kontrol et; gerçek ekonomi deneyinden çıkar.

### P1: Küçük gelir denemesinden önce

6. Tekrarlı bölüm ödülleri, kristal çevrimi ve ekipman tüketim hızını ölçerek ayarla.
7. Tek ödeme ürünü, işlem doğrulama ve tek ödüllü reklam yerleşimi ekle.
8. İngilizce metinleri, ses geri bildirimini ve hedef cihaz matrisini tamamla.
9. Paket adı, sürümleme, imzalı mağaza paketi, lisans kayıtları ve veri beyanlarını hazırla. Mevcut Android ayarında `com.example.wizardgame` kullanılıyor; yayın öncesi ürün kimliği kesinleştirilmeli.

### P2: D7/ekonomi sinyali geldikten sonra

10. Mevcut üç arketipi belirgin ve erişilebilir kıl; ardından sınırlı Plazma etkileşimleri ekle.
11. Gerçek içeriği tüketen oyuncular varsa mastery devamını veya küçük challenge paketini üret.
12. iOS'u ayrı maliyet ve gelir denemesi olarak değerlendir.

**Şimdilik ertele:** Çok sayıda yeni büyücü, yüzlerce bölüm, guild, PvP, büyük backend, kapsamlı leaderboard, ücretli sezon takvimi ve geniş kristal mağazası. Bunların tamamı gelir artışı kanıtlanmadan bakım ve içerik maliyetini büyütür.

### Pazarlama deneyi

Üç gerçek oynanış videosu yeterli ilk farklılaşma deneyi olabilir:

- Ritim girdisi → son vuruş → büyü patlaması.
- Kor → Plazma görsel dönüşümü.
- Aynı karşılaşmada farklı arketiplerin farklı sonucu.

Orb videosu dikkat çekebilir; yalnız orb gösterip oyuncuyu ağırlıklı ritim-savaşa getirmek yanlış beklenti yaratabilir. Reklamın en az bir kısmı gerçek savaş girdisini göstermeli. Videonun ucuz kurulum üretmesi kadar, getirdiği oyuncunun D7'si ve net geliri değerlendirilmelidir.

## 11. Alternatif iş modelleri ve nihai karar

| Yol | Avantaj | Bedel / koşul | Bugünkü değerlendirme |
|---|---|---|---|
| Bağımsız, hibrit mobil | Mevcut döngüyle uyumlu; tüm ürün kararları sende | UA, ölçüm, içerik ve destek yükü sende | Küçük doğrulama için ilk seçenek |
| Yayıncıyla çalışma | Dağıtım bütçesi ve ticari deneyim sağlayabilir | Gelir paylaşımı, masraf geri alımı ve kontrol şartları | Kanıtlı kohorttan sonra anlamlı |
| Organik niş / destek paketi | Düşük reklam nakdiyle başlayabilir | Topluluk emeği ve sınırlı erişim | Paid UA çalışmazsa ekonomik alternatif |
| Ücretli premium mobil | Daha sade ödeme modeli | Giriş engeli; içerik ve ödeme isteği kanıtı gerekir | İkinci bir doğrulama; hazır çözüm değil |
| PC/Steam uyarlaması | Daha farklı ödeme ve oturum yapısı denenebilir | Kontrol, arayüz ve içerik uyarlaması ayrı proje olur | Şimdi öncelik değil |

Yayıncı anlaşması için internette görülen tek bir gelir paylaşımı oranını standart kabul etme. Değerlendirilecek kalemler: hangi masrafların önce geri alındığı, paylaşımın hangi gelir tabanına uygulandığı, fikri mülkiyet, veri erişimi, fesih, minimum destek ve geliştirme yükümlülükleri. Somut teklif olmadığından raporda yayıncı geliri hesaplanmamıştır.

### Açık kararım

**Bu projeyi şimdi bırakmayı önermiyorum. Büyük gelir beklentisiyle özellik eklemeyi de önermiyorum.** Mevcut kod, küçük bir ticari doğrulama denemesi için yeterli yatırımın yapılmış olduğunu gösteriyor. En yüksek getirili sonraki iş, oyuncunun ilk birkaç dakikada neyi sevdiğini ve neden döndüğünü öğrenmek.

Ben bu projeyi yönetiyor olsaydım:

1. İlk karar dönemini 4-6 hafta ve önerilen bütçe tavanıyla sınırlandırırdım.
2. İlk build deneyimini öne alır, kayıt/ekran sorunlarını ve ölçümü tamamlardım.
3. En az bir gerçek hedef-pazar kohortu toplardım.
4. Geri dönüş iyi ise tek gelir ürününü sınardım.
5. Ancak aynı pazarda Net LTV/CPI ve nakit akışı olumluysa içerik ve dağıtım yatırımını büyütürdüm.

**Kârlılık potansiyeli var; kârlılığın kanıtı henüz yok. Şimdiki hedef daha fazla özellik değil, sınırlı maliyetle daha iyi bir yatırım kararı verecek veri üretmek olmalı.**

## 12. Kanıt dizini, kaynaklar ve sınırlamalar

### Yerel kanıtlar

| Kanıt | İncelenen kaynak | Kullanım |
|---|---|---|
| K1 | `project.godot`, `export_presets.cfg` | Ana sahne, yön, görünüm, Android paket ayarları |
| K2 | `scripts/rpg/run/run_content.gd` | Karakter/form, seviyeler, ödüller, katalog ve build erişim aralığı |
| K3 | `scripts/rpg/run/choice_generator.gd` | Dönüşüm garantisi, arketip/relic havuzu, fiyatlar ve kilitler |
| K4 | `scripts/rpg/run/run_loadout.gd`, `run_manager.gd` | Form taşıma ve koşu akışı |
| K5 | `scripts/meta/meta_progress.gd`, `mastery_track.gd` | Meta ekonomi, kalıcı kayıt, mastery |
| K6 | `scripts/home.gd` | Test satın alma düğmesi ve ödül düğmesi yerleşimi |
| K7 | `scripts/battle.gd` | Mevcut oynanışa bağlama, koşu sonu ödülü, ritim ve XP |
| K8 | `scripts/rpg/rhythm_minigame.gd` | Zamanlama, jest, hız tavanı ve kombo |
| K9 | `scripts/rpg/turn_manager.gd`, `battle_damage.gd`, `equipment.gd` | Hasar, stat etkileri ve ekipman maliyetleri |
| K10 | `tests/run_tests.gd` ve çağırdığı 7 grup | 15 Eylül 2026 test çalıştırması: 253 kontrol geçti |
| K11 | `wiki/`, `.raw/data/2026-09-07-run-buyucusu-tasarim-notlari.md` | Tasarım niyeti, tarihsel yön ve açık kararlar |

### Dış kaynaklar

Tüm bağlantılar 15 Eylül 2026 tarihinde incelendi. Mağaza sayaçları zamanla ve yerelleştirmeye göre değişebilir.

1. [Cup Heroes - Google Play](https://play.google.com/store/apps/details?hl=en_US&id=com.studio501.cuphero). Rakip model ve kurulum eşiği.
2. [Archero 2 - Google Play](https://play.google.com/store/apps/details?hl=en_US&id=com.xq.archeroii). İçerik ve gelir modeli karşılaştırması.
3. [Magic Survival - Google Play](https://play.google.com/store/apps/details?gl=gb&hl=en-GB&id=com.vkslrzm.Zombie). Büyü/tek el konumlandırması.
4. [GameAnalytics 2026 Mobile & PC Gaming Benchmarks](https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks). 2025 verisi; 16K+ mobil oyun; bu projeye özgü tahmin değil.
5. [AppsFlyer 2024 App Monetization Report özeti](https://www.appsflyer.com/company/newsroom/pr/app-monetization-report/). Hibrit gelir modeli bağlamı; nedensel karşılaştırma değil.
6. [AppsFlyer 2025 Creative Optimization](https://www.appsflyer.com/resources/reports/creative-optimization-report-2025/). Reklam yaratıcılarının yoğunlaşması ve örneklem.
7. [Appodeal 2025 eCPM Report](https://appodeal.com/wp-content/uploads/2025/03/Appodeal-The-Latest-eCPM-Report-2025.pdf). Ekim-Aralık 2024 dönemi; yalnız format/pazar farklarının bağlamı.
8. [Google Play Service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en). Bölge/program/billing ayrımları.
9. [Apple Small Business Program](https://developer.apple.com/app-store/small-business-program/). Uygunluk koşullu kesinti.
10. [Google Play kayıt](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en-AU), [Apple üyelik](https://developer.apple.com/support/compare-memberships/). Hesap giderleri.
11. [Godot License](https://godotengine.org/license/). Motor lisansı.

### Hesabın sınırları

- Gerçek oyuncu ve mağaza finans verisi yok; tüm geleceğe dönük performans, saat, fiyat ve giderler senaryodur.
- Başarı olasılığı, şirket değeri veya kesin satış tahmini üretilmemiştir.
- Hesaplar gelir/kurumlar vergisi, ülkeye özgü stopaj, kur dönüşümü, kredi faizi ve geçmiş geliştirme maliyetlerini içermez.
- IAP tabanı tüketim vergisi hariçtir; gerçek mağaza tahsilatlarıyla mutabakat gerekir. %3 iade payı ölçüm değil varsayımdır.
- Organik dağıtım ücretsiz emek varsaymaz; sadece reklam harcaması farklıdır.
- D90 değerini ilk ay nakit geliri olarak kullanma. Tam nakit planı, günlük gelir eğrisi ve gerçek ödeme takvimini gerektirir.
- Teknik kontroller çalıştırılmıştır; canlı cihaz performansı, oynanış keyfi ve ödeme akışı bu çalışmada doğrulanmamıştır.
- Oyun kodu, oyun dengesi ve onaylı ürün kararları bu rapor hazırlanırken değiştirilmemiştir.
