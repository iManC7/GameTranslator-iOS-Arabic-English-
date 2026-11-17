# iOS sürümünden diğer platformlara taşınacaklar

iOS sürümünde (`ios-app` dalı) yapılıp Android'e (`mobile/android`) ve bilgisayar sürümüne (`windows/`, `mac/`,
`core/`) henüz eklenmeyen iyileştirmeler. Her madde iOS'taki dosyayı ve commit'i gösterir; aynı kurallar korunmalı.

## 1. Çeviriyi oyunun altyazısının alanına ve boyuna sığdırma

- **Sorun:** TV'deki çeviri ayarlardaki sabit boyda çıkıyor, oyunun altyazısından büyük duruyor ve çok yer kaplıyor.
- **Neden:** TV uygulaması (1.0.5) `subtitle` olayında `source` (oyunun altyazısının kutusu) ve `line` (satır yüksekliği,
  ekran yüksekliğine oranla) alanlarını görünce "cover" yerleşiminde çeviriyi o alana, oyunun yazı boyunda sığdırıyor ve
  alanı opak bantla örtüyor (`tv/webos/app.js` → `fitToSource`). Hiçbir sunucu bu alanları göndermiyordu.
- **iOS'ta:** `mobile/ios/Runner/SubtitleServer.swift` (`subtitleFrame`: `source`, `line`) ve
  `mobile/ios/Runner/VisionReader.swift` (`ServerSink`; `line` = okunan satırların ortanca yüksekliği / kare yüksekliği,
  `source` = okunan yazının kutusu). Commit: `a891cf0`.
- **Android:** `core/SubtitleServer.kt` → `subtitleFrame`'e aynı iki alan; `Engine.kt` → `rows` satır yüksekliğini de
  dönsün, `SubtitleSink.show` onu sunucuya iletsin. Alanlar alfabetik sırada: `at, box, duration, line, replace, source, text`.
- **Windows:** `GameTranslator.Core/SubtitleServer.cs` → `SendSubtitle`'a `source` ve `line`; okuma tarafı satır
  yüksekliğini zaten `ScreenTranslation.Item.LineHeight` için hesaplıyor.

## 2. Konuşmacı adı çevrilmesin

- **Sorun:** "MINE GUARD: ..." her satırda ayrı çevrilince ad tutarsız çıkıyor ("MAYIN KORUYUCU", "MADEN KORUYUCU",
  "MAYIN KORUCU").
- **Kural:** Satır başında yalnız büyük harf, rakam, boşluk ve `. ' ’ - &` içeren, en az iki harfli, en çok 30 karakterlik
  ad ve ardından `: ` varsa ad çevirmene gönderilmez, çevirinin başına olduğu gibi konur. Konuşmacı tiresi ("- ")
  önce ayrılır, sonra ad.
- **iOS'ta:** `mobile/ios/Runner/Core/SpeakerName.swift`, testleri `mobile/ios/CoreTests/SpeakerNameTest.swift`.
  Commit: `8e24545`.
- **Android:** `core/SpeakerPrefix.kt` yanına `SpeakerName` + `SpeakerNameTranslator`; `Engine.buildPipeline`'da
  `PrefixTranslator(SpeakerNameTranslator(withGlossary))`.
- **Windows:** `SubtitleSegmenter`/`GoogleGtxTranslator`'daki konuşmacı işareti kuralının yanına aynı ad kuralı.

## 3. PS5 ses çıkışı

- **Gözlem:** iPhone ilk kez Remote Play ile bağlanınca PS5'in ses çıkışı "yok" görünüyordu ve TV'den ses gelmiyordu.
- **Çözüm:** PS5'te PS tuşu, alttaki menüden Ses › Çıkış Cihazı › HDMI seçilince düzeldi ve öyle kaldı.
- **Kodda fark yok:** Üç sürüm de `CHIAKI_AUDIO_DISABLED` ile bağlanıyor.
- **Tahmin (doğrulanmadı):** Ayar PS5 kullanıcısına göre tutuluyor olabilir.
- **Rehber:** Bu not uygulama rehberine eklendi (`mobile/lib/guide_page.dart`).

## 4. Tuş yazılarını gizleme

- **Sorun:** Altyazının yanındaki oyun düğmesi yazıları ("RESUME BA", "SKIP RESUME BA") okunup çeviriye karışıyor
  ("BA'yı DEVAM ET").
- **Kural:** Satır sonundaki büyük harfli düğme sözcükleri ve yanlarındaki 1–2 karakterlik tuş işaretleri silinir. Kuyrukta
  en az bir düğme sözcüğü bulunmalı ve kuyruk ya satırın tamamı olmalı ya da cümle sonu işaretinden sonra gelmeli.
- **Ayar:** "Tuş yazılarını gizle", varsayılan olarak açık (`hideButtonHints`).
- **iOS'ta:** `mobile/ios/Runner/Core/ButtonHints.swift`, testleri `mobile/ios/CoreTests/ButtonHintsTest.swift`.

## 5. Yapılacak: telefondan Samsung TV'ye kurulum

- **Durum:** iPhone'dan da Android'den de yok. Bilgisayar sürümü kuruyor
  (`windows/src/GameTranslator.TvInstall/Samsung/`; Samsung girişi, TV'ye özel sertifika, TizenSdb ile imzalama ve sdb
  üzerinden kurulum).
- **Engel:** iOS'ta TizenSdb kütüphanesinin karşılığı yok. sdb protokolü ve widget imzalaması (XML-DSig) yazılmalı.
- **Deneme:** TV'de geliştirici modu açılmalı ve TV'ye "Host PC IP" olarak telefonun adresi girilmeli.

## 6. Topluluk yamalarını derlemeden indirme ve elle oyun seçme

- **Yamalar:** `mobile/ios/Runner/CommunityPatches.swift`. GitLab API'sinden `patches/` listesini alır, Git blob özetiyle
  doğrulanan yeni ya da değişen yamaları indirir. Uygulamayla gelenlerin özetleri derlemede
  `mobile/ios/scripts/bundle-patches.sh` ile yazılır.
- **Yama biçimleri:** Düz `{"English": "Türkçe"}` biçimi ve UTF-8 BOM'lu dosyalar okunur (`GamePacks.swift`; Kotlin
  okumuyor).
- **Oyun seçimi:** `GamePackLibrary.setPinned` (bilgisayar sürümündeki "Oyun" satırı). Seçilen oyunda yalnız o paket
  kullanılır.
