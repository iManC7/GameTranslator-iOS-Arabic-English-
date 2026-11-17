// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GameTranslator';

  @override
  String get tabTranslate => 'Translate';

  @override
  String get tabGuide => 'Guide';

  @override
  String get tabSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupApp => 'APP';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAppLanguageNote =>
      'Interface language only; does not change the game or translation language.';
}
