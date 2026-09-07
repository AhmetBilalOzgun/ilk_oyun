# Rün Büyücüsü — Tasarım Notları

Beyin fırtınası özeti. Karara bağlananlar, açık kalanlar ve test edilmesi gerekenler.

## 1. Oyunun tek cümlesi
Dikey, 2D, dalga tabanlı bir savunma oyunu. Oyuncu ekranın altındaki sabit bir kareye parmağıyla rün şekilleri çizer; en soldaki büyücü karakter o büyüyü sağdan gelen düşmanlara fırlatır. Rünler birbiriyle zincirlenerek kombolara dönüşür.

## 2. Ekran düzeni (karara bağlandı)
| Bölge | İçerik |
|---|---|
| Üst ~2/3 | Savaş alanı. Solda büyücü, sağdan düşman akını. |
| Alt orta | Çizim karesi. Sabit konum, sabit ölçek. İçi neredeyse boş. |
| Çizim karesinin solu | Rün paleti. Savaşa getirilen rünler. |

Neden bu düzen önemli:
- Parmak artık savaş alanını kapatmıyor. Girdi ve dünya mekânsal olarak ayrıldı.
- Kare hep aynı yerde ve aynı büyüklükte olduğu için oyuncu zamanla aşağı bakmadan çizebilir hale gelir. Göz savaş alanında kalır → "konuşurken oynanabilir" kriteri karşılanır.
- Sabit ölçek = tanıma doğruluğunda ciddi artış. Serbest ekrana çizmeye göre çok daha az hata.

Kural: Karakter animasyonu çizim karesinin içinde değil, savaş alanında oynar. Mürekkebin arkasında hareket eden hiçbir şey olmamalı — hem tanımayı zorlaştırır hem görsel olarak yarışır.

## 3. Bilişsel yükü kontrol eden dört karar
Çizim mekaniği, dokunma mekaniğinden yapısal olarak daha ağırdır: hatırlama ister, tanıma değil.

### 3.1 Loadout
Kodekste 40 rün olabilir, savaşa 4 tanesiyle girilir. Bilişsel yük sabit kalır, koleksiyon büyümeye devam eder, rün seçimi kendi başına bir meta katman olur (deste kurma).

### 3.2 Çizerken önizleme
Parmak henüz ekrandayken oluşmakta olan rün soluk şekilde belirir. Oyuncu parmağını kaldırmadan ne çıkacağını görür → "hamle öncesi telegraf" kriteri + tanıma hatası korkusunun sıfırlanması.

### 3.3 Sessiz başarısızlık yok
Sistem asla "anlaşılmadı" demez. Her çizgi en yakın rüne yuvarlanır; hiçbir şeye benzemiyorsa düz vuruşa düşer. "Oyun beni anlamadı" hissi hiç yaşanmaz.

### 3.4 Rün formu kısıtları
- En fazla 2–3 çizgi.
- Köşeli, açısal formlar (baş parmak dikey ekranda karmaşık eğri çizemez).
- Silüet olarak birbirine benzemeyen formlar.
- İlk 20 dakikada tanıma toleransı gizlice çok geniş, sonra yavaşça daralır.

## 4. Düz çizgi (temel saldırı)
Tek bir basit jest = düşük hasarlı düz vuruş. Üç iş birden yapıyor:
1. Ritim — büyük büyüler arasında ölü zaman kalmıyor.
2. İlk hamle kazandırır — yeni oyuncuya ilk saniyeden %100 başarılı bir eylem.
3. Başarısızlık tabanı — tanınmayan her karalama buraya yuvarlanır.

Denge riski: çok güçlü olursa spam edilir, çok zayıf olursa dekor olur.
Önerilen çözüm (hasarda değil, işlevde): düz çizgi komboyu taşısın. rün → çizgi → rün zinciri kombo penceresini kırmadan devam etsin. Böylece dolgu olmaktan çıkıp ritim mekaniğine dönüşür.

## 5. Kombo sistemi ve palet
Sorun: "Ateş + rüzgar = alev fırtınası" ekranda görünmeyen bir kuraldır. Oyuncu ya wiki'den öğrenir ya hiç öğrenmez; gerçekte olan şey, işe yarayan tek bir kombo bulup oyunun geri kalanını onu tekrarlayarak geçirmesidir.

Çözüm: Palet aynı zamanda kombo öğretmeni olsun. İlk rün tamamlandığı anda, onunla eşleşen rünler palette parlar. Sistem kendini oynarken öğretir.

Palet solması (ustalık hissi): Bir rün 10 kez başarıyla çizildikten sonra palet o rünün çizgi yolunu göstermeyi bırakır, sadece ikon ve renk kalır. Oyuncu bir gün artık bakmadığını fark eder. Maliyeti sıfır olan bir ustalık anı.

## 6. Düşman tasarımı ve zaaflar
Kaçınılacak şey: "Kırmızı düşman ateşe zayıf" tipi bir tablo. Bu bir ezberdir ve şu zinciri geri getirir: düşmanı oku → zaafı hatırla → rünü hatırla → şekli hatırla → çiz. Bilişsel yük için kurulan her şeyi geri alır.

Kural: zaaf silüetten okunmalı.
| Görünen özellik | Gereken cevap |
|---|---|
| Kalabalık + küçük | Geniş alan büyüsü |
| Büyük + zırhlı | Delici |
| Kalkanlı | Kalkan önce kırılır |

Kural: zaaf bonustur, kapı değildir. Yanlış rün %40 hasar verir, sıfır değil. Doğru rün ödüllendirilir, yanlış rün cezalandırılmaz. Akış bozulmaz.

## 7. Diğer kriterler için fikirler
Juice. Rün mürekkebi parmağın arkasında akkor gibi kalır; tamamlanınca şekil kilitlenir ve düşmana fırlar. Kombo yapıldığında kullanılan rünler büyücünün etrafında yörüngeye girer — oyuncu zincirini tek bakışta görür. Tepki merdiveni bedava: tek rün küçük kıvılcım, üçlü kombo ekranı beyazlatan dalga.

Oturum yapısı. Dalga başına 40–60 saniye. Doğal duruş noktası = dalga aralarındaki rün seçimi ekranı. Uygulamadan çıkılırsa dalga başına dönülür, koşu kaybolmaz. Oyunun uzun vadeli dönüşüm planına henüz karar verilmedi tahmin üretme.

Başarısızlık. Kaybedilen savaştan "rün özü" çıkar, kodekse gider. Diriliş için reklamın yanına bir de beceri seçeneği: zor bir rün çiz, kalk. Reklam istemeyene çıkış bırakır.

İlerleme ve meta. Karar verilmedi.
Geri dönüş kancası. Karar verilmedi.
Sosyal. Karar verilmedi.

Para kazanma. Starter pack = bir rün + bir mürekkep izi. Kolaylık satılır (çözümleme süresini atlama), zafer değil. Reklamlar dalga aralarında.

Teknik. Çizim tanıma için ağır bir şey gerekmiyor; $1 recognizer sınıfı bir algoritma çevrimdışı ve anında çalışır, düşük cihazlarda sorun çıkarmaz. Rün formlarını tasarlarken tanıyıcının karıştırma matrisine bak, karışan iki rünü tasarım aşamasında ayır. (yine de bu konu araştırılmalı)

## 8. Fikrin güçlü tarafları
Reklam ile oynanış aynı şey. Ekranda bir şekil çiziliyor, bir şey patlıyor. Altı saniyelik videoda anlaşılır; sesi kapalı anlaşılır; dil bilinmeden anlaşılır. Kullanıcı edinim maliyeti düşer, kreatif-oynanış tutarlılığı kendiliğinden gelir.
Girdinin kendisinde faillik var. Dokunmalı oyunlarda oyuncu bir seçeneği onaylar; burada bir şey üretir. "Ben yaptım" hissi dokunmayla elde edilmesi çok zor bir histir.
Üretim ekonomisi lehte. Her yeni rün kendisinden fazlasını açar: on rün, elli kombo. İçerik maliyeti lineer, algılanan içerik kombinatoryal. Sanat yönü de ucuz (koyu zemin, akkor çizgi, silüet) ve küçük indirme boyutu / düşük cihaz performansı hedefiyle doğal uyum içinde.

## 9. Fikrin zayıf tarafları
Çizim süresi ölü zamandır. Bir rün 0,5–1,5 saniye sürer. O sürede dünya devam eder (ilk 5 savaş hariç- yavaşlama efekti iyi olur) (oyuncu kör olduğu anda cezalandırılır).
Asıl risk D1 değil, D7. İlk oturumda oyuncu doğaçlama yapan bir büyücüdür; yirminci oturumda aynı üç şekli tekrarlayan biri. Çizim, tanıdıkça ödülü azalan bir girdidir. Çizim oyunları oyun testlerinde yüksek puan alıp D7'de sert düşer: test edilen şey yenilik, ölçülen şey tekrardır.
Fiziksel yorgunluk. Başparmakla 20 dakika şekil çizmek, 20 dakika dokunmaktan belirgin şekilde daha yorucudur. Oturum uzunluğuna tavan koyar, tavan da gelire dokunur.
Beceri ile para kazanma birbirini iter. Çizim becerisi önemliyse ödeme ilerletmez; ödeme ilerletiyorsa beceri önemsizleşir. Beceri temelli bir oyunda satılacak "kolaylık" pek kalmaz. Fikrin en ciddi ticari zayıflığı bu ve henüz çözülmedi.
İlk "vay" anı erken harcanıyor. Swarm'ı tek büyüyle silmek harika bir açılış ama ölçek yukarı gitmek zorunda; bir noktada ekran zaten hep patlıyor olur → kutlama enflasyonu, juice bütçesine takılır.

## 10. Sıradaki adım: prototip
Kapsam: 4 rün, düz çizgi, tek dalga, iki düşman tipi (swarm + tank), 30 saniye. Kâğıtta değil, telefonda, tek elle.
Test: Birine 20 dakika kesintisiz oynat.
Ölçülecek tek soru: Yirminci dakikada hangi rünü çizeceğini düşünüyor mu, yoksa refleksle mi çiziyor?
- Düşünüyorsa → mekanik tutar, devam.
- Refleksle çiziyorsa → çizim yavaş bir butona dönüşmüştür. Mekaniği sürüklemeye ya da kısa jestlere (çizgi, köşe, yay) indirmek gerekir.

## 11. Açık kalan konular
- Para kazanma modeli
- Oyunun uzun vadede kullanıcıları çekecek özelliği (2. Oynanış - sebep) düşünülmedi
- Uzun vadeli ölçek sorunu — 50. dalgada kutlama neye benzeyecek?
- Kombo penceresi süresi
