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

  @override
  String get devicePs5 => 'PS5';

  @override
  String get devicePhone => 'Phone';

  @override
  String get deviceTv => 'TV';

  @override
  String get introSkip => 'Skip';

  @override
  String get introClose => 'Close';

  @override
  String get introContinue => 'Continue';

  @override
  String get introDone => 'Done';

  @override
  String get introStartSetup => 'Start setup';

  @override
  String get introWelcomeTitle => 'Play the game in your own language';

  @override
  String get introWelcomeBody =>
      'Translates PS5 game subtitles on the fly and shows them on your TV.';

  @override
  String get introHowTitle => 'Your phone is the translator in between';

  @override
  String get introHowBody =>
      'The phone takes the game picture from the PS5 over Remote Play, reads the subtitle, translates it and sends it to the TV. No camera, and it keeps working even with the screen off.';

  @override
  String get introFlowVideo => 'Video';

  @override
  String get introFlowPhone => 'Phone';

  @override
  String get introFlowTranslates => 'Translates';

  @override
  String get introFlowShows => 'Shows';

  @override
  String get introSampleOriginal => 'We have to leave before sunrise.';

  @override
  String get introSampleTranslation => 'We have to leave before sunrise.';

  @override
  String get introNeedsTitle => 'Before you start';

  @override
  String get introNeedsBody => 'Setup takes a few minutes. Have these ready:';

  @override
  String get introNeedSecondUserTitle => 'A second user on the PS5';

  @override
  String get introNeedSecondUserText =>
      'You play on your own account; the phone signs in with the second one, so your controller is not detached from the TV.';

  @override
  String get introNeedTvAppTitle => 'The GameTranslator app on your TV';

  @override
  String get introNeedTvAppText =>
      'Works on Samsung, LG and Android TV. Installing on the TV is done from GameTranslator on a computer.';

  @override
  String get introNeedWifiTitle => 'The same Wi-Fi network';

  @override
  String get introNeedWifiText =>
      'Phone, PS5 and TV must be on the same home network.';

  @override
  String get homeStateStreamingTitle => 'Translation on';

  @override
  String get homeStateStreamingHint =>
      'You can turn the screen off; translation continues in the background.';

  @override
  String get homeStateStartingTitle => 'Starting…';

  @override
  String get homeStateStartingHint => 'Takes a few seconds.';

  @override
  String get homeStateConnectingTitle => 'Connecting to the PS5…';

  @override
  String get homeStateConnectingHint =>
      'The PS5 must be on and on the same Wi-Fi.';

  @override
  String get homeStateWakingTitle => 'Waking the PS5…';

  @override
  String get homeStateWakingHint =>
      'Coming out of rest mode can take up to a minute.';

  @override
  String get homeStateReconnectingTitle => 'Reconnecting…';

  @override
  String get homeStateReconnectingHint => 'The connection dropped; retrying.';

  @override
  String get homeStateStoppingTitle => 'Stopping…';

  @override
  String get homeStateFailedTitle => 'Could not start';

  @override
  String get homeStateFailedHint => 'Tap to try again.';

  @override
  String get homeStateIdleTitle => 'Translation off';

  @override
  String get homeStateIdleHint => 'Tap to start.';

  @override
  String get homeNodeConnected => 'Connected';

  @override
  String get homeNodeWaking => 'Waking';

  @override
  String get homeNodeConnecting => 'Connecting';

  @override
  String get homeNodePaired => 'Paired';

  @override
  String get homeNodeNoWifi => 'No Wi-Fi';

  @override
  String get homeNodeTranslating => 'Translating';

  @override
  String get homeNodeReady => 'Ready';

  @override
  String get homeNodeWaiting => 'Waiting';

  @override
  String get homeNodeNotConnected => 'Not connected';

  @override
  String get homeTestSentToast => 'Test subtitle sent to the TV.';

  @override
  String get homeTestNoTvToast =>
      'No TV connected. Open GameTranslator on the TV first.';

  @override
  String get homeUnsupportedTitle => 'This phone is not supported';

  @override
  String get homeUnsupportedText =>
      'The Remote Play library could not be loaded on this device.';

  @override
  String get homeNoWifiTitle => 'No Wi-Fi connection';

  @override
  String get homeNoWifiText =>
      'The phone must be on the same Wi-Fi network as the PS5 and the TV.';

  @override
  String get homeOpenTvTitle => 'Open GameTranslator on your TV';

  @override
  String get homeOpenTvText =>
      'The TV app finds the phone on the network by itself; after you open it, connecting takes a few seconds.';

  @override
  String get homeTvStuckTitle => 'The TV still has not connected';

  @override
  String get homeTvStuckText =>
      'If the TV app was connected to a computer before, it may be stuck on the old address. Clearing the app\'s data on the TV once fixes this.';

  @override
  String get homeTvStuckAction => 'Show me step by step';

  @override
  String get homeLiveGroup => 'LIVE';

  @override
  String get homeSendTest => 'Send a test subtitle to the TV';

  @override
  String get homeAdjustRegion => 'Adjust the subtitle region';

  @override
  String get homeHowGroup => 'HOW TO USE';

  @override
  String get homeHowStep1 => 'Turn on subtitles in the game.';

  @override
  String get homeHowStep2 => 'Start translation with the button above.';

  @override
  String get homeHowStep3 =>
      'Open GameTranslator on the TV; the translation appears over the game.';

  @override
  String get homeInstallTvTitle => 'Install the TV app';

  @override
  String get homeInstallTvSubtitle => 'If your TV does not have GameTranslator';

  @override
  String get homeDetailedGuide => 'Detailed guide';

  @override
  String get homeStartTranslation => 'Start translation';

  @override
  String get homeStopTranslation => 'Stop translation';

  @override
  String get homePreviewPreparing => 'Preparing the preview…';

  @override
  String get homeAwaitingPs5 => 'Waiting for the PS5 picture…';

  @override
  String get homeLastTranslation => 'Last translation';

  @override
  String get homeWaitingSubtitle =>
      'When a subtitle appears in the game, its translation shows here and on the TV.';

  @override
  String get homeRegionReadLabel => 'READ IN THE FRAME';

  @override
  String get homeNothingRead => 'No text right now.';

  @override
  String get settingsGroupTranslate => 'TRANSLATION';

  @override
  String get settingsSourceLanguage => 'Game language';

  @override
  String get settingsTargetLanguage => 'Translation language';

  @override
  String get settingsGlossary => 'Glossary';

  @override
  String get settingsGlossaryEmpty => 'Empty';

  @override
  String get settingsGlossaryInvalid => 'Invalid';

  @override
  String settingsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terms',
      one: '$count term',
      zero: '0 terms',
    );
    return '$_temp0';
  }

  @override
  String get settingsPacks => 'Game packs';

  @override
  String get settingsPacksNote =>
      'GTA V, RDR2, Elden Ring… lines with ready translations';

  @override
  String get settingsGame => 'Game';

  @override
  String get settingsGameAuto => 'Automatic';

  @override
  String get settingsGameAutoOption => 'Automatic (detects the game)';

  @override
  String settingsGameOptionLine(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '$count line',
      zero: '0 lines',
    );
    return '$title · $_temp0';
  }

  @override
  String get settingsPatches => 'Update community patches';

  @override
  String get settingsPatchesBusy => 'Checking patches…';

  @override
  String get settingsPatchesNote =>
      'Downloads new and updated game patches (weekly, automatically)';

  @override
  String get settingsHideButtonHints => 'Hide button hints';

  @override
  String get settingsHideButtonHintsNote =>
      'Button labels like \"SKIP\" or \"RESUME\" next to the subtitle are not translated';

  @override
  String get settingsPacksFooter =>
      'Lines included in the game pack are shown from the pack without calling the translation engine. Packs come from the CouchSubs community and are refreshed weekly.';

  @override
  String get settingsGroupEngine => 'TRANSLATION ENGINE';

  @override
  String get settingsEngineGoogleNote =>
      'Needs internet, no key required. Recommended for most games.';

  @override
  String get settingsEngineDeeplNote =>
      'More natural sentences; works with your own DeepL API key.';

  @override
  String get settingsDeeplKeyHint => 'DeepL API key';

  @override
  String get settingsEngineGeminiNote =>
      'The most natural phrasing with AI. Works with a free key; when the limit is reached, Google is used for a minute.';

  @override
  String get settingsGeminiKeyHint => 'Gemini API key';

  @override
  String get settingsGeminiChecking => 'Testing…';

  @override
  String get settingsGeminiSaveTest => 'Save and test';

  @override
  String get settingsGeminiGetKey => 'Get a free Google Gemini API key';

  @override
  String get settingsEngineOnDevice => 'On device';

  @override
  String get settingsEngineOnDeviceIosNote =>
      'Works offline (Apple Translate). First download English and Turkish in iPhone Settings › Apps › Translate › Downloaded Languages.';

  @override
  String get settingsEngineOnDeviceAndroidNote =>
      'Works offline; quality is lower. The language model downloads once.';

  @override
  String get settingsEngineFooter =>
      'If the internet drops, translation switches to the on-device model by itself. If the DeepL key is empty or does not work, Google is used.';

  @override
  String get settingsGroupRegion => 'SUBTITLE REGION';

  @override
  String get settingsEdgeTop => 'Top';

  @override
  String get settingsEdgeBottom => 'Bottom';

  @override
  String get settingsEdgeLeft => 'Left';

  @override
  String get settingsEdgeRight => 'Right';

  @override
  String get settingsResetDefault => 'Reset to Default';

  @override
  String get settingsRegionFooter =>
      'Move the blue frame to where the game\'s subtitles appear. If the frame is too tight, the start or end of the sentence is cut off.';

  @override
  String get settingsGroupTvLook => 'ON TV';

  @override
  String get settingsFontSize => 'Font size';

  @override
  String get settingsFontSmall => 'Small';

  @override
  String get settingsFontMedium => 'Medium';

  @override
  String get settingsFontLarge => 'Large';

  @override
  String get settingsFontHuge => 'Huge';

  @override
  String get settingsTextColor => 'Text color';

  @override
  String get settingsWhite => 'White';

  @override
  String get settingsYellow => 'Yellow';

  @override
  String get settingsPlacement => 'Subtitle position';

  @override
  String get settingsPlacementCover => 'Covering the game subtitle';

  @override
  String get settingsPlacementAbove => 'Above the game subtitle';

  @override
  String get settingsPlacementBelow => 'Below the game subtitle';

  @override
  String get settingsPlacementFixed => 'Fixed at the bottom';

  @override
  String get settingsBackground => 'Background darkness';

  @override
  String get settingsBold => 'Bold text';

  @override
  String get settingsSpeakerColor => 'Colored speaker name';

  @override
  String get settingsSpeakerColorNote =>
      'The speaker\'s name (e.g. ENZO:) in yellow, light blue on yellow text';

  @override
  String get settingsSendTest => 'Send a Test Subtitle to the TV';

  @override
  String get settingsTestSent => 'Test subtitle sent.';

  @override
  String get settingsGroupTvApp => 'TV APP';

  @override
  String get settingsInstallTv => 'Install the TV App';

  @override
  String get settingsInstallTvNote =>
      'To LG and Android TV from the phone; also for updating';

  @override
  String get settingsPaired => 'Paired';

  @override
  String get settingsAutoWake => 'Wake from rest mode';

  @override
  String get settingsAutoWakeFooter =>
      'If the PS5 is in rest mode when translation starts, it is woken up.';

  @override
  String get settingsRepair => 'Re-pair the PS5';

  @override
  String get settingsChangeAccount => 'Change the PSN Account';

  @override
  String get settingsGroupAbout => 'ABOUT';

  @override
  String get settingsShowIntro => 'Show the Intro';

  @override
  String get settingsLogs => 'Log';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsAboutFooter =>
      'Your game picture and account details stay on the phone. If an online engine is selected, only the subtitle text that was read is sent to the translation service.\n\nGameTranslator is open source (AGPL-3.0). Not affiliated with Sony or PlayStation.';

  @override
  String get settingsForgetTitleAccount => 'Change the PSN account?';

  @override
  String get settingsForgetTitleConsole => 'Re-pair the PS5?';

  @override
  String get settingsForgetMessageAccount =>
      'The saved account and PS5 pairing are deleted; you will set up again from scratch.';

  @override
  String get settingsForgetMessageConsole =>
      'The saved pairing is deleted; you re-pair with the \"Link Device\" code on the PS5.';

  @override
  String get settingsForgetAction => 'Delete and Continue';

  @override
  String get settingsLogsEmpty => 'No log entries yet.';

  @override
  String get settingsLogTitle => 'Log';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsLogCopied => 'Log copied.';

  @override
  String get settingsLogNote =>
      'When something goes wrong you can share these records with support.';

  @override
  String get settingsRegionPreviewNote =>
      'The game picture appears here while translation is on.';

  @override
  String get settingsGlossaryTitle => 'Glossary';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsGlossaryHelp =>
      'Pin proper names and game terms here when the translation gets them wrong. Terms in \"terms\" are translated to the text you write; names in \"keep\" stay as they are.';

  @override
  String get settingsGlossaryEmptyNote =>
      'The glossary is empty. You can start from an example and replace it with your own terms.';

  @override
  String get settingsGlossaryAddExample => 'Add Example';

  @override
  String settingsGlossaryRead(int terms, int keep) {
    return '$terms terms and $keep kept names read.';
  }

  @override
  String get settingsGlossaryFooter =>
      'Same format as the GameTranslator glossary files on a computer; you can paste a file\'s contents here. Only used for English → Turkish translation.';

  @override
  String get settingsGlossaryErrorShape =>
      'The glossary must be a JSON object in curly braces.';

  @override
  String get settingsGlossaryErrorSyntax =>
      'There is a syntax error: check quotes, commas and braces.';

  @override
  String homeLinesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '$count line',
      zero: '0 lines',
    );
    return '$_temp0';
  }

  @override
  String homePackUsage(String game, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '$count line',
      zero: '0 lines',
    );
    return '$game pack in use · $_temp0 from the pack';
  }
}
