import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'GameTranslator'**
  String get appTitle;

  /// No description provided for @tabTranslate.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri'**
  String get tabTranslate;

  /// No description provided for @tabGuide.
  ///
  /// In tr, this message translates to:
  /// **'Rehber'**
  String get tabGuide;

  /// No description provided for @tabSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get tabSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsGroupApp.
  ///
  /// In tr, this message translates to:
  /// **'UYGULAMA'**
  String get settingsGroupApp;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get settingsAppLanguage;

  /// No description provided for @settingsAppLanguageNote.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca arayüz dili; oyun ve çeviri dilini değiştirmez.'**
  String get settingsAppLanguageNote;

  /// No description provided for @commonOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get commonOk;

  /// No description provided for @setupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum'**
  String get setupTitle;

  /// No description provided for @setupSubtitleAccount.
  ///
  /// In tr, this message translates to:
  /// **'Önce PlayStation hesabını bağla.'**
  String get setupSubtitleAccount;

  /// No description provided for @setupSubtitlePs5.
  ///
  /// In tr, this message translates to:
  /// **'PS5 ile bağlantıyı tamamla.'**
  String get setupSubtitlePs5;

  /// No description provided for @setupSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'PSN ile giriş yap'**
  String get setupSignInTitle;

  /// No description provided for @setupSignInSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PlayStation Network hesabını bağla.'**
  String get setupSignInSubtitle;

  /// No description provided for @setupSignedIn.
  ///
  /// In tr, this message translates to:
  /// **'PSN hesabı bağlandı.'**
  String get setupSignedIn;

  /// No description provided for @setupChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get setupChange;

  /// No description provided for @setupSignInBody.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'teki ikinci kullanıcının (yan hesabın) PSN hesabıyla giriş yap. Böylece oyunu kendi hesabınla oynarken kumandan TV\'den kopmaz.'**
  String get setupSignInBody;

  /// No description provided for @setupSignInPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Sony\'nin kendi sayfasında yapılır. Şifren bu uygulamaya ya da başka bir yere kaydedilmez.'**
  String get setupSignInPrivacy;

  /// No description provided for @setupPairTitle.
  ///
  /// In tr, this message translates to:
  /// **'PS5 ile eşleştir'**
  String get setupPairTitle;

  /// No description provided for @setupPairSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu PS5\'inle eşleştir.'**
  String get setupPairSubtitle;

  /// No description provided for @setupPairStepA.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te ikinci kullanıcıya geç.'**
  String get setupPairStepA;

  /// No description provided for @setupPairStepB.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar › Sistem › Uzaktan Oynatma\'da \"Uzaktan Oynatmayı Etkinleştir\"i aç.'**
  String get setupPairStepB;

  /// No description provided for @setupPairStepC.
  ///
  /// In tr, this message translates to:
  /// **'\"Cihaz Eşleştir\"e gir. Ekranda 8 haneli bir kod görünür.'**
  String get setupPairStepC;

  /// No description provided for @setupFoundConsole.
  ///
  /// In tr, this message translates to:
  /// **'Bulunan konsol'**
  String get setupFoundConsole;

  /// No description provided for @setupSearching.
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor…'**
  String get setupSearching;

  /// No description provided for @setupRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get setupRefresh;

  /// No description provided for @setupNotFound.
  ///
  /// In tr, this message translates to:
  /// **'PS5 bulunamadı. Telefon ve PS5 aynı Wi-Fi ağında olmalı. PS5\'in IP adresini aşağıya elle de yazabilirsin (PS5\'te Ayarlar › Ağ › Bağlantı Durumu).'**
  String get setupNotFound;

  /// No description provided for @setupIpLabel.
  ///
  /// In tr, this message translates to:
  /// **'PS5 IP adresi'**
  String get setupIpLabel;

  /// No description provided for @setupEnterIp.
  ///
  /// In tr, this message translates to:
  /// **'IP adresini elle yaz'**
  String get setupEnterIp;

  /// No description provided for @setupPairCode.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme kodu'**
  String get setupPairCode;

  /// No description provided for @setupErrorNoHost.
  ///
  /// In tr, this message translates to:
  /// **'Önce PS5\'i seç ya da IP adresini yaz.'**
  String get setupErrorNoHost;

  /// No description provided for @setupErrorPin.
  ///
  /// In tr, this message translates to:
  /// **'PS5 ekranındaki 8 haneli kodu gir.'**
  String get setupErrorPin;

  /// No description provided for @setupErrorPairFailed.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme başarısız.'**
  String get setupErrorPairFailed;

  /// No description provided for @setupPairing.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştiriliyor…'**
  String get setupPairing;

  /// No description provided for @setupPairAction.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştir'**
  String get setupPairAction;

  /// No description provided for @setupStepOf.
  ///
  /// In tr, this message translates to:
  /// **'Adım {number} / 2'**
  String setupStepOf(int number);

  /// No description provided for @setupWaitingPsn.
  ///
  /// In tr, this message translates to:
  /// **'Önce PSN girişini tamamla.'**
  String get setupWaitingPsn;

  /// No description provided for @setupConsoleAwake.
  ///
  /// In tr, this message translates to:
  /// **'açık'**
  String get setupConsoleAwake;

  /// No description provided for @setupConsoleResting.
  ///
  /// In tr, this message translates to:
  /// **'dinlenmede'**
  String get setupConsoleResting;

  /// No description provided for @setupPsnLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'PSN Girişi'**
  String get setupPsnLoginTitle;

  /// No description provided for @setupLoginIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'Giriş tamamlanmadı.'**
  String get setupLoginIncomplete;

  /// No description provided for @setupManualId.
  ///
  /// In tr, this message translates to:
  /// **'Hesap kimliğini elle gir'**
  String get setupManualId;

  /// No description provided for @setupManualIdHelp.
  ///
  /// In tr, this message translates to:
  /// **'Giriş sayfası açılmıyorsa, Chiaki gibi araçlardan aldığın PSN hesap kimliğini buraya yapıştırabilirsin.'**
  String get setupManualIdHelp;

  /// No description provided for @setupManualIdHint.
  ///
  /// In tr, this message translates to:
  /// **'Base64 hesap kimliği'**
  String get setupManualIdHint;

  /// No description provided for @setupManualIdError.
  ///
  /// In tr, this message translates to:
  /// **'Hesap kimliği 8 baytlık base64 olmalı.'**
  String get setupManualIdError;

  /// No description provided for @setupReload.
  ///
  /// In tr, this message translates to:
  /// **'Sayfayı yeniden yükle'**
  String get setupReload;

  /// No description provided for @setupConnectingAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap bağlanıyor…'**
  String get setupConnectingAccount;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonCancel;

  /// No description provided for @splashTagline.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu kendi dilinde oyna'**
  String get splashTagline;

  /// No description provided for @devicePs5.
  ///
  /// In tr, this message translates to:
  /// **'PS5'**
  String get devicePs5;

  /// No description provided for @devicePhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get devicePhone;

  /// No description provided for @deviceTv.
  ///
  /// In tr, this message translates to:
  /// **'TV'**
  String get deviceTv;

  /// No description provided for @introSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get introSkip;

  /// No description provided for @introClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get introClose;

  /// No description provided for @introContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get introContinue;

  /// No description provided for @introDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get introDone;

  /// No description provided for @introStartSetup.
  ///
  /// In tr, this message translates to:
  /// **'Kuruluma başla'**
  String get introStartSetup;

  /// No description provided for @introWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu kendi dilinde oyna'**
  String get introWelcomeTitle;

  /// No description provided for @introWelcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'teki oyunların altyazılarını anında Türkçeye çevirip TV\'de gösterir.'**
  String get introWelcomeBody;

  /// No description provided for @introHowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun aradaki çevirmen'**
  String get introHowTitle;

  /// No description provided for @introHowBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon oyun görüntüsünü PS5\'ten Remote Play ile alır, altyazıyı okuyup çevirir ve TV\'ye gönderir. Kamera yok; ekranı kapatsan da çalışmaya devam eder.'**
  String get introHowBody;

  /// No description provided for @introFlowVideo.
  ///
  /// In tr, this message translates to:
  /// **'Görüntü'**
  String get introFlowVideo;

  /// No description provided for @introFlowPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get introFlowPhone;

  /// No description provided for @introFlowTranslates.
  ///
  /// In tr, this message translates to:
  /// **'Çevirir'**
  String get introFlowTranslates;

  /// No description provided for @introFlowShows.
  ///
  /// In tr, this message translates to:
  /// **'Gösterir'**
  String get introFlowShows;

  /// No description provided for @introSampleOriginal.
  ///
  /// In tr, this message translates to:
  /// **'We have to leave before sunrise.'**
  String get introSampleOriginal;

  /// No description provided for @introSampleTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Gün doğmadan ayrılmalıyız.'**
  String get introSampleTranslation;

  /// No description provided for @introNeedsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlamadan önce'**
  String get introNeedsTitle;

  /// No description provided for @introNeedsBody.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum birkaç dakika sürer. Şunlar hazır olsun:'**
  String get introNeedsBody;

  /// No description provided for @introNeedSecondUserTitle.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te ikinci bir kullanıcı'**
  String get introNeedSecondUserTitle;

  /// No description provided for @introNeedSecondUserText.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu kendi hesabınla oynarsın; telefon ikinci hesapla bağlanır, böylece kumandan TV\'den kopmaz.'**
  String get introNeedSecondUserText;

  /// No description provided for @introNeedTvAppTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator uygulaması'**
  String get introNeedTvAppTitle;

  /// No description provided for @introNeedTvAppText.
  ///
  /// In tr, this message translates to:
  /// **'Samsung, LG ve Android TV\'de çalışır. TV\'ye kurulum bilgisayardaki GameTranslator ile yapılır.'**
  String get introNeedTvAppText;

  /// No description provided for @introNeedWifiTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı Wi-Fi ağı'**
  String get introNeedWifiTitle;

  /// No description provided for @introNeedWifiText.
  ///
  /// In tr, this message translates to:
  /// **'Telefon, PS5 ve TV aynı ev ağına bağlı olmalı.'**
  String get introNeedWifiText;

  /// No description provided for @homeStateStreamingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri açık'**
  String get homeStateStreamingTitle;

  /// No description provided for @homeStateStreamingHint.
  ///
  /// In tr, this message translates to:
  /// **'Ekranı kapatabilirsin; çeviri arka planda sürer.'**
  String get homeStateStreamingHint;

  /// No description provided for @homeStateStartingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlatılıyor…'**
  String get homeStateStartingTitle;

  /// No description provided for @homeStateStartingHint.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç saniye sürer.'**
  String get homeStateStartingHint;

  /// No description provided for @homeStateConnectingTitle.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'e bağlanılıyor…'**
  String get homeStateConnectingTitle;

  /// No description provided for @homeStateConnectingHint.
  ///
  /// In tr, this message translates to:
  /// **'PS5 açık ve aynı Wi-Fi\'de olmalı.'**
  String get homeStateConnectingHint;

  /// No description provided for @homeStateWakingTitle.
  ///
  /// In tr, this message translates to:
  /// **'PS5 uyandırılıyor…'**
  String get homeStateWakingTitle;

  /// No description provided for @homeStateWakingHint.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme modundan çıkması bir dakikayı bulabilir.'**
  String get homeStateWakingHint;

  /// No description provided for @homeStateReconnectingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden bağlanılıyor…'**
  String get homeStateReconnectingTitle;

  /// No description provided for @homeStateReconnectingHint.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptu, tekrar deneniyor.'**
  String get homeStateReconnectingHint;

  /// No description provided for @homeStateStoppingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Durduruluyor…'**
  String get homeStateStoppingTitle;

  /// No description provided for @homeStateFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlatılamadı'**
  String get homeStateFailedTitle;

  /// No description provided for @homeStateFailedHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden denemek için dokun.'**
  String get homeStateFailedHint;

  /// No description provided for @homeStateIdleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri kapalı'**
  String get homeStateIdleTitle;

  /// No description provided for @homeStateIdleHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlatmak için dokun.'**
  String get homeStateIdleHint;

  /// No description provided for @homeNodeConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get homeNodeConnected;

  /// No description provided for @homeNodeWaking.
  ///
  /// In tr, this message translates to:
  /// **'Uyanıyor'**
  String get homeNodeWaking;

  /// No description provided for @homeNodeConnecting.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor'**
  String get homeNodeConnecting;

  /// No description provided for @homeNodePaired.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşti'**
  String get homeNodePaired;

  /// No description provided for @homeNodeNoWifi.
  ///
  /// In tr, this message translates to:
  /// **'Wi-Fi yok'**
  String get homeNodeNoWifi;

  /// No description provided for @homeNodeTranslating.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyor'**
  String get homeNodeTranslating;

  /// No description provided for @homeNodeReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get homeNodeReady;

  /// No description provided for @homeNodeWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Bekleniyor'**
  String get homeNodeWaiting;

  /// No description provided for @homeNodeNotConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get homeNodeNotConnected;

  /// No description provided for @homeTestSentToast.
  ///
  /// In tr, this message translates to:
  /// **'Deneme altyazısı TV\'ye gönderildi.'**
  String get homeTestSentToast;

  /// No description provided for @homeTestNoTvToast.
  ///
  /// In tr, this message translates to:
  /// **'TV bağlı değil. Önce TV\'de GameTranslator\'ı aç.'**
  String get homeTestNoTvToast;

  /// No description provided for @homeUnsupportedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu telefon desteklenmiyor'**
  String get homeUnsupportedTitle;

  /// No description provided for @homeUnsupportedText.
  ///
  /// In tr, this message translates to:
  /// **'Remote Play kütüphanesi bu cihazda yüklenemedi.'**
  String get homeUnsupportedText;

  /// No description provided for @homeNoWifiTitle.
  ///
  /// In tr, this message translates to:
  /// **'Wi-Fi bağlantısı yok'**
  String get homeNoWifiTitle;

  /// No description provided for @homeNoWifiText.
  ///
  /// In tr, this message translates to:
  /// **'Telefon, PS5 ve TV ile aynı Wi-Fi ağına bağlı olmalı.'**
  String get homeNoWifiText;

  /// No description provided for @homeOpenTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator\'ı aç'**
  String get homeOpenTvTitle;

  /// No description provided for @homeOpenTvText.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması telefonu ağda kendisi bulur; açtıktan sonra bağlanması birkaç saniye sürer.'**
  String get homeOpenTvText;

  /// No description provided for @homeTvStuckTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV hâlâ bağlanmadı'**
  String get homeTvStuckTitle;

  /// No description provided for @homeTvStuckText.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması daha önce bilgisayara bağlandıysa eski adreste takılı kalmış olabilir. TV\'de uygulamanın verilerini bir kez temizlemek bunu düzeltir.'**
  String get homeTvStuckText;

  /// No description provided for @homeTvStuckAction.
  ///
  /// In tr, this message translates to:
  /// **'Adım adım göster'**
  String get homeTvStuckAction;

  /// No description provided for @homeLiveGroup.
  ///
  /// In tr, this message translates to:
  /// **'CANLI'**
  String get homeLiveGroup;

  /// No description provided for @homeSendTest.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye deneme altyazısı gönder'**
  String get homeSendTest;

  /// No description provided for @homeAdjustRegion.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı bölgesini ayarla'**
  String get homeAdjustRegion;

  /// No description provided for @homeHowGroup.
  ///
  /// In tr, this message translates to:
  /// **'NASIL KULLANILIR'**
  String get homeHowGroup;

  /// No description provided for @homeHowStep1.
  ///
  /// In tr, this message translates to:
  /// **'Oyunda altyazıları aç.'**
  String get homeHowStep1;

  /// No description provided for @homeHowStep2.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdaki düğmeyle çeviriyi başlat.'**
  String get homeHowStep2;

  /// No description provided for @homeHowStep3.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator\'ı aç; çeviri oyunun üstünde görünür.'**
  String get homeHowStep3;

  /// No description provided for @homeInstallTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulamasını kur'**
  String get homeInstallTvTitle;

  /// No description provided for @homeInstallTvSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nde GameTranslator yoksa'**
  String get homeInstallTvSubtitle;

  /// No description provided for @homeDetailedGuide.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntılı rehber'**
  String get homeDetailedGuide;

  /// No description provided for @homeStartTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi başlat'**
  String get homeStartTranslation;

  /// No description provided for @homeStopTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi durdur'**
  String get homeStopTranslation;

  /// No description provided for @homePreviewPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme hazırlanıyor…'**
  String get homePreviewPreparing;

  /// No description provided for @homeAwaitingPs5.
  ///
  /// In tr, this message translates to:
  /// **'PS5 görüntüsü bekleniyor…'**
  String get homeAwaitingPs5;

  /// No description provided for @homeLastTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Son çeviri'**
  String get homeLastTranslation;

  /// No description provided for @homeWaitingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyunda altyazı çıkınca çevirisi burada ve TV\'de görünür.'**
  String get homeWaitingSubtitle;

  /// No description provided for @homeRegionReadLabel.
  ///
  /// In tr, this message translates to:
  /// **'ÇERÇEVEDE OKUNAN'**
  String get homeRegionReadLabel;

  /// No description provided for @homeNothingRead.
  ///
  /// In tr, this message translates to:
  /// **'Şu an yazı yok.'**
  String get homeNothingRead;

  /// No description provided for @settingsGroupTranslate.
  ///
  /// In tr, this message translates to:
  /// **'ÇEVİRİ'**
  String get settingsGroupTranslate;

  /// No description provided for @settingsSourceLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun dili'**
  String get settingsSourceLanguage;

  /// No description provided for @settingsTargetLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri dili'**
  String get settingsTargetLanguage;

  /// No description provided for @settingsGlossary.
  ///
  /// In tr, this message translates to:
  /// **'Terim sözlüğü'**
  String get settingsGlossary;

  /// No description provided for @settingsGlossaryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Boş'**
  String get settingsGlossaryEmpty;

  /// No description provided for @settingsGlossaryInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı'**
  String get settingsGlossaryInvalid;

  /// No description provided for @settingsGlossaryCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{0 terim} one{{count} terim} other{{count} terim}}'**
  String settingsGlossaryCount(int count);

  /// No description provided for @settingsPacks.
  ///
  /// In tr, this message translates to:
  /// **'Oyun paketleri'**
  String get settingsPacks;

  /// No description provided for @settingsPacksNote.
  ///
  /// In tr, this message translates to:
  /// **'GTA V, RDR2, Elden Ring… satırları hazır Türkçesiyle'**
  String get settingsPacksNote;

  /// No description provided for @settingsGame.
  ///
  /// In tr, this message translates to:
  /// **'Oyun'**
  String get settingsGame;

  /// No description provided for @settingsGameAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get settingsGameAuto;

  /// No description provided for @settingsGameAutoOption.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik (oyunu kendisi bulur)'**
  String get settingsGameAutoOption;

  /// No description provided for @settingsGameOptionLine.
  ///
  /// In tr, this message translates to:
  /// **'{title} · {count, plural, =0{0 satır} one{{count} satır} other{{count} satır}}'**
  String settingsGameOptionLine(String title, int count);

  /// No description provided for @settingsPatches.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk yamalarını güncelle'**
  String get settingsPatches;

  /// No description provided for @settingsPatchesBusy.
  ///
  /// In tr, this message translates to:
  /// **'Yamalar denetleniyor…'**
  String get settingsPatchesBusy;

  /// No description provided for @settingsPatchesNote.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ve güncellenen oyun yamalarını indirir (haftada bir kendiliğinden)'**
  String get settingsPatchesNote;

  /// No description provided for @settingsHideButtonHints.
  ///
  /// In tr, this message translates to:
  /// **'Tuş yazılarını gizle'**
  String get settingsHideButtonHints;

  /// No description provided for @settingsHideButtonHintsNote.
  ///
  /// In tr, this message translates to:
  /// **'Altyazının yanındaki \"SKIP\", \"RESUME\" gibi düğme yazıları çevrilmez'**
  String get settingsHideButtonHintsNote;

  /// No description provided for @settingsPacksFooter.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun paketinde bulunan satır çeviri motoruna gitmeden paketteki Türkçesiyle gösterilir. Paketler CouchSubs topluluğundan gelir ve haftada bir yenilenir.'**
  String get settingsPacksFooter;

  /// No description provided for @settingsGroupEngine.
  ///
  /// In tr, this message translates to:
  /// **'ÇEVİRİ MOTORU'**
  String get settingsGroupEngine;

  /// No description provided for @settingsEngineGoogleNote.
  ///
  /// In tr, this message translates to:
  /// **'İnternet ister, anahtar gerekmez. Çoğu oyun için önerilir.'**
  String get settingsEngineGoogleNote;

  /// No description provided for @settingsEngineDeeplNote.
  ///
  /// In tr, this message translates to:
  /// **'Daha doğal cümleler; kendi DeepL API anahtarınla çalışır.'**
  String get settingsEngineDeeplNote;

  /// No description provided for @settingsDeeplKeyHint.
  ///
  /// In tr, this message translates to:
  /// **'DeepL API anahtarı'**
  String get settingsDeeplKeyHint;

  /// No description provided for @settingsEngineGeminiNote.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zekâ ile en doğal Türkçe. Ücretsiz anahtarla çalışır; sınır dolunca bir dakika Google kullanılır.'**
  String get settingsEngineGeminiNote;

  /// No description provided for @settingsGeminiKeyHint.
  ///
  /// In tr, this message translates to:
  /// **'Gemini API anahtarı'**
  String get settingsGeminiKeyHint;

  /// No description provided for @settingsGeminiChecking.
  ///
  /// In tr, this message translates to:
  /// **'Deneniyor…'**
  String get settingsGeminiChecking;

  /// No description provided for @settingsGeminiSaveTest.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve dene'**
  String get settingsGeminiSaveTest;

  /// No description provided for @settingsGeminiGetKey.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Google Gemini API anahtarı al'**
  String get settingsGeminiGetKey;

  /// No description provided for @settingsEngineOnDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda'**
  String get settingsEngineOnDevice;

  /// No description provided for @settingsEngineOnDeviceIosNote.
  ///
  /// In tr, this message translates to:
  /// **'İnternetsiz çalışır (Apple Çeviri). Önce iPhone\'da Ayarlar › Uygulamalar › Çeviri › İndirilen Diller\'den İngilizce ve Türkçe\'yi indir.'**
  String get settingsEngineOnDeviceIosNote;

  /// No description provided for @settingsEngineOnDeviceAndroidNote.
  ///
  /// In tr, this message translates to:
  /// **'İnternetsiz çalışır; kalitesi daha düşüktür. Dil modeli bir kez iner.'**
  String get settingsEngineOnDeviceAndroidNote;

  /// No description provided for @settingsEngineFooter.
  ///
  /// In tr, this message translates to:
  /// **'İnternet koparsa çeviri kendiliğinden cihazdaki modele geçer. DeepL anahtarı boşsa ya da çalışmazsa Google kullanılır.'**
  String get settingsEngineFooter;

  /// No description provided for @settingsGroupRegion.
  ///
  /// In tr, this message translates to:
  /// **'ALTYAZI BÖLGESİ'**
  String get settingsGroupRegion;

  /// No description provided for @settingsEdgeTop.
  ///
  /// In tr, this message translates to:
  /// **'Üst'**
  String get settingsEdgeTop;

  /// No description provided for @settingsEdgeBottom.
  ///
  /// In tr, this message translates to:
  /// **'Alt'**
  String get settingsEdgeBottom;

  /// No description provided for @settingsEdgeLeft.
  ///
  /// In tr, this message translates to:
  /// **'Sol'**
  String get settingsEdgeLeft;

  /// No description provided for @settingsEdgeRight.
  ///
  /// In tr, this message translates to:
  /// **'Sağ'**
  String get settingsEdgeRight;

  /// No description provided for @settingsResetDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılana Dön'**
  String get settingsResetDefault;

  /// No description provided for @settingsRegionFooter.
  ///
  /// In tr, this message translates to:
  /// **'Mavi çerçeveyi oyunun altyazısının çıktığı yere getir. Çerçeve dar olursa cümlenin başı ya da sonu kesilir.'**
  String get settingsRegionFooter;

  /// No description provided for @settingsGroupTvLook.
  ///
  /// In tr, this message translates to:
  /// **'TV\'DE GÖRÜNÜM'**
  String get settingsGroupTvLook;

  /// No description provided for @settingsFontSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu'**
  String get settingsFontSize;

  /// No description provided for @settingsFontSmall.
  ///
  /// In tr, this message translates to:
  /// **'Küçük'**
  String get settingsFontSmall;

  /// No description provided for @settingsFontMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get settingsFontMedium;

  /// No description provided for @settingsFontLarge.
  ///
  /// In tr, this message translates to:
  /// **'Büyük'**
  String get settingsFontLarge;

  /// No description provided for @settingsFontHuge.
  ///
  /// In tr, this message translates to:
  /// **'Dev'**
  String get settingsFontHuge;

  /// No description provided for @settingsTextColor.
  ///
  /// In tr, this message translates to:
  /// **'Yazı rengi'**
  String get settingsTextColor;

  /// No description provided for @settingsWhite.
  ///
  /// In tr, this message translates to:
  /// **'Beyaz'**
  String get settingsWhite;

  /// No description provided for @settingsYellow.
  ///
  /// In tr, this message translates to:
  /// **'Sarı'**
  String get settingsYellow;

  /// No description provided for @settingsPlacement.
  ///
  /// In tr, this message translates to:
  /// **'Altyazının yeri'**
  String get settingsPlacement;

  /// No description provided for @settingsPlacementCover.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun altyazısını örterek'**
  String get settingsPlacementCover;

  /// No description provided for @settingsPlacementAbove.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun altyazısının üstünde'**
  String get settingsPlacementAbove;

  /// No description provided for @settingsPlacementBelow.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun altyazısının altında'**
  String get settingsPlacementBelow;

  /// No description provided for @settingsPlacementFixed.
  ///
  /// In tr, this message translates to:
  /// **'Ekranın altında sabit'**
  String get settingsPlacementFixed;

  /// No description provided for @settingsBackground.
  ///
  /// In tr, this message translates to:
  /// **'Zemin koyuluğu'**
  String get settingsBackground;

  /// No description provided for @settingsBold.
  ///
  /// In tr, this message translates to:
  /// **'Kalın yazı'**
  String get settingsBold;

  /// No description provided for @settingsSpeakerColor.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmacı adı renkli'**
  String get settingsSpeakerColor;

  /// No description provided for @settingsSpeakerColorNote.
  ///
  /// In tr, this message translates to:
  /// **'Konuşanın adı (ör. ENZO:) sarı, sarı yazıda açık mavi'**
  String get settingsSpeakerColorNote;

  /// No description provided for @settingsSendTest.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye Deneme Altyazısı Gönder'**
  String get settingsSendTest;

  /// No description provided for @settingsTestSent.
  ///
  /// In tr, this message translates to:
  /// **'Deneme altyazısı gönderildi.'**
  String get settingsTestSent;

  /// No description provided for @settingsGroupTvApp.
  ///
  /// In tr, this message translates to:
  /// **'TV UYGULAMASI'**
  String get settingsGroupTvApp;

  /// No description provided for @settingsInstallTv.
  ///
  /// In tr, this message translates to:
  /// **'TV Uygulamasını Kur'**
  String get settingsInstallTv;

  /// No description provided for @settingsInstallTvNote.
  ///
  /// In tr, this message translates to:
  /// **'LG ve Android TV\'ye telefondan; güncellemek için de'**
  String get settingsInstallTvNote;

  /// No description provided for @settingsPaired.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşti'**
  String get settingsPaired;

  /// No description provided for @settingsAutoWake.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme modundan uyandır'**
  String get settingsAutoWake;

  /// No description provided for @settingsAutoWakeFooter.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri başlarken PS5 dinlenme modundaysa açılır.'**
  String get settingsAutoWakeFooter;

  /// No description provided for @settingsRepair.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'i Yeniden Eşleştir'**
  String get settingsRepair;

  /// No description provided for @settingsChangeAccount.
  ///
  /// In tr, this message translates to:
  /// **'PSN Hesabını Değiştir'**
  String get settingsChangeAccount;

  /// No description provided for @settingsGroupAbout.
  ///
  /// In tr, this message translates to:
  /// **'HAKKINDA'**
  String get settingsGroupAbout;

  /// No description provided for @settingsShowIntro.
  ///
  /// In tr, this message translates to:
  /// **'Tanıtımı Göster'**
  String get settingsShowIntro;

  /// No description provided for @settingsLogs.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get settingsLogs;

  /// No description provided for @settingsVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get settingsVersion;

  /// No description provided for @settingsAboutFooter.
  ///
  /// In tr, this message translates to:
  /// **'Oyun görüntüsü ve hesap bilgilerin telefonda kalır. Çevrimiçi motor seçiliyse yalnızca okunan altyazı metni çeviri servisine gönderilir.\n\nGameTranslator açık kaynaklıdır (AGPL-3.0). Sony ya da PlayStation ile bağlantılı değildir.'**
  String get settingsAboutFooter;

  /// No description provided for @settingsForgetTitleAccount.
  ///
  /// In tr, this message translates to:
  /// **'PSN hesabı değiştirilsin mi?'**
  String get settingsForgetTitleAccount;

  /// No description provided for @settingsForgetTitleConsole.
  ///
  /// In tr, this message translates to:
  /// **'PS5 yeniden eşleştirilsin mi?'**
  String get settingsForgetTitleConsole;

  /// No description provided for @settingsForgetMessageAccount.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı hesap ve PS5 eşleştirmesi silinir; kurulumu baştan yaparsın.'**
  String get settingsForgetMessageAccount;

  /// No description provided for @settingsForgetMessageConsole.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı eşleştirme silinir; PS5\'teki \"Cihaz Eşleştir\" koduyla yeniden eşleştirirsin.'**
  String get settingsForgetMessageConsole;

  /// No description provided for @settingsForgetAction.
  ///
  /// In tr, this message translates to:
  /// **'Sil ve Devam Et'**
  String get settingsForgetAction;

  /// No description provided for @settingsLogsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıt yok.'**
  String get settingsLogsEmpty;

  /// No description provided for @settingsLogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get settingsLogTitle;

  /// No description provided for @settingsCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get settingsCopy;

  /// No description provided for @settingsLogCopied.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kopyalandı.'**
  String get settingsLogCopied;

  /// No description provided for @settingsLogNote.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun olduğunda destek için bu kayıtları paylaşabilirsin.'**
  String get settingsLogNote;

  /// No description provided for @settingsRegionPreviewNote.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri açıkken burada oyun görüntüsü görünür.'**
  String get settingsRegionPreviewNote;

  /// No description provided for @settingsGlossaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Terim Sözlüğü'**
  String get settingsGlossaryTitle;

  /// No description provided for @settingsSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get settingsSave;

  /// No description provided for @settingsGlossaryHelp.
  ///
  /// In tr, this message translates to:
  /// **'Çevirinin yanlış çevirdiği özel adları ve oyun terimlerini burada sabitleyebilirsin. \"terms\" içindeki terimler yazdığın Türkçeyle çevrilir, \"keep\" içindeki adlar olduğu gibi kalır.'**
  String get settingsGlossaryHelp;

  /// No description provided for @settingsGlossaryEmptyNote.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük boş. Bir örnekle başlayıp kendi terimlerinle değiştirebilirsin.'**
  String get settingsGlossaryEmptyNote;

  /// No description provided for @settingsGlossaryAddExample.
  ///
  /// In tr, this message translates to:
  /// **'Örnek Ekle'**
  String get settingsGlossaryAddExample;

  /// No description provided for @settingsGlossaryRead.
  ///
  /// In tr, this message translates to:
  /// **'{terms} terim, {keep} korunan ad okundu.'**
  String settingsGlossaryRead(int terms, int keep);

  /// No description provided for @settingsGlossaryFooter.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator sözlük dosyalarıyla aynı biçimdir; oradaki dosyanın içeriğini buraya yapıştırabilirsin. Yalnızca İngilizce → Türkçe çeviride kullanılır.'**
  String get settingsGlossaryFooter;

  /// No description provided for @settingsGlossaryErrorShape.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük süslü parantezlerle başlayan bir JSON nesnesi olmalı.'**
  String get settingsGlossaryErrorShape;

  /// No description provided for @settingsGlossaryErrorSyntax.
  ///
  /// In tr, this message translates to:
  /// **'Yazım hatası var: tırnak, virgül ve parantezleri kontrol et.'**
  String get settingsGlossaryErrorSyntax;

  /// No description provided for @homeLinesCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{0 satır} one{{count} satır} other{{count} satır}}'**
  String homeLinesCount(int count);

  /// No description provided for @homePackUsage.
  ///
  /// In tr, this message translates to:
  /// **'{game} paketi kullanılıyor · {count, plural, =0{0 satır} one{{count} satır} other{{count} satır}} paketten'**
  String homePackUsage(String game, int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
