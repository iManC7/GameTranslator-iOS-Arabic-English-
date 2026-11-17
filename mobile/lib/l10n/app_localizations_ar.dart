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
}
