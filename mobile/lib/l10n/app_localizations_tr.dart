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
}
