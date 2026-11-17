# GameTranslator Mobil (Android)

Bilgisayardaki GameTranslator'ın telefonda çalışan hâli. Telefon bilgisayarın yerine geçer:

1. PS5 görüntüsünü Remote Play ile alır (libchiaki; kumanda TV'de kalsın diye ikinci kullanıcıyla).
2. Görüntüde altyazı bölgesini okur (ML Kit, cihaz üstünde).
3. Çevirir (Google, DeepL ya da cihaz üstünde ML Kit).
4. Çeviriyi TV'deki GameTranslator uygulamasına gönderir (8787 portunda aynı altyazı sunucusu).

TV uygulaması değişmedi: telefonda çeviri başlayınca TV'deki uygulama telefonu ağda kendisi bulur. Bilgisayardaki
GameTranslator aynı anda çalışmamalıdır; PS5 tek Remote Play bağlantısı kabul eder ve TV tek sunucuya bağlanır.

## Kullanım

1. Telefon, PS5 ve TV aynı Wi-Fi ağında olmalı.
2. Uygulamayı açın, PSN ile giriş yapın (PS5'teki ikinci kullanıcının hesabı).
3. PS5'te ikinci kullanıcıdayken Ayarlar › Sistem › Uzaktan Oynatma › Cihaz Eşleştir'deki 8 haneli kodu girin.
4. **Çeviriyi başlat**'a basın, TV'de GameTranslator'ı açın. Ekranı kapatabilirsiniz; çeviri bildirimdeki
   servisle sürer.

Ana ekrandaki "Bölgede okunan" satırı ve önizlemedeki mavi çerçeve, altyazı bölgesinin doğru yerde olup olmadığını
gösterir; Ayarlar'dan değiştirilir.

### TV'ler ve tarayıcı

Telefon, bilgisayardakiyle aynı altyazı sunucusunu çalıştırır; LG (webOS), Samsung (Tizen) ve Android TV uygulamaları
telefonu ağda kendileri bulur.

TV uygulaması LG ve Android TV'ye telefondan kurulur: Rehber, Ayarlar ya da ana ekrandaki "TV uygulamasını kur"
sihirbazı markayı sorar, TV'yi ağda arar (LG: SSDP, Android TV: 5555 portu taraması; adres elle de yazılabilir),
geliştirici modu adımlarını tek tek gösterip TV'nin hazır olduğunu kendisi denetler, kurar ve TV'de açar.
Android TV'ye ADB ile (onay sorusu TV'de çıkar), LG'ye geliştirici modunun Key Server'ı ve SSH'ı ile kurulur
(`tvinstall/`, Windows'taki `GameTranslator.TvInstall` ve `LgTv/DevModeInstaller` ile aynı akış). Kurulan TV
hatırlanır; yeni sürüm gelince aynı sihirbazdan güncellenir. Samsung'a kurulum şimdilik bilgisayardan yapılır
(`docs/tv-kurulum.md`).

Paketler `android/app/src/main/assets/tv-app/` altındadır: Android TV APK'sı `tv/android`'den
(`gradlew assembleRelease`), LG paketi `python scripts/package-ipk.py --version auto --out-dir mobile/android/app/src/main/assets/tv-app`
ile üretilir. Çeviri açıkken `http://TELEFON:8787/obs` adresi OBS için saydam zeminli altyazı sayfasını
sunar (Windows'taki `/obs` ile aynı dosya).

### Terim sözlüğü

Ayarlar › Çeviri altındaki "Terim sözlüğü" alanına bilgisayardaki sözlük dosyalarıyla aynı biçimde JSON yazılır
(yalnız İngilizce→Türkçe):

```json
{ "terms": { "Leviathan Axe": "Leviathan Baltası" }, "keep": ["Kratos", "Atreus"] }
```

`terms` içindeki terimler verilen Türkçeyle çevrilir, `keep` içindeki adlar olduğu gibi kalır; Türkçe ek terime göre
yeniden kurulur ("Leviathan Baltası'nı", "Kratos'a"). Kurallar Windows'taki `Glossary`, `TermProtection` ve
`TurkishSuffix` ile aynıdır (`core/Glossary.kt`). Uygulamayla hazır sözlük gelmez.

## Tasarım

Arayüz Apple'ın tasarım dilini izler (iOS, koyu görünüm, Liquid Glass): iOS sistem renkleri, büyük başlıklar, cam
yüzeyler, gruplu listeler, altta yüzen cam sekme çubuğu (Çeviri, Rehber, Ayarlar), iOS anahtarları, sürgüleri ve
pencereleri (`cupertino_ui`). Yazı tipi Inter'dir (SIL OFL, `assets/fonts/`): SF Pro lisansı gereği uygulamaya
gömülemez. Renkler ve yazı ölçeği `lib/main.dart` içindeki `Tokens` ve `Txt`, ortak bileşenler `lib/ui.dart` içindedir.

## Yapı

| Katman | Yer | İş |
|---|---|---|
| Arayüz | `lib/` (Flutter) | Tanıtım (`intro_page.dart`), kurulum, ana ekran, ayarlar, ayrıntılı rehber (`guide_page.dart`); ortak parçalar `ui.dart` ve `flow.dart`, PSN girişi `psn.dart` |
| Köprü | `MainActivity.kt` | `gt/bridge` yöntem kanalı, `gt/events` durum akışı |
| Çekirdek | `Engine.kt`, `TranslatorService.kt` | Oturum, yazı okuma, çeviri, yeniden bağlanma; ön plan servisi |
| Mantık | `core/` (saf Kotlin) | `SubtitleStabilizer`, `TextMatch`, `OcrNoise`, `SubtitlePipeline`, `SubtitleServer` |
| Yerel | `android/app/src/main/cpp/` | `gt_native.c` (libchiaki + MediaCodec), `gt_jni.c` |

`core/` altındaki dosyalar Windows'taki `GameTranslator.Core`'un aynı adlı dosyalarından taşındı; kurallar aynıdır.
`gt_native.c`, `windows/native/gametranslator_native.c` ile aynı arayüzü sunar; tek fark H.264 çözücünün FFmpeg yerine
Android MediaCodec olmasıdır.

Bilgisayar sürümünde olup burada henüz olmayanlar: oyun paketleri (0 ms yamalar), dublaj, "ekranı çevir" ve ek
bölgeler, yapay zekâ çevirmenleri, Samsung TV'ye uygulama kurma (bilgisayardan yapılır).

Simge ve açılış ekranı görselleri uygulama simgesinden `python tool/make_icons.py` ile üretilir (Pillow gerekir).

## Derleme

Gerekenler: Flutter, Android SDK + NDK + CMake 3.22.1, JDK 17, Python 3 (`pip install protobuf grpcio-tools`),
`protoc` (PATH üzerinde) ve chiaki-ng kaynakları:

```sh
git clone --recurse-submodules https://github.com/streetpea/chiaki-ng third-party/chiaki-ng   # depo kökünde
cd mobile
. tool/env.sh                      # bu makinedeki araç yolları (C:\dev); başka makinede düzenleyin
flutter build apk --release --split-per-abi --target-platform android-arm64
```

`GT_PYTHON` ve `GT_PROTOC` ortam değişkenleri (ya da `-PgtPython=... -PgtProtoc=...`) yerel derlemeye Python ve
protoc'u gösterir. Windows'ta `GT_PROTOC` tam yol değil `protoc` olmalı ve klasörü PATH'te bulunmalıdır.

Yayın APK'sı şimdilik hata ayıklama anahtarıyla imzalanır; mağaza için kendi anahtarınızı `android/app/build.gradle.kts`
içinde tanımlayın.

## Testler

```sh
flutter test                                   # PSN yardımcıları
cd android && ./gradlew :app:testDebugUnitTest # çekirdek mantık ve altyazı sunucusu
```

Hata ayıklama derlemesinde eşleştirme adb ile aktarılabilir ve çeviri arayüze dokunmadan başlatılabilir
(`MainActivity.handleDebugIntent`); uçtan uca denemeler bununla yapılır. Yayın derlemesinde bu yol kapalıdır.

## Bilinen sınırlar

- Gerçek telefonda henüz denenmedi; emülatörde (Android 14, x86_64) gerçek PS5 ile denendi.
- OpenSSL hazır paketten gelir (1.1.1q, 4 KB sayfa hizalı): 16 KB bellek sayfası kullanan cihazlarda yüklenmeyebilir.
- Sürekli 1080p video çözme ve yazı okuma pili tüketir ve telefonu ısıtır; şarjda kullanın.
