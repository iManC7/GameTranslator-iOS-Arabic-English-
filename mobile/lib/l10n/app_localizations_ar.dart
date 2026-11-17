// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'GameTranslator';

  @override
  String get tabTranslate => 'الترجمة';

  @override
  String get tabGuide => 'الدليل';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsGroupApp => 'التطبيق';

  @override
  String get settingsAppLanguage => 'لغة التطبيق';

  @override
  String get settingsAppLanguageNote =>
      'لغة الواجهة فقط؛ لا تغيّر لغة اللعبة أو الترجمة.';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get setupTitle => 'الإعداد';

  @override
  String get setupSubtitleAccount => 'اربط حساب PlayStation أولًا.';

  @override
  String get setupSubtitlePs5 => 'أكمل الاتصال بـ PS5.';

  @override
  String get setupSignInTitle => 'سجّل الدخول عبر PSN';

  @override
  String get setupSignInSubtitle => 'اربط حساب PlayStation Network.';

  @override
  String get setupSignedIn => 'تم ربط حساب PSN.';

  @override
  String get setupChange => 'تغيير';

  @override
  String get setupSignInBody =>
      'سجّل الدخول بحساب PSN للمستخدم الثاني (الحساب الفرعي) على PS5. وبذلك لا ينفصل ذراع التحكم عن التلفاز وأنت تلعب بحسابك.';

  @override
  String get setupSignInPrivacy =>
      'تسجيل الدخول يتم في صفحة Sony نفسها. لا تُحفظ كلمة مرورك في هذا التطبيق أو في أي مكان آخر.';

  @override
  String get setupPairTitle => 'اقترن بـ PS5';

  @override
  String get setupPairSubtitle => 'اقترن هاتفك بـ PS5.';

  @override
  String get setupPairStepA => 'انتقل إلى المستخدم الثاني على PS5.';

  @override
  String get setupPairStepB =>
      'في الإعدادات › النظام › Remote Play، شغّل \"تمكين Remote Play\".';

  @override
  String get setupPairStepC =>
      'افتح \"ربط الجهاز\". يظهر رمز من 8 أرقام على الشاشة.';

  @override
  String get setupFoundConsole => 'الجهاز المكتشف';

  @override
  String get setupSearching => 'جارٍ البحث…';

  @override
  String get setupRefresh => 'تحديث';

  @override
  String get setupNotFound =>
      'لم يُعثر على PS5. يجب أن يكون الهاتف وPS5 على نفس شبكة Wi-Fi. يمكنك أيضًا كتابة عنوان IP لـ PS5 أدناه (على PS5: الإعدادات › الشبكة › حالة الاتصال).';

  @override
  String get setupIpLabel => 'عنوان IP لـ PS5';

  @override
  String get setupEnterIp => 'أدخل عنوان IP يدويًا';

  @override
  String get setupPairCode => 'رمز الاقتران';

  @override
  String get setupErrorNoHost => 'اختر PS5 أولًا أو اكتب عنوان IP.';

  @override
  String get setupErrorPin => 'أدخل الرمز المكوّن من 8 أرقام الظاهر على PS5.';

  @override
  String get setupErrorPairFailed => 'فشل الاقتران.';

  @override
  String get setupPairing => 'جارٍ الاقتران…';

  @override
  String get setupPairAction => 'اقترن';

  @override
  String setupStepOf(int number) {
    return 'الخطوة $number / 2';
  }

  @override
  String get setupWaitingPsn => 'أكمل تسجيل الدخول عبر PSN أولًا.';

  @override
  String get setupConsoleAwake => 'مشغّل';

  @override
  String get setupConsoleResting => 'في وضع السكون';

  @override
  String get setupPsnLoginTitle => 'تسجيل دخول PSN';

  @override
  String get setupLoginIncomplete => 'لم يكتمل تسجيل الدخول.';

  @override
  String get setupManualId => 'أدخل معرّف الحساب يدويًا';

  @override
  String get setupManualIdHelp =>
      'إذا لم تُفتح صفحة تسجيل الدخول، يمكنك لصق معرّف حساب PSN الذي حصلت عليه من أداة مثل Chiaki هنا.';

  @override
  String get setupManualIdHint => 'معرّف الحساب بصيغة Base64';

  @override
  String get setupManualIdError =>
      'يجب أن يكون معرّف الحساب 8 بايت بصيغة base64.';

  @override
  String get setupReload => 'أعد تحميل الصفحة';

  @override
  String get setupConnectingAccount => 'جارٍ ربط الحساب…';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get splashTagline => 'العب بلغتك';

  @override
  String get devicePs5 => 'PS5';

  @override
  String get devicePhone => 'الهاتف';

  @override
  String get deviceTv => 'التلفاز';

  @override
  String get introSkip => 'تخطّي';

  @override
  String get introClose => 'إغلاق';

  @override
  String get introContinue => 'متابعة';

  @override
  String get introDone => 'تم';

  @override
  String get introStartSetup => 'ابدأ الإعداد';

  @override
  String get introWelcomeTitle => 'العب بلغتك';

  @override
  String get introWelcomeBody =>
      'يترجم ترجمات ألعاب PS5 فورًا ويعرضها على تلفازك.';

  @override
  String get introHowTitle => 'هاتفك هو المترجم الوسيط';

  @override
  String get introHowBody =>
      'يلتقط الهاتف صورة اللعبة من PS5 عبر Remote Play، ويقرأ الترجمة ويترجمها ويرسلها إلى التلفاز. بلا كاميرا، ويعمل حتى والشاشة مغلقة.';

  @override
  String get introFlowVideo => 'الصورة';

  @override
  String get introFlowPhone => 'الهاتف';

  @override
  String get introFlowTranslates => 'يترجم';

  @override
  String get introFlowShows => 'يعرض';

  @override
  String get introSampleOriginal => 'We have to leave before sunrise.';

  @override
  String get introSampleTranslation => 'يجب أن نرحل قبل شروق الشمس.';

  @override
  String get introNeedsTitle => 'قبل أن تبدأ';

  @override
  String get introNeedsBody => 'يستغرق الإعداد بضع دقائق. جهّز ما يلي:';

  @override
  String get introNeedSecondUserTitle => 'مستخدم ثانٍ على PS5';

  @override
  String get introNeedSecondUserText =>
      'تلعب بحسابك؛ يتصل الهاتف بالحساب الثاني، فلا ينفصل ذراع التحكم عن التلفاز.';

  @override
  String get introNeedTvAppTitle => 'تطبيق GameTranslator على التلفاز';

  @override
  String get introNeedTvAppText =>
      'يعمل على Samsung وLG وAndroid TV. يتم التثبيت على التلفاز من GameTranslator على الحاسوب.';

  @override
  String get introNeedWifiTitle => 'نفس شبكة Wi-Fi';

  @override
  String get introNeedWifiText =>
      'يجب أن يكون الهاتف وPS5 والتلفاز على نفس شبكة المنزل.';

  @override
  String get homeStateStreamingTitle => 'الترجمة مفعّلة';

  @override
  String get homeStateStreamingHint =>
      'يمكنك إطفاء الشاشة؛ تستمر الترجمة في الخلفية.';

  @override
  String get homeStateStartingTitle => 'جارٍ البدء…';

  @override
  String get homeStateStartingHint => 'يستغرق بضع ثوانٍ.';

  @override
  String get homeStateConnectingTitle => 'جارٍ الاتصال بـ PS5…';

  @override
  String get homeStateConnectingHint =>
      'يجب أن يكون PS5 مشغّلًا وعلى نفس شبكة Wi-Fi.';

  @override
  String get homeStateWakingTitle => 'جارٍ إيقاظ PS5…';

  @override
  String get homeStateWakingHint => 'قد يستغرق الخروج من وضع السكون دقيقة.';

  @override
  String get homeStateReconnectingTitle => 'جارٍ إعادة الاتصال…';

  @override
  String get homeStateReconnectingHint =>
      'انقطع الاتصال، وتجري إعادة المحاولة.';

  @override
  String get homeStateStoppingTitle => 'جارٍ الإيقاف…';

  @override
  String get homeStateFailedTitle => 'تعذّر البدء';

  @override
  String get homeStateFailedHint => 'اضغط لإعادة المحاولة.';

  @override
  String get homeStateIdleTitle => 'الترجمة متوقفة';

  @override
  String get homeStateIdleHint => 'اضغط للبدء.';

  @override
  String get homeNodeConnected => 'متصل';

  @override
  String get homeNodeWaking => 'يستيقظ';

  @override
  String get homeNodeConnecting => 'يتصل';

  @override
  String get homeNodePaired => 'مقترن';

  @override
  String get homeNodeNoWifi => 'لا Wi-Fi';

  @override
  String get homeNodeTranslating => 'يترجم';

  @override
  String get homeNodeReady => 'جاهز';

  @override
  String get homeNodeWaiting => 'بانتظار';

  @override
  String get homeNodeNotConnected => 'غير متصل';

  @override
  String get homeTestSentToast => 'أُرسلت ترجمة تجريبية إلى التلفاز.';

  @override
  String get homeTestNoTvToast =>
      'لا يوجد تلفاز متصل. افتح GameTranslator على التلفاز أولًا.';

  @override
  String get homeUnsupportedTitle => 'هذا الهاتف غير مدعوم';

  @override
  String get homeUnsupportedText =>
      'تعذّر تحميل مكتبة Remote Play على هذا الجهاز.';

  @override
  String get homeNoWifiTitle => 'لا يوجد اتصال Wi-Fi';

  @override
  String get homeNoWifiText =>
      'يجب أن يكون الهاتف على نفس شبكة Wi-Fi مع PS5 والتلفاز.';

  @override
  String get homeOpenTvTitle => 'افتح GameTranslator على التلفاز';

  @override
  String get homeOpenTvText =>
      'يجد تطبيق التلفاز الهاتف على الشبكة تلقائيًا؛ بعد فتحه يستغرق الاتصال بضع ثوانٍ.';

  @override
  String get homeTvStuckTitle => 'لم يتصل التلفاز بعد';

  @override
  String get homeTvStuckText =>
      'إذا كان تطبيق التلفاز قد اتصل بحاسوب سابقًا فقد يعلق على العنوان القديم. مسح بيانات التطبيق على التلفاز مرة واحدة يحل المشكلة.';

  @override
  String get homeTvStuckAction => 'أرني خطوة بخطوة';

  @override
  String get homeLiveGroup => 'مباشر';

  @override
  String get homeSendTest => 'أرسل ترجمة تجريبية إلى التلفاز';

  @override
  String get homeAdjustRegion => 'اضبط منطقة الترجمة';

  @override
  String get homeHowGroup => 'كيف تستخدم';

  @override
  String get homeHowStep1 => 'شغّل الترجمة في اللعبة.';

  @override
  String get homeHowStep2 => 'ابدأ الترجمة بالزر أعلاه.';

  @override
  String get homeHowStep3 =>
      'افتح GameTranslator على التلفاز؛ تظهر الترجمة فوق اللعبة.';

  @override
  String get homeInstallTvTitle => 'ثبّت تطبيق التلفاز';

  @override
  String get homeInstallTvSubtitle => 'إذا لم يكن GameTranslator على تلفازك';

  @override
  String get homeDetailedGuide => 'دليل مفصّل';

  @override
  String get homeStartTranslation => 'ابدأ الترجمة';

  @override
  String get homeStopTranslation => 'أوقف الترجمة';

  @override
  String get homePreviewPreparing => 'جارٍ تجهيز المعاينة…';

  @override
  String get homeAwaitingPs5 => 'بانتظار صورة PS5…';

  @override
  String get homeLastTranslation => 'آخر ترجمة';

  @override
  String get homeWaitingSubtitle =>
      'عند ظهور ترجمة في اللعبة تظهر ترجمتها هنا وعلى التلفاز.';

  @override
  String get homeRegionReadLabel => 'المقروء داخل الإطار';

  @override
  String get homeNothingRead => 'لا يوجد نص الآن.';

  @override
  String get settingsGroupTranslate => 'الترجمة';

  @override
  String get settingsSourceLanguage => 'لغة اللعبة';

  @override
  String get settingsTargetLanguage => 'لغة الترجمة';

  @override
  String get settingsGlossary => 'قاموس المصطلحات';

  @override
  String get settingsGlossaryEmpty => 'فارغ';

  @override
  String get settingsGlossaryInvalid => 'غير صالح';

  @override
  String settingsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مصطلح',
      many: '$count مصطلحًا',
      few: '$count مصطلحات',
      two: 'مصطلحان',
      one: 'مصطلح واحد',
      zero: 'لا مصطلحات',
    );
    return '$_temp0';
  }

  @override
  String get settingsPacks => 'حزم الألعاب';

  @override
  String get settingsPacksNote => 'GTA V وRDR2 وElden Ring… بترجمات جاهزة';

  @override
  String get settingsGame => 'اللعبة';

  @override
  String get settingsGameAuto => 'تلقائي';

  @override
  String get settingsGameAutoOption => 'تلقائي (يتعرّف على اللعبة)';

  @override
  String settingsGameOptionLine(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سطر',
      many: '$count سطرًا',
      few: '$count أسطر',
      two: 'سطران',
      one: 'سطر واحد',
      zero: 'لا أسطر',
    );
    return '$title · $_temp0';
  }

  @override
  String get settingsPatches => 'حدّث تصحيحات المجتمع';

  @override
  String get settingsPatchesBusy => 'جارٍ فحص التصحيحات…';

  @override
  String get settingsPatchesNote =>
      'ينزّل تصحيحات الألعاب الجديدة والمحدّثة (أسبوعيًا تلقائيًا)';

  @override
  String get settingsHideButtonHints => 'أخفِ تسميات الأزرار';

  @override
  String get settingsHideButtonHintsNote =>
      'لا تُترجم تسميات مثل \"SKIP\" أو \"RESUME\" بجانب الترجمة';

  @override
  String get settingsPacksFooter =>
      'تُعرض الأسطر الموجودة في حزمة اللعبة من الحزمة دون الرجوع إلى محرك الترجمة. الحزم من مجتمع CouchSubs وتُحدَّث أسبوعيًا.';

  @override
  String get settingsGroupEngine => 'محرك الترجمة';

  @override
  String get settingsEngineGoogleNote =>
      'يحتاج إنترنت ولا يحتاج مفتاحًا. مُوصى به لمعظم الألعاب.';

  @override
  String get settingsEngineDeeplNote =>
      'جمل أكثر طبيعية؛ يعمل بمفتاح DeepL API الخاص بك.';

  @override
  String get settingsDeeplKeyHint => 'مفتاح DeepL API';

  @override
  String get settingsEngineGeminiNote =>
      'أطبع صياغة بالذكاء الاصطناعي. يعمل بمفتاح مجاني؛ وعند بلوغ الحد يُستخدم Google لدقيقة.';

  @override
  String get settingsGeminiKeyHint => 'مفتاح Gemini API';

  @override
  String get settingsGeminiChecking => 'جارٍ الاختبار…';

  @override
  String get settingsGeminiSaveTest => 'احفظ واختبر';

  @override
  String get settingsGeminiGetKey => 'احصل على مفتاح Google Gemini API مجاني';

  @override
  String get settingsEngineOnDevice => 'على الجهاز';

  @override
  String get settingsEngineOnDeviceIosNote =>
      'يعمل بلا إنترنت (ترجمة Apple). نزّل أولًا الإنجليزية والتركية من إعدادات iPhone › التطبيقات › الترجمة › اللغات المنزّلة.';

  @override
  String get settingsEngineOnDeviceAndroidNote =>
      'يعمل بلا إنترنت؛ جودته أقل. يُنزَّل نموذج اللغة مرة واحدة.';

  @override
  String get settingsEngineFooter =>
      'إذا انقطع الإنترنت تنتقل الترجمة تلقائيًا إلى نموذج الجهاز. وإذا كان مفتاح DeepL فارغًا أو لا يعمل يُستخدم Google.';

  @override
  String get settingsGroupRegion => 'منطقة الترجمة';

  @override
  String get settingsEdgeTop => 'أعلى';

  @override
  String get settingsEdgeBottom => 'أسفل';

  @override
  String get settingsEdgeLeft => 'يسار';

  @override
  String get settingsEdgeRight => 'يمين';

  @override
  String get settingsResetDefault => 'إعادة إلى الافتراضي';

  @override
  String get settingsRegionFooter =>
      'ضع الإطار الأزرق حيث تظهر ترجمة اللعبة. إذا كان الإطار ضيقًا تُقطع بداية الجملة أو نهايتها.';

  @override
  String get settingsGroupTvLook => 'على التلفاز';

  @override
  String get settingsFontSize => 'حجم الخط';

  @override
  String get settingsFontSmall => 'صغير';

  @override
  String get settingsFontMedium => 'متوسط';

  @override
  String get settingsFontLarge => 'كبير';

  @override
  String get settingsFontHuge => 'ضخم';

  @override
  String get settingsTextColor => 'لون النص';

  @override
  String get settingsWhite => 'أبيض';

  @override
  String get settingsYellow => 'أصفر';

  @override
  String get settingsPlacement => 'موضع الترجمة';

  @override
  String get settingsPlacementCover => 'تغطية ترجمة اللعبة';

  @override
  String get settingsPlacementAbove => 'فوق ترجمة اللعبة';

  @override
  String get settingsPlacementBelow => 'تحت ترجمة اللعبة';

  @override
  String get settingsPlacementFixed => 'ثابت أسفل الشاشة';

  @override
  String get settingsBackground => 'عتامة الخلفية';

  @override
  String get settingsBold => 'نص عريض';

  @override
  String get settingsSpeakerColor => 'اسم المتحدث ملوّن';

  @override
  String get settingsSpeakerColorNote =>
      'اسم المتحدث (مثل ENZO:) بالأصفر، وأزرق فاتح على النص الأصفر';

  @override
  String get settingsSendTest => 'أرسل ترجمة تجريبية إلى التلفاز';

  @override
  String get settingsTestSent => 'أُرسلت الترجمة التجريبية.';

  @override
  String get settingsGroupTvApp => 'تطبيق التلفاز';

  @override
  String get settingsInstallTv => 'ثبّت تطبيق التلفاز';

  @override
  String get settingsInstallTvNote =>
      'إلى LG وAndroid TV من الهاتف؛ وللتحديث أيضًا';

  @override
  String get settingsPaired => 'مقترن';

  @override
  String get settingsAutoWake => 'إيقاظ من وضع السكون';

  @override
  String get settingsAutoWakeFooter =>
      'إذا كان PS5 في وضع السكون عند بدء الترجمة يُشغَّل.';

  @override
  String get settingsRepair => 'أعد اقتران PS5';

  @override
  String get settingsChangeAccount => 'غيّر حساب PSN';

  @override
  String get settingsGroupAbout => 'حول';

  @override
  String get settingsShowIntro => 'اعرض المقدمة';

  @override
  String get settingsLogs => 'السجل';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsAboutFooter =>
      'تبقى صورة اللعبة وبيانات حسابك على الهاتف. وإذا اختير محرك عبر الإنترنت يُرسل نص الترجمة المقروء فقط إلى خدمة الترجمة.\n\nGameTranslator مفتوح المصدر (AGPL-3.0). لا علاقة له بـ Sony أو PlayStation.';

  @override
  String get settingsForgetTitleAccount => 'هل تريد تغيير حساب PSN؟';

  @override
  String get settingsForgetTitleConsole => 'هل تريد إعادة اقتران PS5؟';

  @override
  String get settingsForgetMessageAccount =>
      'يُحذف الحساب المحفوظ واقتران PS5؛ وستعيد الإعداد من البداية.';

  @override
  String get settingsForgetMessageConsole =>
      'يُحذف الاقتران المحفوظ؛ وتعيد الاقتران برمز \"ربط الجهاز\" على PS5.';

  @override
  String get settingsForgetAction => 'احذف وتابع';

  @override
  String get settingsLogsEmpty => 'لا توجد سجلات بعد.';

  @override
  String get settingsLogTitle => 'السجل';

  @override
  String get settingsCopy => 'نسخ';

  @override
  String get settingsLogCopied => 'نُسخ السجل.';

  @override
  String get settingsLogNote =>
      'عند حدوث مشكلة يمكنك مشاركة هذه السجلات مع الدعم.';

  @override
  String get settingsRegionPreviewNote =>
      'تظهر صورة اللعبة هنا عندما تكون الترجمة مفعّلة.';

  @override
  String get settingsGlossaryTitle => 'قاموس المصطلحات';

  @override
  String get settingsSave => 'حفظ';

  @override
  String get settingsGlossaryHelp =>
      'ثبّت هنا الأسماء الخاصة ومصطلحات اللعبة التي يخطئ فيها المترجم. تُترجم المصطلحات في \"terms\" إلى النص الذي تكتبه، وتبقى الأسماء في \"keep\" كما هي.';

  @override
  String get settingsGlossaryEmptyNote =>
      'القاموس فارغ. يمكنك البدء من مثال واستبداله بمصطلحاتك.';

  @override
  String get settingsGlossaryAddExample => 'أضف مثالًا';

  @override
  String settingsGlossaryRead(int terms, int keep) {
    return 'قُرئ $terms مصطلحًا و$keep اسمًا محفوظًا.';
  }

  @override
  String get settingsGlossaryFooter =>
      'بالصيغة نفسها لملفات قاموس GameTranslator على الحاسوب؛ يمكنك لصق محتوى الملف هنا. يُستخدم فقط في الترجمة من الإنجليزية إلى التركية.';

  @override
  String get settingsGlossaryErrorShape =>
      'يجب أن يكون القاموس كائن JSON بين قوسين معقوفين.';

  @override
  String get settingsGlossaryErrorSyntax =>
      'يوجد خطأ إملائي: تحقّق من علامات التنصيص والفاصلة والأقواس.';

  @override
  String homeLinesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سطر',
      many: '$count سطرًا',
      few: '$count أسطر',
      two: 'سطران',
      one: 'سطر واحد',
      zero: 'لا أسطر',
    );
    return '$_temp0';
  }

  @override
  String homePackUsage(String game, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سطر',
      many: '$count سطرًا',
      few: '$count أسطر',
      two: 'سطران',
      one: 'سطر واحد',
      zero: 'لا أسطر',
    );
    return 'حزمة $game قيد الاستخدام · $_temp0 من الحزمة';
  }
}
