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
  String get guideIntro => 'كل شيء من الإعداد إلى حل المشكلات، خطوة بخطوة.';

  @override
  String get guidePhoneAddress => 'عنوان هاتفك';

  @override
  String get guideGroupStart => 'البداية';

  @override
  String get guideGroupUsage => 'الاستخدام';

  @override
  String get guideGroupHelp => 'المساعدة';

  @override
  String get guideNextChapter => 'الفصل التالي';

  @override
  String get guideTvHelpTitle => 'التلفاز لا يتصل';

  @override
  String get gHowTitle => 'كيف يعمل؟';

  @override
  String get gHowSubtitle => 'المنظومة كاملة بلمحة';

  @override
  String get gHowLead =>
      'يربط GameTranslator ثلاثة أجهزة. اللعبة تعمل على PS5، وأنت تلعب على التلفاز، والهاتف يترجم في الوسط:';

  @override
  String get gHowStep1 =>
      'يأخذ الهاتف صورة اللعبة من PS5 عبر Remote Play. لا تُستخدم الكاميرا.';

  @override
  String get gHowStep2 =>
      'يقرأ المنطقة التي تظهر فيها الترجمة في الصورة ويترجم النص.';

  @override
  String get gHowStep3 =>
      'يرسل الترجمة إلى التلفاز على نفس شبكة Wi-Fi، ويعرضها تطبيق GameTranslator فوق اللعبة.';

  @override
  String get gHowNeedsTitle => 'ما المطلوب؟';

  @override
  String get gHowNeed1 => 'جهاز PS5 وعليه مستخدم ثانٍ (موضّح أدناه).';

  @override
  String get gHowNeed2 =>
      'تلفاز مثبّت عليه تطبيق GameTranslator: LG أو Samsung أو Android TV / Google TV.';

  @override
  String get gHowNeed3 =>
      'شبكة منزلية واحدة (Wi-Fi) يتصل بها الهاتف وPS5 والتلفاز.';

  @override
  String get gHowNeed4 =>
      'إنترنت للترجمة عبر الإنترنت. وهناك خيار ترجمة يعمل بلا إنترنت.';

  @override
  String get gHowTip =>
      'الإعداد يتم مرة واحدة. بعدها كل ما تفعله: بدء الترجمة وفتح التطبيق على التلفاز.';

  @override
  String get gPs5Title => 'جهّز PS5';

  @override
  String get gPs5Subtitle => 'مستخدم ثانٍ وRemote Play';

  @override
  String get gPs5UserTitle => '1. أضف مستخدمًا ثانيًا';

  @override
  String get gPs5UserBody =>
      'يعتبر PS5 الجهاز المتصل عبر Remote Play ذراع تحكم ذلك المستخدم. فإذا اتصل الهاتف بحسابك انفصل ذراعك عن التلفاز. لذلك يتصل الهاتف بمستخدم منفصل؛ وتستمر أنت باللعب بحسابك.';

  @override
  String get gPs5UserStep1 =>
      'أضف مستخدمًا جديدًا على PS5 (من صورة الملف على الشاشة الرئيسية: تبديل المستخدم › إضافة مستخدم).';

  @override
  String get gPs5UserStep2 =>
      'سجّل دخول هذا المستخدم بحساب PSN. يمكنك إنشاء حساب مجانًا؛ لا حاجة إلى PS Plus.';

  @override
  String get gPs5UserStep3 =>
      'ستسجّل الدخول إلى PSN على الهاتف أيضًا بهذا الحساب الثاني.';

  @override
  String get gPs5RemoteTitle => '2. شغّل Remote Play';

  @override
  String get gPs5RemoteStep1 => 'انتقل إلى المستخدم الثاني على PS5.';

  @override
  String get gPs5RemoteStep2 => 'ادخل إلى الإعدادات › النظام › Remote Play.';

  @override
  String get gPs5RemoteStep3 => 'شغّل \"تمكين Remote Play\".';

  @override
  String get gPs5WakeTitle => '3. الإيقاظ من وضع السكون (اختياري)';

  @override
  String get gPs5WakeBody =>
      'ليتمكن الهاتف من إيقاظ PS5 عند بدء الترجمة وهو في وضع السكون:';

  @override
  String get gPs5WakeStep1 =>
      'ادخل إلى الإعدادات › النظام › توفير الطاقة › الميزات المتاحة في وضع السكون.';

  @override
  String get gPs5WakeStep2 =>
      'شغّل \"البقاء متصلًا بالإنترنت\" و\"تمكين تشغيل PS5 من الشبكة\".';

  @override
  String get gPs5Tip =>
      'إن لم ترغب في الإيقاظ، أوقف على الهاتف: الإعدادات › PS5 › \"الإيقاظ من وضع السكون\".';

  @override
  String get gPairTitle => 'اقترن الهاتف بـ PS5';

  @override
  String get gPairSubtitle => 'تسجيل الدخول عبر PSN والرمز المكوّن من 8 أرقام';

  @override
  String get gPairSignInTitle => '1. سجّل الدخول عبر PSN';

  @override
  String get gPairSignInStep1 =>
      'في شاشة الإعداد اضغط \"سجّل الدخول عبر PSN\". تُفتح صفحة Sony الرسمية.';

  @override
  String get gPairSignInStep2 => 'سجّل الدخول بحساب المستخدم الثاني على PS5.';

  @override
  String get gPairSignInStep3 =>
      'عند انتهاء تسجيل الدخول يعود التطبيق إلى الإعداد تلقائيًا ويظهر \"تم ربط حساب PSN\".';

  @override
  String get gPairSignInTip =>
      'كلمة مرورك تذهب إلى Sony مباشرة؛ والتطبيق يحفظ معرّف حسابك فقط.';

  @override
  String get gPairCodeTitle => '2. أدخل رمز الاقتران';

  @override
  String get gPairCodeStep1 =>
      'على PS5 وأنت على المستخدم الثاني، ادخل إلى الإعدادات › النظام › Remote Play › \"ربط الجهاز\".';

  @override
  String get gPairCodeStep2 =>
      'يظهر على الشاشة رمز من 8 أرقام وعدّ تنازلي. الرمز صالح نحو 5 دقائق.';

  @override
  String get gPairCodeStep3 =>
      'على الهاتف اختر جهاز PS5 من قائمة \"الجهاز المكتشف\".';

  @override
  String get gPairCodeStep4 => 'اكتب الرمز في المربعات واضغط \"اقترن\".';

  @override
  String get gPairMissingTitle => 'إذا لم يظهر PS5 في القائمة';

  @override
  String get gPairMissing1 =>
      'تأكد أن الهاتف وPS5 على نفس شبكة Wi-Fi؛ لا شبكة ضيوف ولا بيانات جوّال.';

  @override
  String get gPairMissing2 => 'اضغط \"تحديث\".';

  @override
  String get gPairMissing3 =>
      'إن لم يظهر، اضغط \"أدخل عنوان IP يدويًا\". يظهر العنوان على PS5 في الإعدادات › الشبكة › حالة الاتصال › عرض حالة الاتصال.';

  @override
  String get gPairTip =>
      'الاقتران يتم مرة واحدة. وإذا تغيّر عنوان PS5 يجده التطبيق على الشبكة من جديد.';

  @override
  String get gTvTitle => 'جهّز التلفاز';

  @override
  String get gTvSubtitle => 'التلفازات المدعومة وتطبيق التلفاز';

  @override
  String get gTvLead =>
      'هناك تطبيق GameTranslator منفصل للتلفاز يعرض الترجمة عليه. لم يكن في المتاجر بعد، لذا يُثبَّت على التلفاز مرة واحدة. يمكنك تثبيته على LG وAndroid TV من هذا الهاتف؛ أما على Samsung فالتثبيت يتم حاليًا من حاسوب.';

  @override
  String get gTvSupportedTitle => 'أي التلفازات مدعومة؟';

  @override
  String get gTvTableLg => 'LG';

  @override
  String get gTvTableLgDetail => 'webOS 4 وما بعده';

  @override
  String get gTvTableSamsung => 'Samsung';

  @override
  String get gTvTableSamsungDetail => 'Tizen، 2019 وما بعده';

  @override
  String get gTvTableAndroid => 'Android TV / Google TV';

  @override
  String get gTvTableAndroidDetail =>
      'Vestel وArçelik وBeko وGrundig وPhilips وSony وTCL وغيرها';

  @override
  String get gTvTableOther => 'أخرى';

  @override
  String get gTvTableOtherDetail =>
      'موديلات Linux من Vestel/Arçelik/Beko/Grundig، وPhilips Saphi، وTitan OS';

  @override
  String get gTvNotSupported =>
      'غير مدعوم: لا يمكن تثبيت التطبيق على هذه التلفازات.';

  @override
  String get gTvAndroidTip =>
      'هل تلفازك Android؟ إن ظهر Google Play Store أو \"Google TV\" على شاشته الرئيسية فهو كذلك.';

  @override
  String get gTvLgTitle => 'LG';

  @override
  String get gTvLgStep1 =>
      'من حاسوب، أنشئ حساب مطوّر LG مجانيًا على webostv.developer.lge.com.';

  @override
  String get gTvLgStep2 =>
      'على التلفاز ثبّت تطبيق \"Developer Mode\" من LG Content Store، وسجّل الدخول بحسابك وشغّل \"Dev Mode Status\". سيُعاد تشغيل التلفاز.';

  @override
  String get gTvLgStep3 =>
      'في تطبيق Developer Mode على التلفاز شغّل \"Key Server\".';

  @override
  String get gTvLgStep4 =>
      'على الهاتف اختر LG في معالج \"ثبّت تطبيق التلفاز\"، واعثر على تلفازك واكتب كلمة المرور المكوّنة من 6 أحرف الظاهرة على الشاشة (خطوة التلفاز في GameTranslator على الحاسوب تفعل الشيء نفسه).';

  @override
  String get gTvLgNote =>
      'في LG يبقى وضع المطوّر مفعّلًا 1000 ساعة كحد أقصى. إن لم تستخدمه مدة طويلة فاضغط \"EXTEND\" في تطبيق Developer Mode قبل انتهاء المدة؛ وإذا انتهت يُحذف تطبيق التلفاز وتحتاج إلى تثبيته من جديد.';

  @override
  String get gTvSamsungTitle => 'Samsung';

  @override
  String get gTvSamsungStep1 =>
      'على التلفاز افتح شاشة التطبيقات واضغط 1 2 3 4 5 في الريموت. تُفتح نافذة وضع المطوّر.';

  @override
  String get gTvSamsungStep2 =>
      'شغّل \"Developer mode\" واكتب عنوان حاسوبك في خانة \"Host PC IP\".';

  @override
  String get gTvSamsungStep3 =>
      'أطفئ التلفاز تمامًا ثم شغّله بالضغط المستمر على زر الطاقة.';

  @override
  String get gTvSamsungStep4 =>
      'في خطوة التلفاز في GameTranslator على الحاسوب اختر تلفازك. في الصفحة التي تُفتح سجّل الدخول بحساب Samsung مجاني؛ يُوقَّع التطبيق ويُثبَّت.';

  @override
  String get gTvAndroidTitle => 'Android TV / Google TV';

  @override
  String get gTvAndroidStep1 =>
      'على التلفاز ادخل إلى الإعدادات › تفضيلات الجهاز › حول (في Google TV: الإعدادات › النظام › حول).';

  @override
  String get gTvAndroidStep2 => 'اضغط زر OK سبع مرات على \"رقم البنية\".';

  @override
  String get gTvAndroidStep3 =>
      'من خيارات المطوّر شغّل \"تصحيح أخطاء USB\" (و\"تصحيح أخطاء الشبكة\" إن وُجد).';

  @override
  String get gTvAndroidStep4 =>
      'على الهاتف اختر \"Android TV / Google TV\" في معالج \"ثبّت تطبيق التلفاز\" ووافق على الطلب الظاهر على التلفاز.';

  @override
  String get gTvAndroidNote =>
      'إذا لم يسمح التلفاز بتصحيح الأخطاء عبر الشبكة يمكنك التثبيت بذاكرة USB: نزّل ملف APK لتطبيق التلفاز من صفحة الإصدارات في GameTranslator، وانسخه إلى الذاكرة وافتحه بمدير ملفات على التلفاز.';

  @override
  String get gTvAfterTitle => 'بعد التثبيت';

  @override
  String get gTvAfterBody =>
      'يجد تطبيق التلفاز الهاتف على الشبكة تلقائيًا؛ لا تحتاج إلى كتابة عنوان التلفاز على الهاتف. في Samsung لا يُحتاج إلى الحاسوب إلا للتثبيت؛ وبعدها يمكن إبقاؤه مغلقًا.';

  @override
  String get gTvObsTitle => 'للبثّ: OBS';

  @override
  String gTvObsBody(String phone) {
    return 'عند تفعيل الترجمة تُقدَّم الترجمات أيضًا كصفحة ويب. في OBS أضف \"مصدر متصفح\" واستخدم العنوان http://$phone:8787/obs (بمقاس 1920×1080). خلفية الصفحة شفافة؛ ولا تعرض الترجمة فوق اللعبة في متصفح التلفاز، بل هي لتخطيطات البث والتسجيل فقط.';
  }

  @override
  String get gFirstTitle => 'الاستخدام الأول';

  @override
  String get gFirstSubtitle => 'ابدأ الترجمة وشاهدها على التلفاز';

  @override
  String get gFirstStep1 =>
      'افتح اللعبة على PS5 بحسابك وشغّل الترجمات من إعدادات اللعبة.';

  @override
  String get gFirstStep2 =>
      'اضغط الزر الكبير في الشاشة الرئيسية للهاتف. في المرة الأولى يُطلب إذن الإشعارات؛ اسمح به لتستمر الترجمة في الخلفية.';

  @override
  String get gFirstStep3 =>
      'عندما تصبح الحالة \"الترجمة مفعّلة\" تظهر بطاقة PS5 \"متصل\". الاتصال الأول يستغرق بضع ثوانٍ.';

  @override
  String get gFirstStep4 =>
      'افتح تطبيق GameTranslator على التلفاز. خلال ثوانٍ تصبح بطاقة التلفاز على الهاتف \"متصل\".';

  @override
  String get gFirstStep5 =>
      'إن لم تظهر صورة اللعبة على التلفاز، افتح اللوحة بزر OK واختر بيمين ويسار مدخل HDMI الذي يتصل به PS5.';

  @override
  String get gFirstStep6 =>
      'إن لم يكن هناك صوت من التلفاز فقد وجّه PS5 الصوت إلى Remote Play: اضغط زر PS، وافتح الصوت › جهاز الإخراج من القائمة السفلية واختر HDMI. يتم هذا مرة واحدة.';

  @override
  String get gFirstStep7 =>
      'على الهاتف اضغط \"أرسل ترجمة تجريبية إلى التلفاز\". إن رأيت النص على التلفاز فكل شيء جاهز.';

  @override
  String get gFirstTip =>
      'يمكنك إطفاء شاشة الهاتف والترجمة مفعّلة. للإيقاف اضغط الزر في التطبيق أو \"إيقاف\" في الإشعار.';

  @override
  String get gFirstNextTitle => 'المرات القادمة';

  @override
  String get gFirstNextBody =>
      'خطوتان فقط: ابدأ الترجمة على الهاتف، وافتح GameTranslator على التلفاز.';

  @override
  String get gFirstBatteryTitle => 'البطارية والحرارة';

  @override
  String get gFirstBatteryBody =>
      'يفكّ الهاتف ترميز الفيديو ويقرأ النص باستمرار؛ في الجلسات الطويلة استخدمه موصولًا بالشاحن.';

  @override
  String get gRemoteTitle => 'ريموت التلفاز';

  @override
  String get gRemoteSubtitle => 'الأزرار في تطبيق التلفاز';

  @override
  String get gRemoteLead =>
      'عندما يكون GameTranslator مفتوحًا على التلفاز تفعل أزرار الريموت ما يلي:';

  @override
  String get gRemoteOk => 'OK';

  @override
  String get gRemoteOkText =>
      'يفتح لوحة الحالة ويغلقها (مدخل HDMI، حالة الاتصال).';

  @override
  String get gRemoteLeftRight => 'يسار / يمين';

  @override
  String get gRemoteLeftRightText =>
      'يغيّر مدخل HDMI عندما تكون اللوحة مفتوحة.';

  @override
  String get gRemoteNumbers => '1 – 4';

  @override
  String get gRemoteNumbersText => 'يختار مدخل HDMI مباشرة.';

  @override
  String get gRemoteUpDown => 'أعلى / أسفل';

  @override
  String get gRemoteUpDownText => 'يحرّك الترجمة أعلى أو أسفل الشاشة.';

  @override
  String get gRemoteRed => 'الأحمر';

  @override
  String get gRemoteRedText => 'يعرض نص الاختبار الخاص بالتلفاز.';

  @override
  String get gRemoteGreen => 'الأخضر';

  @override
  String get gRemoteGreenText => 'يفتح لوحة الحالة ويغلقها.';

  @override
  String get gRemoteBlue => 'الأزرق';

  @override
  String get gRemoteBlueText => 'يبدأ أو يوقف العرض التعريفي بترجمات نموذجية.';

  @override
  String get gRemoteBack => 'رجوع';

  @override
  String get gRemoteBackText => 'يخرج من التطبيق.';

  @override
  String get gRemoteTip =>
      'تلعب بذراع PS5؛ وريموت التلفاز مطلوب لهذه الإعدادات فقط.';

  @override
  String get gRegionTitle => 'اضبط منطقة الترجمة';

  @override
  String get gRegionSubtitle => 'أين ينظر الهاتف على الشاشة';

  @override
  String get gRegionBody =>
      'لا يقرأ الهاتف الشاشة كلها، بل منطقة ظهور الترجمة فقط. إن كانت المنطقة في المكان الخطأ فلا تأتي ترجمة، أو تُترجم نصوص أخرى على الشاشة.';

  @override
  String get gRegionStep1 => 'والترجمة مفعّلة، انتظر ظهور ترجمة في اللعبة.';

  @override
  String get gRegionStep2 =>
      'انظر إلى الإطار الأزرق في المعاينة على الشاشة الرئيسية: يجب أن تكون الترجمة كاملة داخل الإطار.';

  @override
  String get gRegionStep3 =>
      'إن لم تكن كذلك اضغط \"اضبط منطقة الترجمة\". اختر الحافة العليا أو السفلى أو اليسرى أو اليمنى وحرّكها بالمنزلق.';

  @override
  String get gRegionStep4 =>
      'سطر \"المقروء داخل الإطار\" في الشاشة الرئيسية يُظهر ما يقرأه الهاتف في تلك اللحظة؛ ويجب أن تظهر فيه الترجمة كاملة.';

  @override
  String get gRegionBullet1 => 'إذا قُطع بداية الجملة أو نهايتها فوسّع الإطار.';

  @override
  String get gRegionBullet2 =>
      'إذا اختفى السطر الأعلى في الترجمات ذات السطرين فارفع الحافة العليا.';

  @override
  String get gRegionBullet3 =>
      'إذا تُرجمت نصوص أخرى مثل أهداف المهام أو أسماء الخرائط فضيّق الإطار.';

  @override
  String get gRegionTip =>
      'كل لعبة تضع الترجمة في مكان مختلف؛ عند بدء لعبة جديدة تكفي نظرة واحدة على المنطقة.';

  @override
  String get gLookTitle => 'الترجمة والمظهر';

  @override
  String get gLookSubtitle => 'المحرك والقاموس والنص على التلفاز';

  @override
  String get gEngineTitle => 'محرك الترجمة';

  @override
  String get gEngineGoogle => 'Google';

  @override
  String get gEngineGoogleText =>
      'يحتاج إنترنت ولا يحتاج مفتاحًا. أفضل بداية لمعظم الألعاب.';

  @override
  String get gEngineDeepl => 'DeepL';

  @override
  String get gEngineDeeplText =>
      'يبني جملًا أكثر طبيعية. تحتاج إلى إدخال مفتاح API الخاص بك من DeepL.';

  @override
  String get gEngineOnDevice => 'على الجهاز';

  @override
  String get gEngineOnDeviceText =>
      'يعمل بلا إنترنت؛ جودته أقل من غيره. يُنزَّل نموذج اللغة مرة واحدة عند أول استخدام.';

  @override
  String get gEngineFallback =>
      'إذا انقطع الإنترنت تنتقل الترجمة تلقائيًا إلى نموذج الجهاز، وتعود عند رجوع الاتصال.';

  @override
  String get gGlossaryTitle => 'قاموس المصطلحات';

  @override
  String get gGlossaryBody =>
      'لتثبيت أسماء الشخصيات ومصطلحات اللعبة التي يخطئ فيها المترجم (من الإنجليزية إلى التركية فقط). يُفتح من الإعدادات › الترجمة › قاموس المصطلحات. تُترجم المصطلحات في \"terms\" إلى النص الذي تكتبه، وتبقى الأسماء في \"keep\" كما هي.';

  @override
  String get gLookOnTvTitle => 'المظهر على التلفاز';

  @override
  String get gLookOnTv1 => 'حجم الخط ولونه: الإعدادات › على التلفاز.';

  @override
  String get gLookOnTv2 =>
      'موضع الترجمة: تغطية ترجمة اللعبة، أو فوقها، أو تحتها، أو ثابت أسفل الشاشة.';

  @override
  String get gLookOnTv3 =>
      'عتامة الخلفية: مدى عتامة الصندوق الأسود خلف النص. أبقها عالية إن كنت تغطي ترجمة اللعبة.';

  @override
  String get gTroubleTitle => 'حل المشكلات';

  @override
  String get gTroubleSubtitle => 'حالات متكررة';

  @override
  String get gQ1 => 'الترجمة لا تبدأ وتبقى عند \"جارٍ الاتصال بـ PS5\"';

  @override
  String get gQ1A1 =>
      'هل PS5 مشغّل؟ إن كان في وضع السكون فشغّل الإيقاظ كما في فصل \"جهّز PS5\".';

  @override
  String get gQ1A2 => 'هل الهاتف متصل بـ Wi-Fi وعلى نفس شبكة PS5؟';

  @override
  String get gQ1A3 => 'هل Remote Play مفعّل على PS5؟';

  @override
  String get gQ2 => '\"Remote Play مستخدم من جهاز آخر\"';

  @override
  String get gQ2A1 =>
      'يقبل PS5 اتصال Remote Play واحدًا في الوقت نفسه. إن كان GameTranslator على حاسوب أو أي تطبيق Remote Play آخر مفتوحًا فأغلقه.';

  @override
  String get gQ2A2 =>
      'إن كنت أوقفتَه للتو فانتظر بضع ثوانٍ؛ يعيد التطبيق المحاولة تلقائيًا.';

  @override
  String get gQ3 => 'انفصل ذراع التحكم عن التلفاز';

  @override
  String get gQ3A1 =>
      'اتصل الهاتف بالحساب الذي تلعب به. انتقل إلى حساب المستخدم الثاني من الإعدادات › PS5 › \"غيّر حساب PSN\".';

  @override
  String get gQ4 => 'بطاقة التلفاز تبقى \"بانتظار\"';

  @override
  String get gQ4A1 => 'هل تطبيق GameTranslator مفتوح على التلفاز؟';

  @override
  String get gQ4A2 =>
      'هل التلفاز على نفس شبكة الهاتف؟ لا شبكة ضيوف ولا موجّه مختلف.';

  @override
  String get gQ4A3 =>
      'إن كان GameTranslator على حاسوب مفتوحًا فأغلقه؛ يتصل التلفاز بأول جهاز يجده.';

  @override
  String get gQ4A4 =>
      'إذا كان تطبيق التلفاز قد اتصل بحاسوب سابقًا فقد يعلق على ذلك العنوان. اتبع خطوات \"إذا لم يجد التلفاز الهاتف\" أدناه.';

  @override
  String get gTvNotFoundTitle => 'إذا لم يجد التلفاز الهاتف';

  @override
  String get gRecoveryLead =>
      'يتذكّر تطبيق التلفاز آخر عنوان اتصل به. فإن اتصل بحاسوب سابقًا فقد يستمر في تجربة ذلك العنوان بدل البحث عن الهاتف. ومسح العنوان المحفوظ يجعل التطبيق يفحص الشبكة من جديد ويجد الهاتف.';

  @override
  String get gRecoveryAndroidTitle =>
      'Android TV / Google TV (TCL، Sony، Philips، Vestel…)';

  @override
  String get gRecoveryAndroidStep1 =>
      'على التلفاز ادخل إلى الإعدادات › التطبيقات واختر GameTranslator من القائمة (قد تحتاج إلى \"إظهار كل التطبيقات\").';

  @override
  String get gRecoveryAndroidStep2 =>
      'اختر \"مسح البيانات\" وأكّد. لا يُحذف التطبيق؛ تُصفَّر فقط البيانات والعنوان المحفوظ والإعدادات.';

  @override
  String get gRecoveryAndroidStep3 =>
      'والترجمة مفعّلة، أعد فتح GameTranslator على التلفاز.';

  @override
  String get gRecoveryAndroidStep4 =>
      'انتظر حتى دقيقة؛ تصبح بطاقة التلفاز على الهاتف \"متصل\".';

  @override
  String get gRecoverySamsungTitle => 'Samsung وLG';

  @override
  String get gRecoverySamsungStep1 =>
      'في هذه التلفازات لا تُمسح بيانات التطبيق منفصلة: أزل GameTranslator من التلفاز.';

  @override
  String get gRecoverySamsungStep2 =>
      'أعد تثبيته بواسطة GameTranslator على حاسوب (خطوات فصل \"جهّز التلفاز\").';

  @override
  String get gRecoverySamsungStep3 =>
      'أغلق GameTranslator على الحاسوب، وابدأ الترجمة على الهاتف، وافتح التطبيق على التلفاز.';

  @override
  String get gRecoveryStillTitle => 'إن لم ينجح ذلك';

  @override
  String get gRecoveryStill1 =>
      'هل GameTranslator على الحاسوب مغلق؟ إن كان مفتوحًا فسيتصل التلفاز به.';

  @override
  String get gRecoveryStill2 =>
      'هل الهاتف والتلفاز على نفس شبكة Wi-Fi؟ إن كان \"عزل العملاء\" (AP isolation) مفعّلًا في الموجّه فلا ترى الأجهزة بعضها.';

  @override
  String get gRecoveryStill3 =>
      'إعداد HDMI على التلفاز يُصفَّر أيضًا، لذا اضغط OK لفتح اللوحة واختر مدخل PS5 من جديد.';

  @override
  String get gTroubleTip =>
      'إن واجهت مشكلة لم تحلّها، يمكنك نسخ السجلات من الإعدادات › حول › السجل ومشاركتها.';

  @override
  String get gQ5 => 'لا توجد صورة للعبة على التلفاز والشاشة سوداء';

  @override
  String get gQ5A1 =>
      'اضغط OK لفتح اللوحة واختر بيمين ويسار مدخل HDMI الذي يتصل به PS5.';

  @override
  String get gQ5A2 =>
      'بعض تلفازات Android لا تمنح صورة HDMI لتطبيق آخر؛ في تلك التلفازات تظهر الترجمة لكن الخلفية تبقى سوداء.';

  @override
  String get gQ6 => 'لا تأتي أي ترجمة';

  @override
  String get gQ6A1 => 'هل ترجمات اللعبة نفسها مفعّلة؟';

  @override
  String get gQ6A2 =>
      'إذا كان \"المقروء داخل الإطار\" فارغًا فالمنطقة في المكان الخطأ؛ راجع فصل \"اضبط منطقة الترجمة\".';

  @override
  String get gQ6A3 =>
      'هل لغة اللعبة مطابقة للغة المصدر في الإعدادات › الترجمة؟';

  @override
  String get gQ6A4 =>
      'إن كان \"أرسل ترجمة تجريبية إلى التلفاز\" يعمل فاتصال التلفاز سليم؛ والمشكلة في القراءة.';

  @override
  String get gQ7 => 'الترجمة ناقصة أو بلا معنى';

  @override
  String get gQ7A1 => 'إذا كان بداية الجملة أو نهايتها ناقصًا فوسّع المنطقة.';

  @override
  String get gQ7A2 =>
      'إن كان المحرك \"على الجهاز\" فانتقل إلى Google أو DeepL.';

  @override
  String get gQ7A3 =>
      'القراءة تصعب مع الخطوط المزخرفة جدًا أو الصغيرة جدًا؛ ويساعد تكبير حجم الترجمة في اللعبة وإضافة خلفية.';

  @override
  String get gQ8 => 'الترجمة تصل متأخرة';

  @override
  String get gQ8A1 =>
      'أبقِ الهاتف وPS5 قريبين من الموجّه إن أمكن؛ فWi-Fi الضعيف يؤخّر الصورة.';

  @override
  String get gQ8A2 => 'في المحركات عبر الإنترنت تؤثر سرعة الإنترنت أيضًا.';

  @override
  String get gQ9 => 'الترجمة تتوقف عند إطفاء الشاشة';

  @override
  String get gQ9A1 =>
      'قد يوقف موفّر البطارية التطبيق. من الهاتف ادخل إلى الإعدادات › التطبيقات › GameTranslator › البطارية واختر \"غير مقيّد\".';

  @override
  String get gQ9A2 =>
      'إن كنت أوقفت إذن الإشعارات فشغّله؛ فخدمة الخلفية تعمل بإشعار.';

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

  @override
  String get tvInstallTitle => 'تثبيت تطبيق التلفاز';

  @override
  String tvInstallStepLabel(int number) {
    return 'الخطوة $number من 4';
  }

  @override
  String get tvInstallBrandQuestion => 'ما ماركة تلفازك؟';

  @override
  String get tvInstallIntroBody =>
      'سنثبّت من الهاتف تطبيق GameTranslator الذي يعرض الترجمة على تلفازك. يجب أن يكون الهاتف والتلفاز على شبكة Wi-Fi نفسها.';

  @override
  String get tvInstallSavedHeader => 'تلفاز محفوظ';

  @override
  String tvInstallSavedSubtitle(String host, String version, String phone) {
    return '$host · على التلفاز $version · على الهاتف $phone';
  }

  @override
  String get tvInstallUpdateAvailable => 'يوجد تحديث';

  @override
  String get tvInstallUpdate => 'حدّث';

  @override
  String get tvInstallReinstall => 'أعد التثبيت';

  @override
  String get tvInstallBrandHeader => 'الماركة';

  @override
  String get tvInstallBrandAndroidSubtitle =>
      'TCL وSony وPhilips وXiaomi وVestel وArçelik وBeko وGrundig… تظهر على الشاشة الرئيسية كلمة Google Play أو \"Google TV\".';

  @override
  String get tvInstallBrandLgSubtitle =>
      'webOS. تظهر على الشاشة الرئيسية \"LG Content Store\" وبطاقات تطبيقات ملوّنة في الشريط السفلي.';

  @override
  String get tvInstallBrandSamsungSubtitle =>
      'Tizen، من 2019 وما بعدها. تظهر على الشاشة الرئيسية \"Samsung TV Plus\" و\"Smart Hub\".';

  @override
  String get tvInstallBrandFooter =>
      'لست متأكدًا؟ تعرض شاشة الإعدادات › الدعم (أو حول) على التلفاز الطراز ونظام التشغيل. لا تُدعم طرازات Vestel/Arçelik/Beko/Grundig بنظام Linux ولا Philips Saphi ولا Titan OS.';

  @override
  String get tvInstallSamsungStep => 'Samsung: التثبيت من الحاسوب';

  @override
  String get tvInstallSamsungNoticeTitle =>
      'التثبيت على تلفاز Samsung يحتاج حاسوبًا حاليًا';

  @override
  String get tvInstallSamsungNoticeText =>
      'تطلب Samsung توقيع التطبيق لكل تلفاز بحساب Samsung منفصل. التثبيت من الهاتف غير جاهز بعد؛ ويقوم به GameTranslator على الحاسوب تلقائيًا. يُثبَّت مرة واحدة ثم لا تحتاج إلى الحاسوب.';

  @override
  String get tvInstallSamsungStepsTitle => 'الخطوات باختصار';

  @override
  String get tvInstallSamsungStep1 =>
      'افتح شاشة التطبيقات على التلفاز واضغط 1 2 3 4 5 على الريموت.';

  @override
  String get tvInstallSamsungStep2 =>
      'اجعل \"Developer mode\" على \"On\"، واكتب عنوان الحاسوب في \"Host PC IP\"، ثم اضغط OK.';

  @override
  String get tvInstallSamsungStep3 =>
      'أطفئ التلفاز تمامًا ثم شغّله بالضغط المطوّل على زر الطاقة.';

  @override
  String get tvInstallSamsungStep4 =>
      'على الحاسوب اختر تلفاز Samsung في خطوة التلفاز داخل GameTranslator، ثم سجّل الدخول بحساب Samsung في الصفحة التي تُفتح.';

  @override
  String get tvInstallShowDetailed => 'اعرض التفاصيل في الدليل';

  @override
  String get tvInstallOtherBrand => 'اختر ماركة أخرى';

  @override
  String get tvInstallFindStep => 'ابحث عن تلفازك';

  @override
  String get tvInstallFindBodyAndroid =>
      'يجري البحث عن تلفازات Android المفعّل فيها تصحيح الأخطاء عبر الشبكة. إن لم تفعّله بعد فلن يظهر التلفاز هنا؛ لا مشكلة، تابع بـ \"اعرض الخطوات\".';

  @override
  String get tvInstallFindBodyLg =>
      'يجري البحث عن تلفازات LG على الشبكة نفسها التي عليها الهاتف. يجب أن يكون التلفاز مشتغلًا.';

  @override
  String get tvInstallSearchingHeader => 'يجري البحث…';

  @override
  String get tvInstallFoundHeader => 'التلفازات الموجودة';

  @override
  String get tvInstallScanning => 'يجري فحص الشبكة، يستغرق بضع ثوانٍ…';

  @override
  String get tvInstallNotFound => 'لم يُعثر على تلفاز';

  @override
  String get tvInstallNotSearched => 'لم يُبحث بعد';

  @override
  String get tvInstallNotSearchedNote => 'اضغط تحديث أو اكتب العنوان يدويًا.';

  @override
  String get tvInstallReady => 'جاهز';

  @override
  String get tvInstallRefresh => 'تحديث';

  @override
  String get tvInstallManualHeader => 'اكتب العنوان يدويًا';

  @override
  String get tvInstallIpHint => 'مثال 192.168.1.40';

  @override
  String get tvInstallUseAddress => 'استخدم هذا العنوان';

  @override
  String get tvInstallAddressFooterAndroid =>
      'عنوان التلفاز: الإعدادات › الشبكة والإنترنت › اسم شبكة Wi-Fi المتصلة (Google TV: الإعدادات › الشبكة والإنترنت).';

  @override
  String get tvInstallAddressFooterLg =>
      'عنوان التلفاز: الإعدادات › عام › الشبكة › اتصال Wi-Fi › إعدادات Wi-Fi المتقدمة (وفي بعض الطرازات الإعدادات › الشبكة).';

  @override
  String tvInstallSameSubnet(String phone) {
    return 'عنوان الهاتف $phone؛ ويجب أن يتفق عنوان التلفاز معه في الأجزاء الثلاثة الأولى.';
  }

  @override
  String get tvInstallShowSteps => 'اعرض الخطوات';

  @override
  String get tvInstallIpError => 'هذا لا يشبه عنوان IP. مثال: 192.168.1.40';

  @override
  String get tvInstallDebugStep => 'فعّل تصحيح الأخطاء';

  @override
  String get tvInstallDevModeStep => 'فعّل وضع المطوّر';

  @override
  String tvInstallStepCounter(int index, int total) {
    return 'الخطوة $index من $total';
  }

  @override
  String get tvInstallCopy => 'نسخ';

  @override
  String get tvInstallCopied => 'نُسخ العنوان.';

  @override
  String get tvInstallKeyServerOn => 'خادم المفاتيح مفعّل. يمكنك المتابعة.';

  @override
  String get tvInstallDeviceReady => 'التلفاز جاهز. يمكنك المتابعة.';

  @override
  String get tvInstallSearchingTv => 'يجري البحث عن التلفاز في الشبكة…';

  @override
  String tvInstallWaitingTv(String host) {
    return 'بانتظار التلفاز ($host)…';
  }

  @override
  String get tvInstallDifferentMenu => 'إذا ظهرت القائمة بشكل مختلف';

  @override
  String get tvInstallDidIt => 'فعلت هذا';

  @override
  String get tvInstallGoInstall => 'انتقل إلى التثبيت';

  @override
  String get tvInstallWaitingFooter =>
      'بانتظار ظهور التلفاز في الشبكة. إن لم يظهر فارجع واكتب عنوان التلفاز يدويًا.';

  @override
  String get tvInstallInstallStep => 'الثبيت';

  @override
  String get tvInstallVersionToInstall => 'الإصدار المطلوب تثبيته';

  @override
  String get tvInstallPassHeader => 'كلمة المرور على شاشة التلفاز';

  @override
  String get tvInstallPassHint => 'مثال 2FEEB2';

  @override
  String get tvInstallPassFooter =>
      'هي الأحرف الستة الظاهرة باسم \"Passphrase\" أسفل يسار الشاشة عندما يكون خادم المفاتيح مفعّلًا في تطبيق Developer Mode. تُطلب في هذا التثبيت الأول فقط.';

  @override
  String get tvInstallApproveTitle => 'سيظهر سؤال على التلفاز';

  @override
  String get tvInstallApproveText =>
      'عند سؤال \"هل تسمح بتصحيح أخطاء USB؟\" علّم \"السماح دائمًا من هذا الحاسوب\" واختر \"السماح\". يظهر السؤال في التثبيت الأول فقط.';

  @override
  String get tvInstallLookAtTvTitle => 'انظر الآن إلى التلفاز';

  @override
  String get tvInstallLookAtTvText =>
      'يسأل التلفاز \"هل تسمح بتصحيح أخطاء USB؟\". علّم \"السماح دائمًا من هذا الحاسوب\" واختر \"السماح\". ثم يستمر التثبيت وحده.';

  @override
  String get tvInstallKeepScreenOn =>
      'أبقِ شاشة الهاتف مفتوحة. يستغرق التثبيت عادة أقل من دقيقة.';

  @override
  String get tvInstallTvSaid => 'ما قاله التلفاز';

  @override
  String get tvInstallStop => 'إيقاف';

  @override
  String get tvInstallInstallButton => 'ثبّت على التلفاز';

  @override
  String get tvInstallRetry => 'أعد المحاولة';

  @override
  String get tvInstallBackToSteps => 'رجوع إلى الخطوات';

  @override
  String get tvInstallInstalled => 'تم تثبيت تطبيق التلفاز';

  @override
  String get tvInstallAlreadyCurrent => 'تطبيق التلفاز محدّث بالفعل';

  @override
  String tvInstallVersionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String get tvInstallLaunchedTitle => 'فُتح GameTranslator على التلفاز';

  @override
  String get tvInstallOpenOnTvTitle => 'افتح GameTranslator على التلفاز';

  @override
  String get tvInstallLaunchedText =>
      'عند بدء الترجمة على الهاتف يجد تطبيق التلفاز الهاتف في الشبكة بنفسه.';

  @override
  String get tvInstallOpenOnTvText =>
      'ابحث عن GameTranslator في قائمة تطبيقات التلفاز وافتحه. يجد الهاتف بنفسه عند بدء الترجمة.';

  @override
  String get tvInstallLgHoursTitle => 'مدة وضع المطوّر في LG';

  @override
  String tvInstallHoursLeft(int hours) {
    return 'المدة المتبقية: $hours ساعة.';
  }

  @override
  String get tvInstallLgHoursText =>
      'إن انتهت المدة يُحذف تطبيق التلفاز. إن كنت لن تستخدمه مدة طويلة فاضغط \"EXTEND\" في تطبيق Developer Mode على التلفاز؛ وإعادة التثبيت من هذه الصفحة تطيل المدة أيضًا.';

  @override
  String get tvInstallAndroidNote =>
      'يمكنك الآن إن أردت إيقاف تصحيح أخطاء USB على التلفاز. وستحتاج إلى تفعيله مرة أخرى لتثبيت إصدار جديد.';

  @override
  String get tvInstallDone => 'تم';

  @override
  String get tvInstallBrandFallback => 'تلفاز';

  @override
  String get tvGuideA1Title => 'افتح الإعدادات على التلفاز';

  @override
  String get tvGuideA1Body =>
      'اضغط زر الترس (الإعدادات) على ريموت التلفاز. وإن لم يكن في الريموت فاختر أيقونة الترس أعلى يمين الشاشة الرئيسية.';

  @override
  String get tvGuideA1Different =>
      'في Google TV (طرازات Sony وTCL وPhilips وXiaomi الحديثة) اختر صورة الحساب أو الترس أعلى اليمين، ثم ادخل \"الإعدادات\".';

  @override
  String get tvGuideA2Title => 'ادخل شاشة \"حول\"';

  @override
  String get tvGuideA2Body =>
      'Android TV: الإعدادات › تفضيلات الجهاز › حول.\nGoogle TV: الإعدادات › النظام › حول.';

  @override
  String get tvGuideA2Different =>
      'Philips: الإعدادات › إعدادات Android › تفضيلات الجهاز › حول.\nSony: الإعدادات › النظام › حول (وفي الطرازات القديمة تفضيلات الجهاز › حول).\nTCL وXiaomi: الإعدادات › النظام › حول أو تفضيلات الجهاز › حول.\nوإن لم تجده فاكتب \"حول\" في بحث الإعدادات إن وُجد.';

  @override
  String get tvGuideA3Title => 'اضغط سطر الإصدار 7 مرات';

  @override
  String get tvGuideA3Body =>
      'اختر سطر \"إصدار نظام Android TV OS\" أسفل القائمة واضغط زر OK في الريموت 7 مرات متتالية. ستظهر رسالة \"أنت الآن مطوّر\".';

  @override
  String get tvGuideA3Different =>
      'قد يكون اسم السطر \"رقم الإصدار\" أو \"حزمة البناء\" أو \"Build\" حسب الطراز. وإن طلب التلفاز رمز PIN فأدخل رمز قفل التلفاز. وإن ظهر \"أنت مطوّر بالفعل\" فقد تمّت هذه الخطوة.';

  @override
  String get tvGuideA4Title => 'افتح خيارات المطوّر';

  @override
  String get tvGuideA4Body =>
      'ارجع شاشة واحدة بزر الرجوع. سيظهر سطر جديد باسم \"خيارات المطوّر\" تحت تفضيلات الجهاز في Android TV وتحت النظام في Google TV؛ ادخله.';

  @override
  String get tvGuideA4Different =>
      'إن لم ترَ السطر فاخرج من الإعدادات تمامًا ثم ادخل من جديد. وإن بقي غير موجود فأعد الضغط 7 مرات في الخطوة السابقة.';

  @override
  String get tvGuideA5Title => 'فعّل \"تصحيح أخطاء USB\"';

  @override
  String get tvGuideA5Body =>
      'ابحث عن \"تصحيح أخطاء USB\" في قائمة خيارات المطوّر وفعّله؛ واختر \"موافق\" في التحذير. وإن وُجد في القائمة \"تصحيح الأخطاء عبر الشبكة\" أو \"ADB عبر الشبكة\" ففعّله أيضًا.\n\nعند تشغيل التلفاز يتحوّل هذا إلى الأخضر تلقائيًا.';

  @override
  String get tvGuideA5Different =>
      'قد يكون اسم الخيار \"تصحيح الأخطاء (ADB)\" أو \"USB debugging\". الطرازات التي لا تتيح إلا \"التصحيح اللاسلكي\" وتطلب رمز اقتران (مثل Google TV Streamer) لا يمكن التثبيت عليها من الهاتف بعد؛ استخدم فيها طريق فلاش USB المذكور في الدليل.';

  @override
  String get tvGuideL1Title => 'أنشئ حساب مطوّر LG مجانيًا';

  @override
  String get tvGuideL1Body =>
      'افتح العنوان أدناه في متصفح الهاتف، ثم اختر \"SIGN IN\" أعلى اليمين، وبعدها \"Create Account\" لإنشاء حساب مجاني. وستكتب بريدك وكلمة مرورك على التلفاز في الخطوة التالية.';

  @override
  String get tvGuideL1Different =>
      'إن كان لديك حساب LG (مثل LG ThinQ) فيمكنك الدخول بالبريد وكلمة المرور نفسيهما؛ وتجاوز هذه الخطوة.';

  @override
  String get tvGuideL2Title => 'ثبّت تطبيق \"Developer Mode\" على التلفاز';

  @override
  String get tvGuideL2Body =>
      'افتح LG Content Store (التطبيقات) على التلفاز، واكتب \"Developer Mode\" في مربع البحث، وثبّت التطبيق.';

  @override
  String get tvGuideL2Different =>
      'إن لم يُفتح المتجر فتأكد من اتصال التلفاز بالإنترنت. وفي الطرازات القديمة يكون اسم المتجر \"LG Store\" أو \"التطبيقات\". يظهر التطبيق بالإنجليزية.';

  @override
  String get tvGuideL3Title => 'سجّل الدخول وفعّل \"Dev Mode Status\"';

  @override
  String get tvGuideL3Body =>
      'افتح تطبيق Developer Mode وسجّل الدخول ببريد حساب LG وكلمة مروره. ثم فعّل مفتاح \"Dev Mode Status\". يعيد التلفاز التشغيل بنفسه؛ فانتظر حتى يعود.\n\nعند تفعيل وضع المطوّر يتحوّل هذا إلى الأخضر تلقائيًا.';

  @override
  String get tvGuideL3Different =>
      'إن كان \"Dev Mode Status\" رماديًا وغير قابل للاختيار فلم تسجّل الدخول بعد. وإن قال الدخول \"Login failed\" فتأكد من توثيق بريد حسابك.';

  @override
  String get tvGuideL4Title => 'فعّل \"Key Server\"';

  @override
  String get tvGuideL4Body =>
      'بعد عودة التلفاز للعمل افتح تطبيق Developer Mode مرة أخرى وفعّل مفتاح \"Key Server\". واترك التطبيق على الشاشة؛ فإن أغلقته يُغلق خادم المفاتيح أيضًا.\n\nعند تفعيل خادم المفاتيح يتحوّل هذا إلى الأخضر تلقائيًا.';

  @override
  String get tvGuideL4Different =>
      'تظهر أسفل يسار الشاشة كلمة \"Passphrase\" من 6 أحرف؛ وستكتبها في الخطوة التالية.';

  @override
  String get tvErrUnreachableAndroidTitle => 'التلفاز لم يستجب';

  @override
  String get tvErrUnreachableAndroidFix =>
      'هل التلفاز مشتغل وعلى شبكة Wi-Fi نفسها التي عليها الهاتف؟ يجب أن يكون \"تصحيح أخطاء USB\" مفعّلًا في خيارات المطوّر. وفي بعض التلفازات يُطفأ هذا الإعداد عند إعادة التشغيل؛ ففعّله وأعد المحاولة.';

  @override
  String get tvErrUnreachableLgTitle => 'التلفاز لم يستجب';

  @override
  String get tvErrUnreachableLgFix =>
      'هل التلفاز مشتغل وعلى شبكة Wi-Fi نفسها التي عليها الهاتف؟ يجب أن يكون \"Dev Mode Status\" مفعّلًا في تطبيق Developer Mode؛ وبعد تفعيله يعيد التلفاز التشغيل، فانتظر حتى يعود.';

  @override
  String get tvErrKeyServerOffTitle => 'خادم المفاتيح مغلق';

  @override
  String get tvErrKeyServerOffFix =>
      'افتح تطبيق Developer Mode على التلفاز، وفعّل \"Key Server\"، واترك التطبيق على الشاشة. ثم أعد المحاولة.';

  @override
  String get tvErrWrongPassphraseTitle => 'كلمة المرور غير صحيحة';

  @override
  String get tvErrWrongPassphraseFix =>
      'اكتب مرة أخرى الأحرف الستة الظاهرة باسم \"Passphrase\" أسفل يسار تطبيق Developer Mode على شاشة التلفاز. قد يلتبس 0 (صفر) بحرف O، و1 بحرف I.';

  @override
  String get tvErrKeyRefusedTitle => 'التلفاز رفض المفتاح';

  @override
  String get tvErrKeyRefusedFix =>
      'إن أُغلق وضع المطوّر ثم فُتح فسيُنشئ التلفاز مفتاحًا جديدًا. فعّل خادم المفاتيح واكتب كلمة المرور من جديد.';

  @override
  String get tvErrNotApprovedTitle => 'لم يُسمح على التلفاز';

  @override
  String get tvErrNotApprovedFix =>
      'أعد المحاولة. وعند ظهور سؤال \"هل تسمح بتصحيح أخطاء USB؟\" على التلفاز علّم \"السماح دائمًا من هذا الحاسوب\" واختر \"السماح\". ينتظر السؤال على شاشة التلفاز نحو دقيقة ونصف.';

  @override
  String get tvErrNoSpaceTitle => 'لا توجد مساحة على التلفاز';

  @override
  String get tvErrNoSpaceFix =>
      'احذف من التلفاز تطبيقًا لا تستخدمه وأعد المحاولة.';

  @override
  String get tvErrConnectionLostTitle => 'انقطع الاتصال';

  @override
  String get tvErrConnectionLostFix =>
      'انقطع الاتصال بالتلفاز أثناء التثبيت. أبقِ شاشة الهاتف مفتوحة ومتصلة بـ Wi-Fi؛ وأعد المحاولة.';

  @override
  String get tvErrTooOldTitle => 'هذا التلفاز قديم جدًا';

  @override
  String get tvErrTooOldFix =>
      'تطبيق GameTranslator للتلفاز لا يعمل على برنامج هذا التلفاز.';

  @override
  String get tvErrPackageMissingTitle => 'حزمة التلفاز غير موجودة';

  @override
  String get tvErrPackageMissingFix =>
      'حزمة التلفاز غير مضمنة في تطبيق الهاتف هذا. ثبّت أحدث إصدار من التطبيق.';

  @override
  String get tvErrCancelledTitle => 'أُوقف التثبيت';

  @override
  String get tvErrCancelledFix => 'يمكنك بدؤه من جديد عندما تكون جاهزًا.';

  @override
  String get tvErrGenericTitle => 'لم يتم تثبيت تطبيق التلفاز';

  @override
  String get tvErrGenericFix =>
      'أعد المحاولة. وإعادة تشغيل التلفاز تصلح معظم عمليات التثبيت الناقصة. وإن استمرت المشكلة فأبلغنا مع نص \"ما قاله التلفاز\" أدناه.';

  @override
  String tvStageUploading(String percent) {
    return 'يجري إرسال التطبيق إلى التلفاز… %$percent';
  }

  @override
  String get tvStageConnecting => 'يجري الاتصال بالتلفاز…';

  @override
  String get tvStageApprove => 'بانتظار السماح على التلفاز…';

  @override
  String get tvStageChecking => 'يجري التحقق من الإصدار على التلفاز…';

  @override
  String get tvStageKey => 'يجري الحصول على مفتاح من التلفاز…';

  @override
  String get tvStageInstalling => 'يجري التثبيت على التلفاز…';

  @override
  String get tvStageVerifying => 'يجري التحقق من التثبيت…';

  @override
  String get tvStageLaunching => 'يجري الفتح على التلفاز…';

  @override
  String get tvStagePreparing => 'يجري التحضير…';

  @override
  String psnErrAuth(int status, String detail) {
    return 'رفضت Sony تسجيل الدخول (HTTP $status)$detail';
  }

  @override
  String psnErrAccount(int status) {
    return 'تعذّر الحصول على معرّف الحساب (HTTP $status)';
  }

  @override
  String psnErrNetwork(String error) {
    return 'تعذّر الوصول إلى Sony: $error';
  }

  @override
  String get commonBack => 'رجوع';
}
