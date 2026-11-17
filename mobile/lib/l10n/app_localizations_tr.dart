// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'GameTranslator';

  @override
  String get tabTranslate => 'Çeviri';

  @override
  String get tabGuide => 'Rehber';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsGroupApp => 'UYGULAMA';

  @override
  String get settingsAppLanguage => 'Uygulama dili';

  @override
  String get settingsAppLanguageNote =>
      'Yalnızca arayüz dili; oyun ve çeviri dilini değiştirmez.';

  @override
  String get devicePs5 => 'PS5';

  @override
  String get devicePhone => 'Telefon';

  @override
  String get deviceTv => 'TV';

  @override
  String get introSkip => 'Geç';

  @override
  String get introClose => 'Kapat';

  @override
  String get introContinue => 'Devam';

  @override
  String get introDone => 'Tamam';

  @override
  String get introStartSetup => 'Kuruluma başla';

  @override
  String get introWelcomeTitle => 'Oyunu kendi dilinde oyna';

  @override
  String get introWelcomeBody =>
      'PS5\'teki oyunların altyazılarını anında Türkçeye çevirip TV\'de gösterir.';

  @override
  String get introHowTitle => 'Telefonun aradaki çevirmen';

  @override
  String get introHowBody =>
      'Telefon oyun görüntüsünü PS5\'ten Remote Play ile alır, altyazıyı okuyup çevirir ve TV\'ye gönderir. Kamera yok; ekranı kapatsan da çalışmaya devam eder.';

  @override
  String get introFlowVideo => 'Görüntü';

  @override
  String get introFlowPhone => 'Telefon';

  @override
  String get introFlowTranslates => 'Çevirir';

  @override
  String get introFlowShows => 'Gösterir';

  @override
  String get introSampleOriginal => 'We have to leave before sunrise.';

  @override
  String get introSampleTranslation => 'Gün doğmadan ayrılmalıyız.';

  @override
  String get introNeedsTitle => 'Başlamadan önce';

  @override
  String get introNeedsBody =>
      'Kurulum birkaç dakika sürer. Şunlar hazır olsun:';

  @override
  String get introNeedSecondUserTitle => 'PS5\'te ikinci bir kullanıcı';

  @override
  String get introNeedSecondUserText =>
      'Oyunu kendi hesabınla oynarsın; telefon ikinci hesapla bağlanır, böylece kumandan TV\'den kopmaz.';

  @override
  String get introNeedTvAppTitle => 'TV\'de GameTranslator uygulaması';

  @override
  String get introNeedTvAppText =>
      'Samsung, LG ve Android TV\'de çalışır. TV\'ye kurulum bilgisayardaki GameTranslator ile yapılır.';

  @override
  String get introNeedWifiTitle => 'Aynı Wi-Fi ağı';

  @override
  String get introNeedWifiText =>
      'Telefon, PS5 ve TV aynı ev ağına bağlı olmalı.';

  @override
  String get homeStateStreamingTitle => 'Çeviri açık';

  @override
  String get homeStateStreamingHint =>
      'Ekranı kapatabilirsin; çeviri arka planda sürer.';

  @override
  String get homeStateStartingTitle => 'Başlatılıyor…';

  @override
  String get homeStateStartingHint => 'Birkaç saniye sürer.';

  @override
  String get homeStateConnectingTitle => 'PS5\'e bağlanılıyor…';

  @override
  String get homeStateConnectingHint => 'PS5 açık ve aynı Wi-Fi\'de olmalı.';

  @override
  String get homeStateWakingTitle => 'PS5 uyandırılıyor…';

  @override
  String get homeStateWakingHint =>
      'Dinlenme modundan çıkması bir dakikayı bulabilir.';

  @override
  String get homeStateReconnectingTitle => 'Yeniden bağlanılıyor…';

  @override
  String get homeStateReconnectingHint => 'Bağlantı koptu, tekrar deneniyor.';

  @override
  String get homeStateStoppingTitle => 'Durduruluyor…';

  @override
  String get homeStateFailedTitle => 'Başlatılamadı';

  @override
  String get homeStateFailedHint => 'Yeniden denemek için dokun.';

  @override
  String get homeStateIdleTitle => 'Çeviri kapalı';

  @override
  String get homeStateIdleHint => 'Başlatmak için dokun.';

  @override
  String get homeNodeConnected => 'Bağlı';

  @override
  String get homeNodeWaking => 'Uyanıyor';

  @override
  String get homeNodeConnecting => 'Bağlanıyor';

  @override
  String get homeNodePaired => 'Eşleşti';

  @override
  String get homeNodeNoWifi => 'Wi-Fi yok';

  @override
  String get homeNodeTranslating => 'Çeviriyor';

  @override
  String get homeNodeReady => 'Hazır';

  @override
  String get homeNodeWaiting => 'Bekleniyor';

  @override
  String get homeNodeNotConnected => 'Bağlı değil';

  @override
  String get homeTestSentToast => 'Deneme altyazısı TV\'ye gönderildi.';

  @override
  String get homeTestNoTvToast =>
      'TV bağlı değil. Önce TV\'de GameTranslator\'ı aç.';

  @override
  String get homeUnsupportedTitle => 'Bu telefon desteklenmiyor';

  @override
  String get homeUnsupportedText =>
      'Remote Play kütüphanesi bu cihazda yüklenemedi.';

  @override
  String get homeNoWifiTitle => 'Wi-Fi bağlantısı yok';

  @override
  String get homeNoWifiText =>
      'Telefon, PS5 ve TV ile aynı Wi-Fi ağına bağlı olmalı.';

  @override
  String get homeOpenTvTitle => 'TV\'de GameTranslator\'ı aç';

  @override
  String get homeOpenTvText =>
      'TV uygulaması telefonu ağda kendisi bulur; açtıktan sonra bağlanması birkaç saniye sürer.';

  @override
  String get homeTvStuckTitle => 'TV hâlâ bağlanmadı';

  @override
  String get homeTvStuckText =>
      'TV uygulaması daha önce bilgisayara bağlandıysa eski adreste takılı kalmış olabilir. TV\'de uygulamanın verilerini bir kez temizlemek bunu düzeltir.';

  @override
  String get homeTvStuckAction => 'Adım adım göster';

  @override
  String get homeLiveGroup => 'CANLI';

  @override
  String get homeSendTest => 'TV\'ye deneme altyazısı gönder';

  @override
  String get homeAdjustRegion => 'Altyazı bölgesini ayarla';

  @override
  String get homeHowGroup => 'NASIL KULLANILIR';

  @override
  String get homeHowStep1 => 'Oyunda altyazıları aç.';

  @override
  String get homeHowStep2 => 'Yukarıdaki düğmeyle çeviriyi başlat.';

  @override
  String get homeHowStep3 =>
      'TV\'de GameTranslator\'ı aç; çeviri oyunun üstünde görünür.';

  @override
  String get homeInstallTvTitle => 'TV uygulamasını kur';

  @override
  String get homeInstallTvSubtitle => 'TV\'nde GameTranslator yoksa';

  @override
  String get homeDetailedGuide => 'Ayrıntılı rehber';

  @override
  String get homeStartTranslation => 'Çeviriyi başlat';

  @override
  String get homeStopTranslation => 'Çeviriyi durdur';

  @override
  String get homePreviewPreparing => 'Önizleme hazırlanıyor…';

  @override
  String get homeAwaitingPs5 => 'PS5 görüntüsü bekleniyor…';

  @override
  String get homeLastTranslation => 'Son çeviri';

  @override
  String get homeWaitingSubtitle =>
      'Oyunda altyazı çıkınca çevirisi burada ve TV\'de görünür.';

  @override
  String get homeRegionReadLabel => 'ÇERÇEVEDE OKUNAN';

  @override
  String get homeNothingRead => 'Şu an yazı yok.';

  @override
  String get settingsGroupTranslate => 'ÇEVİRİ';

  @override
  String get settingsSourceLanguage => 'Oyunun dili';

  @override
  String get settingsTargetLanguage => 'Çeviri dili';

  @override
  String get settingsGlossary => 'Terim sözlüğü';

  @override
  String get settingsGlossaryEmpty => 'Boş';

  @override
  String get settingsGlossaryInvalid => 'Hatalı';

  @override
  String settingsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terim',
      one: '$count terim',
      zero: '0 terim',
    );
    return '$_temp0';
  }

  @override
  String get settingsPacks => 'Oyun paketleri';

  @override
  String get settingsPacksNote =>
      'GTA V, RDR2, Elden Ring… satırları hazır Türkçesiyle';

  @override
  String get settingsGame => 'Oyun';

  @override
  String get settingsGameAuto => 'Otomatik';

  @override
  String get settingsGameAutoOption => 'Otomatik (oyunu kendisi bulur)';

  @override
  String settingsGameOptionLine(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count satır',
      one: '$count satır',
      zero: '0 satır',
    );
    return '$title · $_temp0';
  }

  @override
  String get settingsPatches => 'Topluluk yamalarını güncelle';

  @override
  String get settingsPatchesBusy => 'Yamalar denetleniyor…';

  @override
  String get settingsPatchesNote =>
      'Yeni ve güncellenen oyun yamalarını indirir (haftada bir kendiliğinden)';

  @override
  String get settingsHideButtonHints => 'Tuş yazılarını gizle';

  @override
  String get settingsHideButtonHintsNote =>
      'Altyazının yanındaki \"SKIP\", \"RESUME\" gibi düğme yazıları çevrilmez';

  @override
  String get settingsPacksFooter =>
      'Oyunun paketinde bulunan satır çeviri motoruna gitmeden paketteki Türkçesiyle gösterilir. Paketler CouchSubs topluluğundan gelir ve haftada bir yenilenir.';

  @override
  String get settingsGroupEngine => 'ÇEVİRİ MOTORU';

  @override
  String get settingsEngineGoogleNote =>
      'İnternet ister, anahtar gerekmez. Çoğu oyun için önerilir.';

  @override
  String get settingsEngineDeeplNote =>
      'Daha doğal cümleler; kendi DeepL API anahtarınla çalışır.';

  @override
  String get settingsDeeplKeyHint => 'DeepL API anahtarı';

  @override
  String get settingsEngineGeminiNote =>
      'Yapay zekâ ile en doğal Türkçe. Ücretsiz anahtarla çalışır; sınır dolunca bir dakika Google kullanılır.';

  @override
  String get settingsGeminiKeyHint => 'Gemini API anahtarı';

  @override
  String get settingsGeminiChecking => 'Deneniyor…';

  @override
  String get settingsGeminiSaveTest => 'Kaydet ve dene';

  @override
  String get settingsGeminiGetKey => 'Ücretsiz Google Gemini API anahtarı al';

  @override
  String get settingsEngineOnDevice => 'Cihazda';

  @override
  String get settingsEngineOnDeviceIosNote =>
      'İnternetsiz çalışır (Apple Çeviri). Önce iPhone\'da Ayarlar › Uygulamalar › Çeviri › İndirilen Diller\'den İngilizce ve Türkçe\'yi indir.';

  @override
  String get settingsEngineOnDeviceAndroidNote =>
      'İnternetsiz çalışır; kalitesi daha düşüktür. Dil modeli bir kez iner.';

  @override
  String get settingsEngineFooter =>
      'İnternet koparsa çeviri kendiliğinden cihazdaki modele geçer. DeepL anahtarı boşsa ya da çalışmazsa Google kullanılır.';

  @override
  String get settingsGroupRegion => 'ALTYAZI BÖLGESİ';

  @override
  String get settingsEdgeTop => 'Üst';

  @override
  String get settingsEdgeBottom => 'Alt';

  @override
  String get settingsEdgeLeft => 'Sol';

  @override
  String get settingsEdgeRight => 'Sağ';

  @override
  String get settingsResetDefault => 'Varsayılana Dön';

  @override
  String get settingsRegionFooter =>
      'Mavi çerçeveyi oyunun altyazısının çıktığı yere getir. Çerçeve dar olursa cümlenin başı ya da sonu kesilir.';

  @override
  String get settingsGroupTvLook => 'TV\'DE GÖRÜNÜM';

  @override
  String get settingsFontSize => 'Yazı boyutu';

  @override
  String get settingsFontSmall => 'Küçük';

  @override
  String get settingsFontMedium => 'Orta';

  @override
  String get settingsFontLarge => 'Büyük';

  @override
  String get settingsFontHuge => 'Dev';

  @override
  String get settingsTextColor => 'Yazı rengi';

  @override
  String get settingsWhite => 'Beyaz';

  @override
  String get settingsYellow => 'Sarı';

  @override
  String get settingsPlacement => 'Altyazının yeri';

  @override
  String get settingsPlacementCover => 'Oyunun altyazısını örterek';

  @override
  String get settingsPlacementAbove => 'Oyunun altyazısının üstünde';

  @override
  String get settingsPlacementBelow => 'Oyunun altyazısının altında';

  @override
  String get settingsPlacementFixed => 'Ekranın altında sabit';

  @override
  String get settingsBackground => 'Zemin koyuluğu';

  @override
  String get settingsBold => 'Kalın yazı';

  @override
  String get settingsSpeakerColor => 'Konuşmacı adı renkli';

  @override
  String get settingsSpeakerColorNote =>
      'Konuşanın adı (ör. ENZO:) sarı, sarı yazıda açık mavi';

  @override
  String get settingsSendTest => 'TV\'ye Deneme Altyazısı Gönder';

  @override
  String get settingsTestSent => 'Deneme altyazısı gönderildi.';

  @override
  String get settingsGroupTvApp => 'TV UYGULAMASI';

  @override
  String get settingsInstallTv => 'TV Uygulamasını Kur';

  @override
  String get settingsInstallTvNote =>
      'LG ve Android TV\'ye telefondan; güncellemek için de';

  @override
  String get settingsPaired => 'Eşleşti';

  @override
  String get settingsAutoWake => 'Dinlenme modundan uyandır';

  @override
  String get settingsAutoWakeFooter =>
      'Çeviri başlarken PS5 dinlenme modundaysa açılır.';

  @override
  String get settingsRepair => 'PS5\'i Yeniden Eşleştir';

  @override
  String get settingsChangeAccount => 'PSN Hesabını Değiştir';

  @override
  String get settingsGroupAbout => 'HAKKINDA';

  @override
  String get settingsShowIntro => 'Tanıtımı Göster';

  @override
  String get settingsLogs => 'Günlük';

  @override
  String get settingsVersion => 'Sürüm';

  @override
  String get settingsAboutFooter =>
      'Oyun görüntüsü ve hesap bilgilerin telefonda kalır. Çevrimiçi motor seçiliyse yalnızca okunan altyazı metni çeviri servisine gönderilir.\n\nGameTranslator açık kaynaklıdır (AGPL-3.0). Sony ya da PlayStation ile bağlantılı değildir.';

  @override
  String get settingsForgetTitleAccount => 'PSN hesabı değiştirilsin mi?';

  @override
  String get settingsForgetTitleConsole => 'PS5 yeniden eşleştirilsin mi?';

  @override
  String get settingsForgetMessageAccount =>
      'Kayıtlı hesap ve PS5 eşleştirmesi silinir; kurulumu baştan yaparsın.';

  @override
  String get settingsForgetMessageConsole =>
      'Kayıtlı eşleştirme silinir; PS5\'teki \"Cihaz Eşleştir\" koduyla yeniden eşleştirirsin.';

  @override
  String get settingsForgetAction => 'Sil ve Devam Et';

  @override
  String get settingsLogsEmpty => 'Henüz kayıt yok.';

  @override
  String get settingsLogTitle => 'Günlük';

  @override
  String get settingsCopy => 'Kopyala';

  @override
  String get settingsLogCopied => 'Günlük kopyalandı.';

  @override
  String get settingsLogNote =>
      'Bir sorun olduğunda destek için bu kayıtları paylaşabilirsin.';

  @override
  String get settingsRegionPreviewNote =>
      'Çeviri açıkken burada oyun görüntüsü görünür.';

  @override
  String get settingsGlossaryTitle => 'Terim Sözlüğü';

  @override
  String get settingsSave => 'Kaydet';

  @override
  String get settingsGlossaryHelp =>
      'Çevirinin yanlış çevirdiği özel adları ve oyun terimlerini burada sabitleyebilirsin. \"terms\" içindeki terimler yazdığın Türkçeyle çevrilir, \"keep\" içindeki adlar olduğu gibi kalır.';

  @override
  String get settingsGlossaryEmptyNote =>
      'Sözlük boş. Bir örnekle başlayıp kendi terimlerinle değiştirebilirsin.';

  @override
  String get settingsGlossaryAddExample => 'Örnek Ekle';

  @override
  String settingsGlossaryRead(int terms, int keep) {
    return '$terms terim, $keep korunan ad okundu.';
  }

  @override
  String get settingsGlossaryFooter =>
      'Bilgisayardaki GameTranslator sözlük dosyalarıyla aynı biçimdir; oradaki dosyanın içeriğini buraya yapıştırabilirsin. Yalnızca İngilizce → Türkçe çeviride kullanılır.';

  @override
  String get settingsGlossaryErrorShape =>
      'Sözlük süslü parantezlerle başlayan bir JSON nesnesi olmalı.';

  @override
  String get settingsGlossaryErrorSyntax =>
      'Yazım hatası var: tırnak, virgül ve parantezleri kontrol et.';

  @override
  String homeLinesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count satır',
      one: '$count satır',
      zero: '0 satır',
    );
    return '$_temp0';
  }

  @override
  String homePackUsage(String game, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count satır',
      one: '$count satır',
      zero: '0 satır',
    );
    return '$game paketi kullanılıyor · $_temp0 paketten';
  }
}
