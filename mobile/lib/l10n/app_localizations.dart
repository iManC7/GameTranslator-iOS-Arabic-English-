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

  /// No description provided for @guideIntro.
  ///
  /// In tr, this message translates to:
  /// **'Kurulumdan sorun gidermeye kadar her şey, adım adım.'**
  String get guideIntro;

  /// No description provided for @guidePhoneAddress.
  ///
  /// In tr, this message translates to:
  /// **'telefonun adresi'**
  String get guidePhoneAddress;

  /// No description provided for @guideGroupStart.
  ///
  /// In tr, this message translates to:
  /// **'BAŞLANGIÇ'**
  String get guideGroupStart;

  /// No description provided for @guideGroupUsage.
  ///
  /// In tr, this message translates to:
  /// **'KULLANIM'**
  String get guideGroupUsage;

  /// No description provided for @guideGroupHelp.
  ///
  /// In tr, this message translates to:
  /// **'YARDIM'**
  String get guideGroupHelp;

  /// No description provided for @guideNextChapter.
  ///
  /// In tr, this message translates to:
  /// **'SONRAKİ BÖLÜM'**
  String get guideNextChapter;

  /// No description provided for @guideTvHelpTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV Bağlanmıyor'**
  String get guideTvHelpTitle;

  /// No description provided for @gHowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl çalışır?'**
  String get gHowTitle;

  /// No description provided for @gHowSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir bakışta bütün düzen'**
  String get gHowSubtitle;

  /// No description provided for @gHowLead.
  ///
  /// In tr, this message translates to:
  /// **'GameTranslator üç cihazı birbirine bağlar. Oyun PS5\'te çalışır, sen TV\'de oynarsın; telefon arada çevirmenlik yapar:'**
  String get gHowLead;

  /// No description provided for @gHowStep1.
  ///
  /// In tr, this message translates to:
  /// **'Telefon, oyun görüntüsünü PS5\'ten Remote Play (Uzaktan Oynatma) ile alır. Kamera kullanılmaz.'**
  String get gHowStep1;

  /// No description provided for @gHowStep2.
  ///
  /// In tr, this message translates to:
  /// **'Görüntüde altyazının çıktığı bölgeyi okur ve yazıyı çevirir.'**
  String get gHowStep2;

  /// No description provided for @gHowStep3.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi aynı Wi-Fi\'deki TV\'ye gönderir. TV\'deki GameTranslator uygulaması onu oyunun üstünde gösterir.'**
  String get gHowStep3;

  /// No description provided for @gHowNeedsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neler gerekli?'**
  String get gHowNeedsTitle;

  /// No description provided for @gHowNeed1.
  ///
  /// In tr, this message translates to:
  /// **'PS5 ve üzerinde ikinci bir kullanıcı (aşağıda anlatılıyor).'**
  String get gHowNeed1;

  /// No description provided for @gHowNeed2.
  ///
  /// In tr, this message translates to:
  /// **'GameTranslator TV uygulamasının kurulu olduğu bir TV: LG, Samsung ya da Android TV / Google TV.'**
  String get gHowNeed2;

  /// No description provided for @gHowNeed3.
  ///
  /// In tr, this message translates to:
  /// **'Telefon, PS5 ve TV\'nin bağlı olduğu tek bir ev ağı (Wi-Fi).'**
  String get gHowNeed3;

  /// No description provided for @gHowNeed4.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi çeviri için internet. İnternetsiz çalışan bir çeviri seçeneği de var.'**
  String get gHowNeed4;

  /// No description provided for @gHowTip.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum bir kez yapılır. Sonrasında tek yapacağın: çeviriyi başlatmak ve TV\'de uygulamayı açmak.'**
  String get gHowTip;

  /// No description provided for @gPs5Title.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'i hazırla'**
  String get gPs5Title;

  /// No description provided for @gPs5Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'İkinci kullanıcı ve Uzaktan Oynatma'**
  String get gPs5Subtitle;

  /// No description provided for @gPs5UserTitle.
  ///
  /// In tr, this message translates to:
  /// **'1. İkinci bir kullanıcı ekle'**
  String get gPs5UserTitle;

  /// No description provided for @gPs5UserBody.
  ///
  /// In tr, this message translates to:
  /// **'PS5, Uzaktan Oynatma ile bağlanan cihazı o kullanıcının kumandası sayar. Telefon senin hesabınla bağlanırsa elindeki kumanda TV\'den kopar. Bu yüzden telefon ayrı bir kullanıcıyla bağlanır; sen kendi hesabınla oynamaya devam edersin.'**
  String get gPs5UserBody;

  /// No description provided for @gPs5UserStep1.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te yeni bir kullanıcı ekle (ana ekrandaki profil resminden Kullanıcı Değiştir › Kullanıcı Ekle).'**
  String get gPs5UserStep1;

  /// No description provided for @gPs5UserStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcıya bir PSN hesabıyla giriş yap. Hesabın yoksa ücretsiz açabilirsin; PS Plus gerekmez.'**
  String get gPs5UserStep2;

  /// No description provided for @gPs5UserStep3.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda PSN girişini de bu ikinci hesapla yapacaksın.'**
  String get gPs5UserStep3;

  /// No description provided for @gPs5RemoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'2. Uzaktan Oynatmayı aç'**
  String get gPs5RemoteTitle;

  /// No description provided for @gPs5RemoteStep1.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te ikinci kullanıcıya geç.'**
  String get gPs5RemoteStep1;

  /// No description provided for @gPs5RemoteStep2.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar › Sistem › Uzaktan Oynatma\'ya gir.'**
  String get gPs5RemoteStep2;

  /// No description provided for @gPs5RemoteStep3.
  ///
  /// In tr, this message translates to:
  /// **'\"Uzaktan Oynatmayı Etkinleştir\"i aç.'**
  String get gPs5RemoteStep3;

  /// No description provided for @gPs5WakeTitle.
  ///
  /// In tr, this message translates to:
  /// **'3. Dinlenme modundan uyandırma (isteğe bağlı)'**
  String get gPs5WakeTitle;

  /// No description provided for @gPs5WakeBody.
  ///
  /// In tr, this message translates to:
  /// **'PS5 dinlenme modundayken çeviriyi başlattığında telefonun onu uyandırabilmesi için:'**
  String get gPs5WakeBody;

  /// No description provided for @gPs5WakeStep1.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar › Sistem › Güç Tasarrufu › Dinlenme Modunda Kullanılabilen Özellikler\'e gir.'**
  String get gPs5WakeStep1;

  /// No description provided for @gPs5WakeStep2.
  ///
  /// In tr, this message translates to:
  /// **'\"İnternete Bağlı Kal\" ve \"PS5\'in Ağdan Açılmasını Etkinleştir\" seçeneklerini aç.'**
  String get gPs5WakeStep2;

  /// No description provided for @gPs5Tip.
  ///
  /// In tr, this message translates to:
  /// **'Uyandırmayı istemiyorsan telefonda Ayarlar › PS5 › \"Dinlenme modundaysa uyandır\"ı kapatabilirsin.'**
  String get gPs5Tip;

  /// No description provided for @gPairTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu PS5 ile eşleştir'**
  String get gPairTitle;

  /// No description provided for @gPairSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PSN girişi ve 8 haneli kod'**
  String get gPairSubtitle;

  /// No description provided for @gPairSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'1. PSN ile giriş yap'**
  String get gPairSignInTitle;

  /// No description provided for @gPairSignInStep1.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum ekranında \"PSN ile giriş yap\"a dokun. Sony\'nin kendi giriş sayfası açılır.'**
  String get gPairSignInStep1;

  /// No description provided for @gPairSignInStep2.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'teki ikinci kullanıcının hesabıyla giriş yap.'**
  String get gPairSignInStep2;

  /// No description provided for @gPairSignInStep3.
  ///
  /// In tr, this message translates to:
  /// **'Giriş bitince uygulama kuruluma kendiliğinden döner ve \"PSN hesabı bağlandı\" yazar.'**
  String get gPairSignInStep3;

  /// No description provided for @gPairSignInTip.
  ///
  /// In tr, this message translates to:
  /// **'Şifren doğrudan Sony\'ye gider; uygulama yalnızca hesabının kimlik numarasını saklar.'**
  String get gPairSignInTip;

  /// No description provided for @gPairCodeTitle.
  ///
  /// In tr, this message translates to:
  /// **'2. Eşleştirme kodunu gir'**
  String get gPairCodeTitle;

  /// No description provided for @gPairCodeStep1.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te ikinci kullanıcıdayken Ayarlar › Sistem › Uzaktan Oynatma › \"Cihaz Eşleştir\"e gir.'**
  String get gPairCodeStep1;

  /// No description provided for @gPairCodeStep2.
  ///
  /// In tr, this message translates to:
  /// **'Ekranda 8 haneli bir kod ve geri sayım görünür. Kod yaklaşık 5 dakika geçerlidir.'**
  String get gPairCodeStep2;

  /// No description provided for @gPairCodeStep3.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda \"Bulunan konsol\" listesinden PS5\'ini seç.'**
  String get gPairCodeStep3;

  /// No description provided for @gPairCodeStep4.
  ///
  /// In tr, this message translates to:
  /// **'Kodu kutulara yaz ve \"Eşleştir\"e dokun.'**
  String get gPairCodeStep4;

  /// No description provided for @gPairMissingTitle.
  ///
  /// In tr, this message translates to:
  /// **'PS5 listede yoksa'**
  String get gPairMissingTitle;

  /// No description provided for @gPairMissing1.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ve PS5 aynı Wi-Fi ağında mı kontrol et; misafir ağı ya da mobil veri olmamalı.'**
  String get gPairMissing1;

  /// No description provided for @gPairMissing2.
  ///
  /// In tr, this message translates to:
  /// **'\"Yenile\"ye dokun.'**
  String get gPairMissing2;

  /// No description provided for @gPairMissing3.
  ///
  /// In tr, this message translates to:
  /// **'Yine çıkmazsa \"IP adresini elle yaz\"a dokun. Adres PS5\'te Ayarlar › Ağ › Bağlantı Durumu › Bağlantı Durumunu Görüntüle\'de yazar.'**
  String get gPairMissing3;

  /// No description provided for @gPairTip.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme bir kez yapılır. PS5\'in adresi değişirse uygulama onu ağda yeniden bulur.'**
  String get gPairTip;

  /// No description provided for @gTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'yi hazırla'**
  String get gTvTitle;

  /// No description provided for @gTvSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenen TV\'ler ve TV uygulaması'**
  String get gTvSubtitle;

  /// No description provided for @gTvLead.
  ///
  /// In tr, this message translates to:
  /// **'Altyazıyı TV\'de gösteren ayrı bir GameTranslator TV uygulaması vardır. Henüz mağazalarda olmadığı için TV\'ye bir kez kurulur. LG ve Android TV\'ye bu telefondan kurabilirsin; Samsung\'a kurulum şimdilik bilgisayardan yapılır.'**
  String get gTvLead;

  /// No description provided for @gTvSupportedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi TV\'ler destekleniyor?'**
  String get gTvSupportedTitle;

  /// No description provided for @gTvTableLg.
  ///
  /// In tr, this message translates to:
  /// **'LG'**
  String get gTvTableLg;

  /// No description provided for @gTvTableLgDetail.
  ///
  /// In tr, this message translates to:
  /// **'webOS 4 ve üstü'**
  String get gTvTableLgDetail;

  /// No description provided for @gTvTableSamsung.
  ///
  /// In tr, this message translates to:
  /// **'Samsung'**
  String get gTvTableSamsung;

  /// No description provided for @gTvTableSamsungDetail.
  ///
  /// In tr, this message translates to:
  /// **'Tizen, 2019 ve sonrası'**
  String get gTvTableSamsungDetail;

  /// No description provided for @gTvTableAndroid.
  ///
  /// In tr, this message translates to:
  /// **'Android TV / Google TV'**
  String get gTvTableAndroid;

  /// No description provided for @gTvTableAndroidDetail.
  ///
  /// In tr, this message translates to:
  /// **'Vestel, Arçelik, Beko, Grundig, Philips, Sony, TCL ve diğerleri'**
  String get gTvTableAndroidDetail;

  /// No description provided for @gTvTableOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğerleri'**
  String get gTvTableOther;

  /// No description provided for @gTvTableOtherDetail.
  ///
  /// In tr, this message translates to:
  /// **'Vestel/Arçelik/Beko/Grundig\'in Linux modelleri, Philips Saphi, Titan OS'**
  String get gTvTableOtherDetail;

  /// No description provided for @gTvNotSupported.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmiyor: bu TV\'lere uygulama kurulamıyor.'**
  String get gTvNotSupported;

  /// No description provided for @gTvAndroidTip.
  ///
  /// In tr, this message translates to:
  /// **'TV\'n Android mi? Ana ekranında Google Play Store ya da \"Google TV\" yazıyorsa Android\'dir.'**
  String get gTvAndroidTip;

  /// No description provided for @gTvLgTitle.
  ///
  /// In tr, this message translates to:
  /// **'LG'**
  String get gTvLgTitle;

  /// No description provided for @gTvLgStep1.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardan webostv.developer.lge.com adresinde ücretsiz bir LG geliştirici hesabı aç.'**
  String get gTvLgStep1;

  /// No description provided for @gTvLgStep2.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de LG Content Store\'dan \"Developer Mode\" uygulamasını kur, hesabınla giriş yap ve \"Dev Mode Status\"u aç. TV yeniden başlar.'**
  String get gTvLgStep2;

  /// No description provided for @gTvLgStep3.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Developer Mode uygulamasında \"Key Server\"ı aç.'**
  String get gTvLgStep3;

  /// No description provided for @gTvLgStep4.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda \"TV uygulamasını kur\" sihirbazında LG\'yi seç, TV\'ni bul ve ekrandaki 6 karakterli parolayı yaz (bilgisayardaki GameTranslator\'ın TV adımı da aynısını yapar).'**
  String get gTvLgStep4;

  /// No description provided for @gTvLgNote.
  ///
  /// In tr, this message translates to:
  /// **'LG\'de geliştirici modu en çok 1000 saat açık kalır. Uzun süre kullanmayacaksan süre dolmadan Developer Mode uygulamasında \"EXTEND\"e bas; süre dolarsa TV uygulaması silinir ve baştan kurman gerekir.'**
  String get gTvLgNote;

  /// No description provided for @gTvSamsungTitle.
  ///
  /// In tr, this message translates to:
  /// **'Samsung'**
  String get gTvSamsungTitle;

  /// No description provided for @gTvSamsungStep1.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Uygulamalar ekranını aç ve kumandayla 1 2 3 4 5 tuşlarına bas. Geliştirici modu penceresi açılır.'**
  String get gTvSamsungStep1;

  /// No description provided for @gTvSamsungStep2.
  ///
  /// In tr, this message translates to:
  /// **'\"Developer mode\"u aç, \"Host PC IP\" alanına bilgisayarının adresini yaz.'**
  String get gTvSamsungStep2;

  /// No description provided for @gTvSamsungStep3.
  ///
  /// In tr, this message translates to:
  /// **'TV\'yi güç tuşunu basılı tutarak tam kapatıp aç.'**
  String get gTvSamsungStep3;

  /// No description provided for @gTvSamsungStep4.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator\'ın TV adımında TV\'ni seç. Açılan sayfada ücretsiz bir Samsung hesabıyla giriş yap; uygulama imzalanıp kurulur.'**
  String get gTvSamsungStep4;

  /// No description provided for @gTvAndroidTitle.
  ///
  /// In tr, this message translates to:
  /// **'Android TV / Google TV'**
  String get gTvAndroidTitle;

  /// No description provided for @gTvAndroidStep1.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Ayarlar › Cihaz Tercihleri › Hakkında\'ya gir (Google TV\'de Ayarlar › Sistem › Hakkında).'**
  String get gTvAndroidStep1;

  /// No description provided for @gTvAndroidStep2.
  ///
  /// In tr, this message translates to:
  /// **'\"Yapı numarası\"nın üstünde Tamam tuşuna 7 kez bas.'**
  String get gTvAndroidStep2;

  /// No description provided for @gTvAndroidStep3.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici seçenekleri\'nden \"USB hata ayıklama\"yı (varsa \"Ağ hata ayıklama\"yı da) aç.'**
  String get gTvAndroidStep3;

  /// No description provided for @gTvAndroidStep4.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda \"TV uygulamasını kur\" sihirbazında \"Android TV / Google TV\"yi seç ve TV\'deki izin sorusunu onayla.'**
  String get gTvAndroidStep4;

  /// No description provided for @gTvAndroidNote.
  ///
  /// In tr, this message translates to:
  /// **'TV ağdan hata ayıklamaya izin vermiyorsa USB bellekle de kurabilirsin: GameTranslator\'ın sürümler sayfasından TV uygulamasının APK dosyasını indir, belleğe kopyala ve TV\'de bir dosya yöneticisiyle açıp kur.'**
  String get gTvAndroidNote;

  /// No description provided for @gTvAfterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurulduktan sonra'**
  String get gTvAfterTitle;

  /// No description provided for @gTvAfterBody.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması telefonu ağda kendisi bulur; telefona TV\'nin adresini yazman gerekmez. Samsung\'da bilgisayara yalnızca kurulum için ihtiyaç var; sonrasında kapalı kalabilir.'**
  String get gTvAfterBody;

  /// No description provided for @gTvObsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yayın yapanlar için: OBS'**
  String get gTvObsTitle;

  /// No description provided for @gTvObsBody.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri açıkken altyazılar bir web sayfası olarak da sunulur. OBS\'te \"Tarayıcı Kaynağı\" ekleyip adres olarak http://{phone}:8787/obs yaz (1920×1080). Sayfanın zemini saydamdır; TV\'nin tarayıcısında oyunun üstünde göstermez, yalnızca yayın ve kayıt düzenleri içindir.'**
  String gTvObsBody(String phone);

  /// No description provided for @gFirstTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk kullanım'**
  String get gFirstTitle;

  /// No description provided for @gFirstSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi başlat ve TV\'de gör'**
  String get gFirstSubtitle;

  /// No description provided for @gFirstStep1.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te oyunu kendi hesabınla aç ve oyunun ayarlarından altyazıları aç.'**
  String get gFirstStep1;

  /// No description provided for @gFirstStep2.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda ana ekrandaki büyük düğmeye dokun. İlk seferde bildirim izni sorulur; izin ver ki çeviri arka planda sürsün.'**
  String get gFirstStep2;

  /// No description provided for @gFirstStep3.
  ///
  /// In tr, this message translates to:
  /// **'Durum \"Çeviri açık\" olunca PS5 kartı \"Bağlı\" yazar. İlk bağlantı birkaç saniye sürer.'**
  String get gFirstStep3;

  /// No description provided for @gFirstStep4.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator uygulamasını aç. Birkaç saniye içinde telefondaki TV kartı \"Bağlı\" olur.'**
  String get gFirstStep4;

  /// No description provided for @gFirstStep5.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de oyun görüntüsü gelmezse Tamam tuşuyla paneli aç, sol ve sağ tuşlarıyla PS5\'in bağlı olduğu HDMI girişini seç.'**
  String get gFirstStep5;

  /// No description provided for @gFirstStep6.
  ///
  /// In tr, this message translates to:
  /// **'TV\'den ses gelmezse PS5 sesi Remote Play\'e yönlendirmiştir: PS tuşuna bas, alttaki menüden Ses › Çıkış Cihazı\'nı aç ve HDMI\'ı seç. Bu bir kez yapılır.'**
  String get gFirstStep6;

  /// No description provided for @gFirstStep7.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda \"TV\'ye deneme altyazısı gönder\"e dokun. TV\'de yazıyı görüyorsan her şey hazır.'**
  String get gFirstStep7;

  /// No description provided for @gFirstTip.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri açıkken telefonun ekranını kapatabilirsin. Durdurmak için uygulamadaki düğmeye ya da bildirimdeki \"Durdur\"a dokun.'**
  String get gFirstTip;

  /// No description provided for @gFirstNextTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki seferler'**
  String get gFirstNextTitle;

  /// No description provided for @gFirstNextBody.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca iki adım: telefonda çeviriyi başlat, TV\'de GameTranslator\'ı aç.'**
  String get gFirstNextBody;

  /// No description provided for @gFirstBatteryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pil ve ısınma'**
  String get gFirstBatteryTitle;

  /// No description provided for @gFirstBatteryBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon sürekli video çözüp yazı okur; uzun oturumlarda şarja takılı kullan.'**
  String get gFirstBatteryBody;

  /// No description provided for @gRemoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV kumandası'**
  String get gRemoteTitle;

  /// No description provided for @gRemoteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulamasındaki tuşlar'**
  String get gRemoteSubtitle;

  /// No description provided for @gRemoteLead.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator açıkken kumandanın tuşları şunları yapar:'**
  String get gRemoteLead;

  /// No description provided for @gRemoteOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get gRemoteOk;

  /// No description provided for @gRemoteOkText.
  ///
  /// In tr, this message translates to:
  /// **'Durum panelini açar ve kapatır (HDMI girişi, bağlantı durumu).'**
  String get gRemoteOkText;

  /// No description provided for @gRemoteLeftRight.
  ///
  /// In tr, this message translates to:
  /// **'Sol / Sağ'**
  String get gRemoteLeftRight;

  /// No description provided for @gRemoteLeftRightText.
  ///
  /// In tr, this message translates to:
  /// **'Panel açıkken HDMI girişini değiştirir.'**
  String get gRemoteLeftRightText;

  /// No description provided for @gRemoteNumbers.
  ///
  /// In tr, this message translates to:
  /// **'1 – 4'**
  String get gRemoteNumbers;

  /// No description provided for @gRemoteNumbersText.
  ///
  /// In tr, this message translates to:
  /// **'HDMI girişini doğrudan seçer.'**
  String get gRemoteNumbersText;

  /// No description provided for @gRemoteUpDown.
  ///
  /// In tr, this message translates to:
  /// **'Yukarı / Aşağı'**
  String get gRemoteUpDown;

  /// No description provided for @gRemoteUpDownText.
  ///
  /// In tr, this message translates to:
  /// **'Altyazıyı ekranda yukarı ya da aşağı kaydırır.'**
  String get gRemoteUpDownText;

  /// No description provided for @gRemoteRed.
  ///
  /// In tr, this message translates to:
  /// **'Kırmızı'**
  String get gRemoteRed;

  /// No description provided for @gRemoteRedText.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin kendi deneme yazısını gösterir.'**
  String get gRemoteRedText;

  /// No description provided for @gRemoteGreen.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil'**
  String get gRemoteGreen;

  /// No description provided for @gRemoteGreenText.
  ///
  /// In tr, this message translates to:
  /// **'Durum panelini açar ve kapatır.'**
  String get gRemoteGreenText;

  /// No description provided for @gRemoteBlue.
  ///
  /// In tr, this message translates to:
  /// **'Mavi'**
  String get gRemoteBlue;

  /// No description provided for @gRemoteBlueText.
  ///
  /// In tr, this message translates to:
  /// **'Örnek altyazılarla tanıtımı başlatır ya da durdurur.'**
  String get gRemoteBlueText;

  /// No description provided for @gRemoteBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get gRemoteBack;

  /// No description provided for @gRemoteBackText.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamadan çıkar.'**
  String get gRemoteBackText;

  /// No description provided for @gRemoteTip.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu PS5 kumandasıyla oynarsın; TV kumandası yalnızca bu ayarlar için gerekir.'**
  String get gRemoteTip;

  /// No description provided for @gRegionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı bölgesini ayarla'**
  String get gRegionTitle;

  /// No description provided for @gRegionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun ekranda nereye bakacağı'**
  String get gRegionSubtitle;

  /// No description provided for @gRegionBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefon bütün ekranı değil, yalnızca altyazının çıktığı bölgeyi okur. Bölge yanlış yerdeyse çeviri gelmez ya da ekrandaki başka yazılar çevrilir.'**
  String get gRegionBody;

  /// No description provided for @gRegionStep1.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri açıkken oyunda bir altyazı çıkmasını bekle.'**
  String get gRegionStep1;

  /// No description provided for @gRegionStep2.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrandaki önizlemede mavi çerçeveye bak: altyazının tamamı çerçevenin içinde olmalı.'**
  String get gRegionStep2;

  /// No description provided for @gRegionStep3.
  ///
  /// In tr, this message translates to:
  /// **'Değilse \"Altyazı bölgesini ayarla\"ya dokun. Üst, Alt, Sol ya da Sağ kenarı seç ve sürgüyle yerini değiştir.'**
  String get gRegionStep3;

  /// No description provided for @gRegionStep4.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrandaki \"Çerçevede okunan\" satırı telefonun o anda ne okuduğunu gösterir; altyazının tamamı orada görünmeli.'**
  String get gRegionStep4;

  /// No description provided for @gRegionBullet1.
  ///
  /// In tr, this message translates to:
  /// **'Cümlenin başı ya da sonu kesiliyorsa çerçeveyi genişlet.'**
  String get gRegionBullet1;

  /// No description provided for @gRegionBullet2.
  ///
  /// In tr, this message translates to:
  /// **'İki satırlı altyazılarda üst satır kayboluyorsa üst kenarı yukarı al.'**
  String get gRegionBullet2;

  /// No description provided for @gRegionBullet3.
  ///
  /// In tr, this message translates to:
  /// **'Görev yazıları, harita adları gibi başka yazılar çevriliyorsa çerçeveyi daralt.'**
  String get gRegionBullet3;

  /// No description provided for @gRegionTip.
  ///
  /// In tr, this message translates to:
  /// **'Her oyun altyazıyı farklı yere koyar; yeni bir oyuna başladığında bölgeye bir kez bakmak yeter.'**
  String get gRegionTip;

  /// No description provided for @gLookTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri ve görünüm'**
  String get gLookTitle;

  /// No description provided for @gLookSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Motor, sözlük ve TV\'deki yazı'**
  String get gLookSubtitle;

  /// No description provided for @gEngineTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri motoru'**
  String get gEngineTitle;

  /// No description provided for @gEngineGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google'**
  String get gEngineGoogle;

  /// No description provided for @gEngineGoogleText.
  ///
  /// In tr, this message translates to:
  /// **'İnternet ister, anahtar gerekmez. Çoğu oyun için en iyi başlangıç.'**
  String get gEngineGoogleText;

  /// No description provided for @gEngineDeepl.
  ///
  /// In tr, this message translates to:
  /// **'DeepL'**
  String get gEngineDeepl;

  /// No description provided for @gEngineDeeplText.
  ///
  /// In tr, this message translates to:
  /// **'Daha doğal cümleler kurar. DeepL\'den aldığın kendi API anahtarını yazman gerekir.'**
  String get gEngineDeeplText;

  /// No description provided for @gEngineOnDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda'**
  String get gEngineOnDevice;

  /// No description provided for @gEngineOnDeviceText.
  ///
  /// In tr, this message translates to:
  /// **'İnternetsiz çalışır; kalitesi diğerlerinden düşüktür. İlk kullanımda dil modeli bir kez iner.'**
  String get gEngineOnDeviceText;

  /// No description provided for @gEngineFallback.
  ///
  /// In tr, this message translates to:
  /// **'İnternet koparsa çeviri kendiliğinden cihazdaki modele geçer ve bağlantı gelince geri döner.'**
  String get gEngineFallback;

  /// No description provided for @gGlossaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Terim sözlüğü'**
  String get gGlossaryTitle;

  /// No description provided for @gGlossaryBody.
  ///
  /// In tr, this message translates to:
  /// **'Çevirinin bozduğu karakter adlarını ve oyun terimlerini sabitlemek içindir (yalnız İngilizce → Türkçe). Ayarlar › Çeviri › Terim sözlüğü\'nden açılır. \"terms\" içindeki terimler yazdığın Türkçeyle çevrilir, \"keep\" içindeki adlar olduğu gibi kalır.'**
  String get gGlossaryBody;

  /// No description provided for @gLookOnTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'deki görünüm'**
  String get gLookOnTvTitle;

  /// No description provided for @gLookOnTv1.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu ve rengi: Ayarlar › TV\'de görünüm.'**
  String get gLookOnTv1;

  /// No description provided for @gLookOnTv2.
  ///
  /// In tr, this message translates to:
  /// **'Altyazının yeri: oyunun altyazısını örterek, üstünde, altında ya da ekranın altında sabit.'**
  String get gLookOnTv2;

  /// No description provided for @gLookOnTv3.
  ///
  /// In tr, this message translates to:
  /// **'Zemin koyuluğu: yazının arkasındaki siyah kutunun koyuluğu. Oyunun altyazısını örtüyorsan yüksek tut.'**
  String get gLookOnTv3;

  /// No description provided for @gTroubleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sorun giderme'**
  String get gTroubleTitle;

  /// No description provided for @gTroubleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık karşılaşılan durumlar'**
  String get gTroubleSubtitle;

  /// No description provided for @gQ1.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri başlamıyor, \"PS5\'e bağlanılıyor\"da kalıyor'**
  String get gQ1;

  /// No description provided for @gQ1A1.
  ///
  /// In tr, this message translates to:
  /// **'PS5 açık mı? Dinlenme modundaysa uyandırma ayarlarını \"PS5\'i hazırla\" bölümündeki gibi aç.'**
  String get gQ1A1;

  /// No description provided for @gQ1A2.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Wi-Fi\'ye bağlı ve PS5 ile aynı ağda mı?'**
  String get gQ1A2;

  /// No description provided for @gQ1A3.
  ///
  /// In tr, this message translates to:
  /// **'PS5\'te Uzaktan Oynatma açık mı?'**
  String get gQ1A3;

  /// No description provided for @gQ2.
  ///
  /// In tr, this message translates to:
  /// **'\"Uzaktan Oynatma başka bir cihaz tarafından kullanılıyor\"'**
  String get gQ2;

  /// No description provided for @gQ2A1.
  ///
  /// In tr, this message translates to:
  /// **'PS5 aynı anda tek bir Uzaktan Oynatma bağlantısı kabul eder. Bilgisayardaki GameTranslator ya da başka bir Remote Play uygulaması açıksa kapat.'**
  String get gQ2A1;

  /// No description provided for @gQ2A2.
  ///
  /// In tr, this message translates to:
  /// **'Az önce durdurduysan birkaç saniye bekle; uygulama kendiliğinden yeniden dener.'**
  String get gQ2A2;

  /// No description provided for @gQ3.
  ///
  /// In tr, this message translates to:
  /// **'Kumandam TV\'den koptu'**
  String get gQ3;

  /// No description provided for @gQ3A1.
  ///
  /// In tr, this message translates to:
  /// **'Telefon senin oynadığın hesapla bağlanmış. Ayarlar › PS5 › \"PSN hesabını değiştir\" ile ikinci kullanıcının hesabına geç.'**
  String get gQ3A1;

  /// No description provided for @gQ4.
  ///
  /// In tr, this message translates to:
  /// **'TV kartı \"Bekleniyor\"da kalıyor'**
  String get gQ4;

  /// No description provided for @gQ4A1.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator uygulaması açık mı?'**
  String get gQ4A1;

  /// No description provided for @gQ4A2.
  ///
  /// In tr, this message translates to:
  /// **'TV, telefonla aynı ağda mı? Misafir ağı ya da farklı bir modem olmamalı.'**
  String get gQ4A2;

  /// No description provided for @gQ4A3.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator açıksa kapat; TV ağda ilk bulduğuna bağlanır.'**
  String get gQ4A3;

  /// No description provided for @gQ4A4.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması daha önce bilgisayara bağlandıysa o adreste takılı kalmış olabilir. Aşağıdaki \"TV telefonu bulamıyorsa\" adımlarını uygula.'**
  String get gQ4A4;

  /// No description provided for @gTvNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV telefonu bulamıyorsa'**
  String get gTvNotFoundTitle;

  /// No description provided for @gRecoveryLead.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması en son bağlandığı adresi hatırlar. Daha önce bilgisayara bağlandıysa, telefonu aramak yerine o adresi denemeye devam edebilir. Kayıtlı adresi silince uygulama ağı baştan tarar ve telefonu bulur.'**
  String get gRecoveryLead;

  /// No description provided for @gRecoveryAndroidTitle.
  ///
  /// In tr, this message translates to:
  /// **'Android TV / Google TV (TCL, Sony, Philips, Vestel…)'**
  String get gRecoveryAndroidTitle;

  /// No description provided for @gRecoveryAndroidStep1.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Ayarlar › Uygulamalar\'a gir ve listeden GameTranslator\'ı seç (\"Tüm uygulamaları göster\" gerekebilir).'**
  String get gRecoveryAndroidStep1;

  /// No description provided for @gRecoveryAndroidStep2.
  ///
  /// In tr, this message translates to:
  /// **'\"Verileri temizle\"yi seç ve onayla. Uygulama silinmez, yalnızca kayıtlı adres ve ayarlar sıfırlanır.'**
  String get gRecoveryAndroidStep2;

  /// No description provided for @gRecoveryAndroidStep3.
  ///
  /// In tr, this message translates to:
  /// **'Telefonda çeviri açıkken TV\'de GameTranslator\'ı yeniden aç.'**
  String get gRecoveryAndroidStep3;

  /// No description provided for @gRecoveryAndroidStep4.
  ///
  /// In tr, this message translates to:
  /// **'Bir dakikaya kadar bekle; telefondaki TV karosu \"Bağlı\" olur.'**
  String get gRecoveryAndroidStep4;

  /// No description provided for @gRecoverySamsungTitle.
  ///
  /// In tr, this message translates to:
  /// **'Samsung ve LG'**
  String get gRecoverySamsungTitle;

  /// No description provided for @gRecoverySamsungStep1.
  ///
  /// In tr, this message translates to:
  /// **'Bu TV\'lerde uygulama verisi ayrı silinemez: GameTranslator\'ı TV\'den kaldır.'**
  String get gRecoverySamsungStep1;

  /// No description provided for @gRecoverySamsungStep2.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator ile yeniden kur (\"TV\'yi hazırla\" bölümündeki adımlar).'**
  String get gRecoverySamsungStep2;

  /// No description provided for @gRecoverySamsungStep3.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator\'ı kapat, telefonda çeviriyi başlat ve TV\'de uygulamayı aç.'**
  String get gRecoverySamsungStep3;

  /// No description provided for @gRecoveryStillTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yine olmazsa'**
  String get gRecoveryStillTitle;

  /// No description provided for @gRecoveryStill1.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayardaki GameTranslator kapalı mı? Açıksa TV ona bağlanır.'**
  String get gRecoveryStill1;

  /// No description provided for @gRecoveryStill2.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ve TV aynı Wi-Fi ağında mı? Modemde \"istemci yalıtımı\" (AP isolation) açıksa cihazlar birbirini göremez.'**
  String get gRecoveryStill2;

  /// No description provided for @gRecoveryStill3.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de HDMI ayarı da sıfırlandığı için Tamam ile paneli açıp PS5\'in girişini yeniden seç.'**
  String get gRecoveryStill3;

  /// No description provided for @gTroubleTip.
  ///
  /// In tr, this message translates to:
  /// **'Çözemediğin bir sorun olursa Ayarlar › Hakkında › Günlük\'teki kayıtları kopyalayıp paylaşabilirsin.'**
  String get gTroubleTip;

  /// No description provided for @gQ5.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de oyun görüntüsü yok, ekran siyah'**
  String get gQ5;

  /// No description provided for @gQ5A1.
  ///
  /// In tr, this message translates to:
  /// **'Tamam ile paneli aç ve sol/sağ ile PS5\'in bağlı olduğu HDMI girişini seç.'**
  String get gQ5A1;

  /// No description provided for @gQ5A2.
  ///
  /// In tr, this message translates to:
  /// **'Bazı Android TV\'ler HDMI görüntüsünü başka uygulamaya vermez; o TV\'lerde altyazı görünür ama arkası siyah kalır.'**
  String get gQ5A2;

  /// No description provided for @gQ6.
  ///
  /// In tr, this message translates to:
  /// **'Altyazı hiç gelmiyor'**
  String get gQ6;

  /// No description provided for @gQ6A1.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun kendi altyazıları açık mı?'**
  String get gQ6A1;

  /// No description provided for @gQ6A2.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrandaki \"Çerçevede okunan\" boşsa bölge yanlış yerdedir; \"Altyazı bölgesini ayarla\" bölümüne bak.'**
  String get gQ6A2;

  /// No description provided for @gQ6A3.
  ///
  /// In tr, this message translates to:
  /// **'Oyunun dili ile Ayarlar › Çeviri\'deki kaynak dil aynı mı?'**
  String get gQ6A3;

  /// No description provided for @gQ6A4.
  ///
  /// In tr, this message translates to:
  /// **'\"TV\'ye deneme altyazısı gönder\" çalışıyorsa TV bağlantısı sağlamdır; sorun okumadadır.'**
  String get gQ6A4;

  /// No description provided for @gQ7.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri yarım ya da anlamsız'**
  String get gQ7;

  /// No description provided for @gQ7A1.
  ///
  /// In tr, this message translates to:
  /// **'Cümlenin başı ya da sonu eksikse bölgeyi genişlet.'**
  String get gQ7A1;

  /// No description provided for @gQ7A2.
  ///
  /// In tr, this message translates to:
  /// **'Motor \"Cihazda\" ise Google ya da DeepL\'e geç.'**
  String get gQ7A2;

  /// No description provided for @gQ7A3.
  ///
  /// In tr, this message translates to:
  /// **'Çok süslü ya da çok küçük yazı tiplerinde okuma zorlaşır; oyunda altyazı boyutunu büyütmek ve arka plan eklemek yardımcı olur.'**
  String get gQ7A3;

  /// No description provided for @gQ8.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri geç geliyor'**
  String get gQ8;

  /// No description provided for @gQ8A1.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ve PS5 mümkünse modeme yakın olsun; zayıf Wi-Fi görüntüyü geciktirir.'**
  String get gQ8A1;

  /// No description provided for @gQ8A2.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi motorlarda internet hızı da etkiler.'**
  String get gQ8A2;

  /// No description provided for @gQ9.
  ///
  /// In tr, this message translates to:
  /// **'Ekranı kapatınca çeviri duruyor'**
  String get gQ9;

  /// No description provided for @gQ9A1.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun pil tasarrufu uygulamayı durduruyor olabilir. Telefonun Ayarlar › Uygulamalar › GameTranslator › Pil bölümünden \"Kısıtlanmamış\"ı seç.'**
  String get gQ9A1;

  /// No description provided for @gQ9A2.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim iznini kapattıysan aç; arka plan servisi bildirimle çalışır.'**
  String get gQ9A2;

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

  /// No description provided for @tvInstallTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV Uygulamasını Kur'**
  String get tvInstallTitle;

  /// No description provided for @tvInstallStepLabel.
  ///
  /// In tr, this message translates to:
  /// **'ADIM {number} / 4'**
  String tvInstallStepLabel(int number);

  /// No description provided for @tvInstallBrandQuestion.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin markası ne?'**
  String get tvInstallBrandQuestion;

  /// No description provided for @tvInstallIntroBody.
  ///
  /// In tr, this message translates to:
  /// **'Altyazıyı TV\'de gösteren GameTranslator uygulamasını telefondan TV\'ne kuracağız. Telefon ve TV aynı Wi-Fi ağında olsun.'**
  String get tvInstallIntroBody;

  /// No description provided for @tvInstallSavedHeader.
  ///
  /// In tr, this message translates to:
  /// **'KAYITLI TV'**
  String get tvInstallSavedHeader;

  /// No description provided for @tvInstallSavedSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{host} · TV\'de {version} · telefonda {phone}'**
  String tvInstallSavedSubtitle(String host, String version, String phone);

  /// No description provided for @tvInstallUpdateAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme var'**
  String get tvInstallUpdateAvailable;

  /// No description provided for @tvInstallUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get tvInstallUpdate;

  /// No description provided for @tvInstallReinstall.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden kur'**
  String get tvInstallReinstall;

  /// No description provided for @tvInstallBrandHeader.
  ///
  /// In tr, this message translates to:
  /// **'MARKA'**
  String get tvInstallBrandHeader;

  /// No description provided for @tvInstallBrandAndroidSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'TCL, Sony, Philips, Xiaomi, Vestel, Arçelik, Beko, Grundig… Ana ekranda Google Play ya da \"Google TV\" yazar.'**
  String get tvInstallBrandAndroidSubtitle;

  /// No description provided for @tvInstallBrandLgSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'webOS. Ana ekranda \"LG Content Store\" ve alt şeritte renkli uygulama kartları bulunur.'**
  String get tvInstallBrandLgSubtitle;

  /// No description provided for @tvInstallBrandSamsungSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tizen, 2019 ve sonrası. Ana ekranda \"Samsung TV Plus\" ve \"Smart Hub\" bulunur.'**
  String get tvInstallBrandSamsungSubtitle;

  /// No description provided for @tvInstallBrandFooter.
  ///
  /// In tr, this message translates to:
  /// **'Emin değil misin? TV\'nin Ayarlar › Destek (ya da Hakkında) ekranında model ve işletim sistemi yazar. Vestel/Arçelik/Beko/Grundig\'in Linux modelleri, Philips Saphi ve Titan OS desteklenmiyor.'**
  String get tvInstallBrandFooter;

  /// No description provided for @tvInstallSamsungStep.
  ///
  /// In tr, this message translates to:
  /// **'Samsung: bilgisayardan kur'**
  String get tvInstallSamsungStep;

  /// No description provided for @tvInstallSamsungNoticeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Samsung TV\'ye kurulum şimdilik bilgisayardan'**
  String get tvInstallSamsungNoticeTitle;

  /// No description provided for @tvInstallSamsungNoticeText.
  ///
  /// In tr, this message translates to:
  /// **'Samsung, uygulamanın her TV için Samsung hesabıyla ayrıca imzalanmasını istiyor. Telefondan kurulum henüz hazır değil; bilgisayardaki GameTranslator bunu kendisi yapar. Kurulum bir kez yapılır, sonra bilgisayar gerekmez.'**
  String get tvInstallSamsungNoticeText;

  /// No description provided for @tvInstallSamsungStepsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kısaca adımlar'**
  String get tvInstallSamsungStepsTitle;

  /// No description provided for @tvInstallSamsungStep1.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Uygulamalar ekranını aç, kumandayla 1 2 3 4 5 tuşlarına bas.'**
  String get tvInstallSamsungStep1;

  /// No description provided for @tvInstallSamsungStep2.
  ///
  /// In tr, this message translates to:
  /// **'\"Developer mode\"u \"On\" yap, \"Host PC IP\" alanına BİLGİSAYARIN adresini yaz, OK\'e bas.'**
  String get tvInstallSamsungStep2;

  /// No description provided for @tvInstallSamsungStep3.
  ///
  /// In tr, this message translates to:
  /// **'TV\'yi güç tuşunu basılı tutarak tam kapatıp aç.'**
  String get tvInstallSamsungStep3;

  /// No description provided for @tvInstallSamsungStep4.
  ///
  /// In tr, this message translates to:
  /// **'Bilgisayarda GameTranslator\'ın TV adımında Samsung TV\'ni seç ve açılan sayfada Samsung hesabınla giriş yap.'**
  String get tvInstallSamsungStep4;

  /// No description provided for @tvInstallShowDetailed.
  ///
  /// In tr, this message translates to:
  /// **'Rehberde ayrıntılı göster'**
  String get tvInstallShowDetailed;

  /// No description provided for @tvInstallOtherBrand.
  ///
  /// In tr, this message translates to:
  /// **'Başka marka seç'**
  String get tvInstallOtherBrand;

  /// No description provided for @tvInstallFindStep.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ni bul'**
  String get tvInstallFindStep;

  /// No description provided for @tvInstallFindBodyAndroid.
  ///
  /// In tr, this message translates to:
  /// **'Ağda hata ayıklaması açık Android TV\'ler aranıyor. Hata ayıklamayı henüz açmadıysan TV burada görünmez; sorun değil, \"Adımları göster\" ile devam et.'**
  String get tvInstallFindBodyAndroid;

  /// No description provided for @tvInstallFindBodyLg.
  ///
  /// In tr, this message translates to:
  /// **'Telefonla aynı ağdaki LG TV\'ler aranıyor. TV açık olsun.'**
  String get tvInstallFindBodyLg;

  /// No description provided for @tvInstallSearchingHeader.
  ///
  /// In tr, this message translates to:
  /// **'ARANIYOR…'**
  String get tvInstallSearchingHeader;

  /// No description provided for @tvInstallFoundHeader.
  ///
  /// In tr, this message translates to:
  /// **'BULUNAN TV\'LER'**
  String get tvInstallFoundHeader;

  /// No description provided for @tvInstallScanning.
  ///
  /// In tr, this message translates to:
  /// **'Ağ taranıyor, birkaç saniye sürer…'**
  String get tvInstallScanning;

  /// No description provided for @tvInstallNotFound.
  ///
  /// In tr, this message translates to:
  /// **'TV bulunamadı'**
  String get tvInstallNotFound;

  /// No description provided for @tvInstallNotSearched.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aranmadı'**
  String get tvInstallNotSearched;

  /// No description provided for @tvInstallNotSearchedNote.
  ///
  /// In tr, this message translates to:
  /// **'Yenile\'ye dokun ya da adresi elle yaz.'**
  String get tvInstallNotSearchedNote;

  /// No description provided for @tvInstallReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get tvInstallReady;

  /// No description provided for @tvInstallRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get tvInstallRefresh;

  /// No description provided for @tvInstallManualHeader.
  ///
  /// In tr, this message translates to:
  /// **'ADRESİ ELLE YAZ'**
  String get tvInstallManualHeader;

  /// No description provided for @tvInstallIpHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. 192.168.1.40'**
  String get tvInstallIpHint;

  /// No description provided for @tvInstallUseAddress.
  ///
  /// In tr, this message translates to:
  /// **'Bu adresi kullan'**
  String get tvInstallUseAddress;

  /// No description provided for @tvInstallAddressFooterAndroid.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin adresi: Ayarlar › Ağ ve İnternet › bağlı olduğun Wi-Fi ağının adı (Google TV: Ayarlar › Ağ ve İnternet).'**
  String get tvInstallAddressFooterAndroid;

  /// No description provided for @tvInstallAddressFooterLg.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin adresi: Ayarlar › Genel › Ağ › Wi-Fi Bağlantısı › Gelişmiş Wi-Fi Ayarları (modele göre Ayarlar › Ağ).'**
  String get tvInstallAddressFooterLg;

  /// No description provided for @tvInstallSameSubnet.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun adresi {phone}; TV\'ninki ilk üç bölümde aynı olmalı.'**
  String tvInstallSameSubnet(String phone);

  /// No description provided for @tvInstallShowSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adımları göster'**
  String get tvInstallShowSteps;

  /// No description provided for @tvInstallIpError.
  ///
  /// In tr, this message translates to:
  /// **'Bu bir IP adresine benzemiyor. Örnek: 192.168.1.40'**
  String get tvInstallIpError;

  /// No description provided for @tvInstallDebugStep.
  ///
  /// In tr, this message translates to:
  /// **'Hata ayıklamayı aç'**
  String get tvInstallDebugStep;

  /// No description provided for @tvInstallDevModeStep.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici modunu aç'**
  String get tvInstallDevModeStep;

  /// No description provided for @tvInstallStepCounter.
  ///
  /// In tr, this message translates to:
  /// **'{index}. adım, toplam {total}'**
  String tvInstallStepCounter(int index, int total);

  /// No description provided for @tvInstallCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get tvInstallCopy;

  /// No description provided for @tvInstallCopied.
  ///
  /// In tr, this message translates to:
  /// **'Adres kopyalandı'**
  String get tvInstallCopied;

  /// No description provided for @tvInstallKeyServerOn.
  ///
  /// In tr, this message translates to:
  /// **'Key Server açık. Devam edebilirsin.'**
  String get tvInstallKeyServerOn;

  /// No description provided for @tvInstallDeviceReady.
  ///
  /// In tr, this message translates to:
  /// **'TV hazır. Devam edebilirsin.'**
  String get tvInstallDeviceReady;

  /// No description provided for @tvInstallSearchingTv.
  ///
  /// In tr, this message translates to:
  /// **'TV ağda aranıyor…'**
  String get tvInstallSearchingTv;

  /// No description provided for @tvInstallWaitingTv.
  ///
  /// In tr, this message translates to:
  /// **'TV bekleniyor ({host})…'**
  String tvInstallWaitingTv(String host);

  /// No description provided for @tvInstallDifferentMenu.
  ///
  /// In tr, this message translates to:
  /// **'Menü farklı görünüyorsa'**
  String get tvInstallDifferentMenu;

  /// No description provided for @tvInstallDidIt.
  ///
  /// In tr, this message translates to:
  /// **'Bunu yaptım'**
  String get tvInstallDidIt;

  /// No description provided for @tvInstallGoInstall.
  ///
  /// In tr, this message translates to:
  /// **'Kuruluma geç'**
  String get tvInstallGoInstall;

  /// No description provided for @tvInstallWaitingFooter.
  ///
  /// In tr, this message translates to:
  /// **'TV ağda görünene kadar bekleniyor. Görünmüyorsa geri dönüp TV\'nin adresini elle yaz.'**
  String get tvInstallWaitingFooter;

  /// No description provided for @tvInstallInstallStep.
  ///
  /// In tr, this message translates to:
  /// **'Kur'**
  String get tvInstallInstallStep;

  /// No description provided for @tvInstallVersionToInstall.
  ///
  /// In tr, this message translates to:
  /// **'Kurulacak sürüm'**
  String get tvInstallVersionToInstall;

  /// No description provided for @tvInstallPassHeader.
  ///
  /// In tr, this message translates to:
  /// **'TV EKRANINDAKİ PAROLA'**
  String get tvInstallPassHeader;

  /// No description provided for @tvInstallPassHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. 2FEEB2'**
  String get tvInstallPassHint;

  /// No description provided for @tvInstallPassFooter.
  ///
  /// In tr, this message translates to:
  /// **'Developer Mode uygulamasında Key Server açıkken ekranın sol altında \"Passphrase\" olarak görünen 6 karakter. Yalnız bu ilk kurulumda sorulur.'**
  String get tvInstallPassFooter;

  /// No description provided for @tvInstallApproveTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de bir soru çıkacak'**
  String get tvInstallApproveTitle;

  /// No description provided for @tvInstallApproveText.
  ///
  /// In tr, this message translates to:
  /// **'\"USB hata ayıklamaya izin verilsin mi?\" sorusunda \"Bu bilgisayardan her zaman izin ver\"i işaretle ve \"İzin ver\"i seç. Soru yalnız ilk kurulumda çıkar.'**
  String get tvInstallApproveText;

  /// No description provided for @tvInstallLookAtTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi TV\'ye bak'**
  String get tvInstallLookAtTvTitle;

  /// No description provided for @tvInstallLookAtTvText.
  ///
  /// In tr, this message translates to:
  /// **'TV \"USB hata ayıklamaya izin verilsin mi?\" diye soruyor. \"Bu bilgisayardan her zaman izin ver\"i işaretle ve \"İzin ver\"i seç. Kurulum sonra kendiliğinden sürer.'**
  String get tvInstallLookAtTvText;

  /// No description provided for @tvInstallKeepScreenOn.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun ekranını açık tut. Kurulum genellikle bir dakikadan kısa sürer.'**
  String get tvInstallKeepScreenOn;

  /// No description provided for @tvInstallTvSaid.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin söylediği'**
  String get tvInstallTvSaid;

  /// No description provided for @tvInstallStop.
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get tvInstallStop;

  /// No description provided for @tvInstallInstallButton.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye kur'**
  String get tvInstallInstallButton;

  /// No description provided for @tvInstallRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tvInstallRetry;

  /// No description provided for @tvInstallBackToSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adımlara dön'**
  String get tvInstallBackToSteps;

  /// No description provided for @tvInstallInstalled.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması kuruldu'**
  String get tvInstallInstalled;

  /// No description provided for @tvInstallAlreadyCurrent.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması zaten güncel'**
  String get tvInstallAlreadyCurrent;

  /// No description provided for @tvInstallVersionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version}'**
  String tvInstallVersionLabel(String version);

  /// No description provided for @tvInstallLaunchedTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator açıldı'**
  String get tvInstallLaunchedTitle;

  /// No description provided for @tvInstallOpenOnTvTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de GameTranslator\'ı aç'**
  String get tvInstallOpenOnTvTitle;

  /// No description provided for @tvInstallLaunchedText.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi telefonda başlattığında TV uygulaması telefonu ağda kendisi bulur.'**
  String get tvInstallLaunchedText;

  /// No description provided for @tvInstallOpenOnTvText.
  ///
  /// In tr, this message translates to:
  /// **'TV\'nin uygulamalar listesinde GameTranslator\'ı bul ve aç. Çeviriyi başlattığında telefonu kendisi bulur.'**
  String get tvInstallOpenOnTvText;

  /// No description provided for @tvInstallLgHoursTitle.
  ///
  /// In tr, this message translates to:
  /// **'LG geliştirici modu süresi'**
  String get tvInstallLgHoursTitle;

  /// No description provided for @tvInstallHoursLeft.
  ///
  /// In tr, this message translates to:
  /// **'Kalan süre: {hours} saat.'**
  String tvInstallHoursLeft(int hours);

  /// No description provided for @tvInstallLgHoursText.
  ///
  /// In tr, this message translates to:
  /// **'Süre dolarsa TV uygulaması silinir. Uzun süre kullanmayacaksan TV\'deki Developer Mode uygulamasında \"EXTEND\"e bas; bu sayfadan yeniden kurmak da süreyi uzatır.'**
  String get tvInstallLgHoursText;

  /// No description provided for @tvInstallAndroidNote.
  ///
  /// In tr, this message translates to:
  /// **'İstersen artık TV\'de USB hata ayıklamayı kapatabilirsin. Yeni bir sürümü kurmak için yeniden açman gerekir.'**
  String get tvInstallAndroidNote;

  /// No description provided for @tvInstallDone.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get tvInstallDone;

  /// No description provided for @tvInstallBrandFallback.
  ///
  /// In tr, this message translates to:
  /// **'TV'**
  String get tvInstallBrandFallback;

  /// No description provided for @tvGuideA1Title.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Ayarlar\'ı aç'**
  String get tvGuideA1Title;

  /// No description provided for @tvGuideA1Body.
  ///
  /// In tr, this message translates to:
  /// **'TV kumandasındaki dişli (Ayarlar) tuşuna bas. Kumandada yoksa ana ekranın sağ üstündeki dişli simgesini seç.'**
  String get tvGuideA1Body;

  /// No description provided for @tvGuideA1Different.
  ///
  /// In tr, this message translates to:
  /// **'Google TV\'de (yeni Sony, TCL, Philips, Xiaomi modelleri) sağ üstteki profil resmini ya da dişliyi seç, sonra \"Ayarlar\"a gir.'**
  String get tvGuideA1Different;

  /// No description provided for @tvGuideA2Title.
  ///
  /// In tr, this message translates to:
  /// **'\"Hakkında\" ekranına gir'**
  String get tvGuideA2Title;

  /// No description provided for @tvGuideA2Body.
  ///
  /// In tr, this message translates to:
  /// **'Android TV: Ayarlar › Cihaz Tercihleri › Hakkında.\nGoogle TV: Ayarlar › Sistem › Hakkında.'**
  String get tvGuideA2Body;

  /// No description provided for @tvGuideA2Different.
  ///
  /// In tr, this message translates to:
  /// **'Philips: Ayarlar › Android Ayarları › Cihaz Tercihleri › Hakkında.\nSony: Ayarlar › Sistem › Hakkında (eski modellerde Cihaz Tercihleri › Hakkında).\nTCL ve Xiaomi: Ayarlar › Sistem › Hakkında ya da Cihaz Tercihleri › Hakkında.\nBulamazsan ayarlarda arama varsa \"Hakkında\" yaz.'**
  String get tvGuideA2Different;

  /// No description provided for @tvGuideA3Title.
  ///
  /// In tr, this message translates to:
  /// **'Yapı satırına 7 kez bas'**
  String get tvGuideA3Title;

  /// No description provided for @tvGuideA3Body.
  ///
  /// In tr, this message translates to:
  /// **'Listenin altındaki \"Android TV OS yapısı\" satırını seç ve kumandanın Tamam tuşuna art arda 7 kez bas. \"Artık bir geliştiricisiniz\" yazısı çıkar.'**
  String get tvGuideA3Body;

  /// No description provided for @tvGuideA3Different.
  ///
  /// In tr, this message translates to:
  /// **'Satırın adı modele göre \"Yapı numarası\", \"Derleme\" ya da \"Build\" olabilir. TV PIN isterse TV\'nin kilit PIN\'ini gir. \"Zaten geliştiricisiniz\" yazıyorsa bu adım tamam.'**
  String get tvGuideA3Different;

  /// No description provided for @tvGuideA4Title.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici seçenekleri\'ni aç'**
  String get tvGuideA4Title;

  /// No description provided for @tvGuideA4Body.
  ///
  /// In tr, this message translates to:
  /// **'Geri tuşuyla bir ekran geri dön. Android TV\'de Cihaz Tercihleri, Google TV\'de Sistem altında yeni bir \"Geliştirici seçenekleri\" satırı belirdi; ona gir.'**
  String get tvGuideA4Body;

  /// No description provided for @tvGuideA4Different.
  ///
  /// In tr, this message translates to:
  /// **'Satırı göremiyorsan Ayarlar\'dan tamamen çıkıp yeniden gir. Hâlâ yoksa önceki adımda 7 kez basmayı yinele.'**
  String get tvGuideA4Different;

  /// No description provided for @tvGuideA5Title.
  ///
  /// In tr, this message translates to:
  /// **'\"USB hata ayıklama\"yı aç'**
  String get tvGuideA5Title;

  /// No description provided for @tvGuideA5Body.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici seçenekleri listesinde \"USB hata ayıklama\"yı bul ve aç; çıkan uyarıda \"Tamam\"ı seç. Listede \"Ağ üzerinden hata ayıklama\" ya da \"ADB ağ hata ayıklama\" varsa onu da aç.\n\nTV açıldığında burası kendiliğinden yeşile döner.'**
  String get tvGuideA5Body;

  /// No description provided for @tvGuideA5Different.
  ///
  /// In tr, this message translates to:
  /// **'Seçeneğin adı \"Hata ayıklama (ADB)\" ya da İngilizce \"USB debugging\" olabilir. Yalnız \"Kablosuz hata ayıklama\" olup eşleştirme kodu isteyen modeller (ör. Google TV Streamer) telefondan henüz kurulamıyor; bunlarda Rehber\'deki USB bellek yolunu kullan.'**
  String get tvGuideA5Different;

  /// No description provided for @tvGuideL1Title.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz LG geliştirici hesabı aç'**
  String get tvGuideL1Title;

  /// No description provided for @tvGuideL1Body.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun tarayıcısında aşağıdaki adrese gir, sağ üstten \"SIGN IN\", sonra \"Create Account\" ile ücretsiz hesap aç. E-postanı ve şifreni bir sonraki adımda TV\'de yazacaksın.'**
  String get tvGuideL1Body;

  /// No description provided for @tvGuideL1Different.
  ///
  /// In tr, this message translates to:
  /// **'LG hesabın zaten varsa (ör. LG ThinQ) aynı e-posta ve şifreyle giriş yapabilirsin; bu adımı geç.'**
  String get tvGuideL1Different;

  /// No description provided for @tvGuideL2Title.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye \"Developer Mode\" uygulamasını kur'**
  String get tvGuideL2Title;

  /// No description provided for @tvGuideL2Body.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de LG Content Store\'u (Uygulamalar) aç, arama kutusuna \"Developer Mode\" yaz ve uygulamayı yükle.'**
  String get tvGuideL2Body;

  /// No description provided for @tvGuideL2Different.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza açılmıyorsa TV internete bağlı mı kontrol et. Eski modellerde mağazanın adı \"LG Store\" ya da \"Uygulamalar\"dır. Uygulama ekranda İngilizce görünür.'**
  String get tvGuideL2Different;

  /// No description provided for @tvGuideL3Title.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap ve \"Dev Mode Status\"u aç'**
  String get tvGuideL3Title;

  /// No description provided for @tvGuideL3Body.
  ///
  /// In tr, this message translates to:
  /// **'Developer Mode uygulamasını aç, LG hesabının e-postası ve şifresiyle giriş yap. \"Dev Mode Status\" anahtarını aç. TV kendiliğinden yeniden başlar; açılmasını bekle.\n\nGeliştirici modu açıldığında burası kendiliğinden yeşile döner.'**
  String get tvGuideL3Body;

  /// No description provided for @tvGuideL3Different.
  ///
  /// In tr, this message translates to:
  /// **'\"Dev Mode Status\" gri ve seçilemiyorsa önce giriş yapılmamıştır. Giriş \"Login failed\" diyorsa hesabının e-postasını doğruladığından emin ol.'**
  String get tvGuideL3Different;

  /// No description provided for @tvGuideL4Title.
  ///
  /// In tr, this message translates to:
  /// **'\"Key Server\"ı aç'**
  String get tvGuideL4Title;

  /// No description provided for @tvGuideL4Body.
  ///
  /// In tr, this message translates to:
  /// **'TV açıldıktan sonra Developer Mode uygulamasını yeniden aç ve \"Key Server\" anahtarını aç. Uygulamayı ekranda bırak; kapatırsan Key Server da kapanır.\n\nKey Server açıldığında burası kendiliğinden yeşile döner.'**
  String get tvGuideL4Body;

  /// No description provided for @tvGuideL4Different.
  ///
  /// In tr, this message translates to:
  /// **'Ekranın sol altında 6 karakterlik \"Passphrase\" görünür; bir sonraki adımda onu yazacaksın.'**
  String get tvGuideL4Different;

  /// No description provided for @tvErrUnreachableAndroidTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV yanıt vermedi'**
  String get tvErrUnreachableAndroidTitle;

  /// No description provided for @tvErrUnreachableAndroidFix.
  ///
  /// In tr, this message translates to:
  /// **'TV açık mı ve telefonla aynı Wi-Fi ağında mı? Geliştirici seçeneklerinde \"USB hata ayıklama\" açık olmalı. Bazı TV\'lerde bu ayar TV yeniden başlayınca kapanır; açıp yeniden dene.'**
  String get tvErrUnreachableAndroidFix;

  /// No description provided for @tvErrUnreachableLgTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV yanıt vermedi'**
  String get tvErrUnreachableLgTitle;

  /// No description provided for @tvErrUnreachableLgFix.
  ///
  /// In tr, this message translates to:
  /// **'TV açık mı ve telefonla aynı Wi-Fi ağında mı? Developer Mode uygulamasında \"Dev Mode Status\" açık olmalı; açtıktan sonra TV yeniden başlar, açılmasını bekle.'**
  String get tvErrUnreachableLgFix;

  /// No description provided for @tvErrKeyServerOffTitle.
  ///
  /// In tr, this message translates to:
  /// **'Key Server kapalı'**
  String get tvErrKeyServerOffTitle;

  /// No description provided for @tvErrKeyServerOffFix.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de Developer Mode uygulamasını aç, \"Key Server\"ı aç ve uygulamayı ekranda bırak. Sonra yeniden dene.'**
  String get tvErrKeyServerOffFix;

  /// No description provided for @tvErrWrongPassphraseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Parola doğru değil'**
  String get tvErrWrongPassphraseTitle;

  /// No description provided for @tvErrWrongPassphraseFix.
  ///
  /// In tr, this message translates to:
  /// **'TV ekranında Developer Mode uygulamasının sol altındaki 6 karakterlik \"Passphrase\"i yeniden yaz. 0 (sıfır) ile O harfi, 1 ile I harfi karışabilir.'**
  String get tvErrWrongPassphraseFix;

  /// No description provided for @tvErrKeyRefusedTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV anahtarı kabul etmedi'**
  String get tvErrKeyRefusedTitle;

  /// No description provided for @tvErrKeyRefusedFix.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici modu kapatılıp açıldıysa TV yeni bir anahtar üretir. Key Server\'ı açıp parolayı yeniden yaz.'**
  String get tvErrKeyRefusedFix;

  /// No description provided for @tvErrNotApprovedTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de izin verilmedi'**
  String get tvErrNotApprovedTitle;

  /// No description provided for @tvErrNotApprovedFix.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene. TV\'de \"USB hata ayıklamaya izin verilsin mi?\" sorusu çıkınca \"Bu bilgisayardan her zaman izin ver\"i işaretleyip \"İzin ver\"i seç. Soru TV ekranında yaklaşık bir buçuk dakika bekler.'**
  String get tvErrNotApprovedFix;

  /// No description provided for @tvErrNoSpaceTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de yer kalmamış'**
  String get tvErrNoSpaceTitle;

  /// No description provided for @tvErrNoSpaceFix.
  ///
  /// In tr, this message translates to:
  /// **'TV\'den kullanmadığın bir uygulamayı kaldır ve yeniden dene.'**
  String get tvErrNoSpaceFix;

  /// No description provided for @tvErrConnectionLostTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı koptu'**
  String get tvErrConnectionLostTitle;

  /// No description provided for @tvErrConnectionLostFix.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum sırasında TV ile bağlantı kesildi. Telefonun ekranı açık ve Wi-Fi\'ye bağlı kalsın; yeniden dene.'**
  String get tvErrConnectionLostFix;

  /// No description provided for @tvErrTooOldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu TV çok eski'**
  String get tvErrTooOldTitle;

  /// No description provided for @tvErrTooOldFix.
  ///
  /// In tr, this message translates to:
  /// **'GameTranslator TV uygulaması bu TV\'nin yazılımında çalışmıyor.'**
  String get tvErrTooOldFix;

  /// No description provided for @tvErrPackageMissingTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV paketi bulunamadı'**
  String get tvErrPackageMissingTitle;

  /// No description provided for @tvErrPackageMissingFix.
  ///
  /// In tr, this message translates to:
  /// **'Bu telefon uygulamasının içinde TV paketi yok. Uygulamanın son sürümünü kur.'**
  String get tvErrPackageMissingFix;

  /// No description provided for @tvErrCancelledTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum durduruldu'**
  String get tvErrCancelledTitle;

  /// No description provided for @tvErrCancelledFix.
  ///
  /// In tr, this message translates to:
  /// **'Hazır olduğunda yeniden başlatabilirsin.'**
  String get tvErrCancelledFix;

  /// No description provided for @tvErrGenericTitle.
  ///
  /// In tr, this message translates to:
  /// **'TV uygulaması kurulamadı'**
  String get tvErrGenericTitle;

  /// No description provided for @tvErrGenericFix.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene. TV\'yi kapatıp açmak yarım kalan kurulumların çoğunu düzeltir. Yine olmazsa aşağıdaki \"TV\'nin söylediği\" yazısıyla birlikte bize bildir.'**
  String get tvErrGenericFix;

  /// No description provided for @tvStageUploading.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama TV\'ye gönderiliyor… %{percent}'**
  String tvStageUploading(String percent);

  /// No description provided for @tvStageConnecting.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye bağlanılıyor…'**
  String get tvStageConnecting;

  /// No description provided for @tvStageApprove.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de izin bekleniyor…'**
  String get tvStageApprove;

  /// No description provided for @tvStageChecking.
  ///
  /// In tr, this message translates to:
  /// **'TV\'deki sürüme bakılıyor…'**
  String get tvStageChecking;

  /// No description provided for @tvStageKey.
  ///
  /// In tr, this message translates to:
  /// **'TV\'den anahtar alınıyor…'**
  String get tvStageKey;

  /// No description provided for @tvStageInstalling.
  ///
  /// In tr, this message translates to:
  /// **'TV\'ye kuruluyor…'**
  String get tvStageInstalling;

  /// No description provided for @tvStageVerifying.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum doğrulanıyor…'**
  String get tvStageVerifying;

  /// No description provided for @tvStageLaunching.
  ///
  /// In tr, this message translates to:
  /// **'TV\'de açılıyor…'**
  String get tvStageLaunching;

  /// No description provided for @tvStagePreparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor…'**
  String get tvStagePreparing;

  /// No description provided for @psnErrAuth.
  ///
  /// In tr, this message translates to:
  /// **'Sony girişi kabul etmedi (HTTP {status}){detail}'**
  String psnErrAuth(int status, String detail);

  /// No description provided for @psnErrAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap kimliği alınamadı (HTTP {status})'**
  String psnErrAccount(int status);

  /// No description provided for @psnErrNetwork.
  ///
  /// In tr, this message translates to:
  /// **'Sony\'ye ulaşılamadı: {error}'**
  String psnErrNetwork(String error);

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// No description provided for @settingsAppLanguageAuto.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz dili'**
  String get settingsAppLanguageAuto;
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
