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
  String get guideIntro =>
      'Everything from setup to troubleshooting, step by step.';

  @override
  String get guidePhoneAddress => 'your phone\'s address';

  @override
  String get guideGroupStart => 'GETTING STARTED';

  @override
  String get guideGroupUsage => 'USAGE';

  @override
  String get guideGroupHelp => 'HELP';

  @override
  String get guideNextChapter => 'NEXT CHAPTER';

  @override
  String get guideTvHelpTitle => 'TV Will Not Connect';

  @override
  String get gHowTitle => 'How it works';

  @override
  String get gHowSubtitle => 'The whole setup at a glance';

  @override
  String get gHowLead =>
      'GameTranslator links three devices. The game runs on the PS5, you play on the TV, and the phone translates in between:';

  @override
  String get gHowStep1 =>
      'The phone takes the game picture from the PS5 over Remote Play. No camera is used.';

  @override
  String get gHowStep2 =>
      'It reads the area of the picture where the subtitles appear and translates the text.';

  @override
  String get gHowStep3 =>
      'It sends the translation to the TV on the same Wi-Fi. The GameTranslator app on the TV shows it over the game.';

  @override
  String get gHowNeedsTitle => 'What you need';

  @override
  String get gHowNeed1 => 'A PS5 with a second user on it (explained below).';

  @override
  String get gHowNeed2 =>
      'A TV with the GameTranslator TV app installed: LG, Samsung or Android TV / Google TV.';

  @override
  String get gHowNeed3 =>
      'One home network (Wi-Fi) that the phone, the PS5 and the TV are all connected to.';

  @override
  String get gHowNeed4 =>
      'Internet for online translation. There is also an offline translation option.';

  @override
  String get gHowTip =>
      'Setup is done once. After that you only start translation and open the app on the TV.';

  @override
  String get gPs5Title => 'Prepare the PS5';

  @override
  String get gPs5Subtitle => 'A second user and Remote Play';

  @override
  String get gPs5UserTitle => '1. Add a second user';

  @override
  String get gPs5UserBody =>
      'The PS5 treats the device that connects over Remote Play as that user\'s controller. If the phone connects with your account, your controller is detached from the TV. That is why the phone connects with a separate user; you keep playing on your own account.';

  @override
  String get gPs5UserStep1 =>
      'Add a new user on the PS5 (from the profile picture on the home screen: Switch User › Add User).';

  @override
  String get gPs5UserStep2 =>
      'Sign that user in with a PSN account. You can create one for free; PS Plus is not required.';

  @override
  String get gPs5UserStep3 =>
      'You will also sign in to PSN on the phone with this second account.';

  @override
  String get gPs5RemoteTitle => '2. Turn on Remote Play';

  @override
  String get gPs5RemoteStep1 => 'Switch to the second user on the PS5.';

  @override
  String get gPs5RemoteStep2 => 'Go to Settings › System › Remote Play.';

  @override
  String get gPs5RemoteStep3 => 'Turn on \"Enable Remote Play\".';

  @override
  String get gPs5WakeTitle => '3. Waking from rest mode (optional)';

  @override
  String get gPs5WakeBody =>
      'So the phone can wake the PS5 when you start translation while it is in rest mode:';

  @override
  String get gPs5WakeStep1 =>
      'Go to Settings › System › Power Saving › Features Available in Rest Mode.';

  @override
  String get gPs5WakeStep2 =>
      'Turn on \"Stay Connected to the Internet\" and \"Enable Turning On PS5 from Network\".';

  @override
  String get gPs5Tip =>
      'If you do not want waking, turn off Settings › PS5 › \"Wake if in rest mode\" on the phone.';

  @override
  String get gPairTitle => 'Pair the phone with the PS5';

  @override
  String get gPairSubtitle => 'PSN sign-in and the 8-digit code';

  @override
  String get gPairSignInTitle => '1. Sign in with PSN';

  @override
  String get gPairSignInStep1 =>
      'On the setup screen tap \"Sign in with PSN\". Sony\'s own sign-in page opens.';

  @override
  String get gPairSignInStep2 =>
      'Sign in with the account of the second user on the PS5.';

  @override
  String get gPairSignInStep3 =>
      'When sign-in finishes, the app returns to setup by itself and shows \"PSN account connected\".';

  @override
  String get gPairSignInTip =>
      'Your password goes straight to Sony; the app only stores your account ID.';

  @override
  String get gPairCodeTitle => '2. Enter the pairing code';

  @override
  String get gPairCodeStep1 =>
      'On the PS5, while the second user is active, go to Settings › System › Remote Play › \"Link Device\".';

  @override
  String get gPairCodeStep2 =>
      'An 8-digit code and a countdown appear on the screen. The code is valid for about 5 minutes.';

  @override
  String get gPairCodeStep3 =>
      'On the phone, pick your PS5 from the \"Found console\" list.';

  @override
  String get gPairCodeStep4 => 'Type the code into the boxes and tap \"Pair\".';

  @override
  String get gPairMissingTitle => 'If the PS5 is not in the list';

  @override
  String get gPairMissing1 =>
      'Check that the phone and the PS5 are on the same Wi-Fi network; it must not be a guest network or mobile data.';

  @override
  String get gPairMissing2 => 'Tap \"Refresh\".';

  @override
  String get gPairMissing3 =>
      'If it still does not appear, tap \"Enter the IP address manually\". The address is shown on the PS5 under Settings › Network › Connection Status › View Connection Status.';

  @override
  String get gPairTip =>
      'Pairing is done once. If the PS5 address changes, the app finds it again on the network.';

  @override
  String get gTvTitle => 'Prepare the TV';

  @override
  String get gTvSubtitle => 'Supported TVs and the TV app';

  @override
  String get gTvLead =>
      'A separate GameTranslator TV app shows the subtitles on the TV. It is not in the stores yet, so it is installed on the TV once. You can install it on LG and Android TV from this phone; on Samsung, installation is currently done from a computer.';

  @override
  String get gTvSupportedTitle => 'Which TVs are supported?';

  @override
  String get gTvTableLg => 'LG';

  @override
  String get gTvTableLgDetail => 'webOS 4 and later';

  @override
  String get gTvTableSamsung => 'Samsung';

  @override
  String get gTvTableSamsungDetail => 'Tizen, 2019 and later';

  @override
  String get gTvTableAndroid => 'Android TV / Google TV';

  @override
  String get gTvTableAndroidDetail =>
      'Vestel, Arçelik, Beko, Grundig, Philips, Sony, TCL and others';

  @override
  String get gTvTableOther => 'Others';

  @override
  String get gTvTableOtherDetail =>
      'Linux models from Vestel/Arçelik/Beko/Grundig, Philips Saphi, Titan OS';

  @override
  String get gTvNotSupported =>
      'Not supported: the app cannot be installed on these TVs.';

  @override
  String get gTvAndroidTip =>
      'Is your TV an Android TV? If the home screen says Google Play Store or \"Google TV\", it is.';

  @override
  String get gTvLgTitle => 'LG';

  @override
  String get gTvLgStep1 =>
      'On a computer, create a free LG developer account at webostv.developer.lge.com.';

  @override
  String get gTvLgStep2 =>
      'On the TV, install the \"Developer Mode\" app from LG Content Store, sign in with your account and turn on \"Dev Mode Status\". The TV restarts.';

  @override
  String get gTvLgStep3 =>
      'In the Developer Mode app on the TV, turn on \"Key Server\".';

  @override
  String get gTvLgStep4 =>
      'On the phone, choose LG in the \"Install the TV app\" wizard, find your TV and type the 6-character passphrase shown on the screen (the TV step of GameTranslator on a computer does the same).';

  @override
  String get gTvLgNote =>
      'On LG, developer mode stays on for at most 1000 hours. If you will not use it for a long time, press \"EXTEND\" in the Developer Mode app before the time runs out; once it expires the TV app is removed and you have to install it again.';

  @override
  String get gTvSamsungTitle => 'Samsung';

  @override
  String get gTvSamsungStep1 =>
      'On the TV open the Apps screen and press 1 2 3 4 5 on the remote. The developer mode window opens.';

  @override
  String get gTvSamsungStep2 =>
      'Turn on \"Developer mode\" and type your computer\'s address into \"Host PC IP\".';

  @override
  String get gTvSamsungStep3 =>
      'Fully power the TV off and on by holding the power button.';

  @override
  String get gTvSamsungStep4 =>
      'In the TV step of GameTranslator on the computer, select your TV. On the page that opens, sign in with a free Samsung account; the app is signed and installed.';

  @override
  String get gTvAndroidTitle => 'Android TV / Google TV';

  @override
  String get gTvAndroidStep1 =>
      'On the TV go to Settings › Device Preferences › About (on Google TV: Settings › System › About).';

  @override
  String get gTvAndroidStep2 => 'Press OK 7 times on \"Build\".';

  @override
  String get gTvAndroidStep3 =>
      'In Developer options turn on \"USB debugging\" (and \"Network debugging\" if available).';

  @override
  String get gTvAndroidStep4 =>
      'On the phone, choose \"Android TV / Google TV\" in the \"Install the TV app\" wizard and accept the prompt on the TV.';

  @override
  String get gTvAndroidNote =>
      'If the TV does not allow network debugging, you can also install with a USB drive: download the TV app APK from GameTranslator\'s releases page, copy it to the drive and open it with a file manager on the TV.';

  @override
  String get gTvAfterTitle => 'After installation';

  @override
  String get gTvAfterBody =>
      'The TV app finds the phone on the network by itself; you do not need to type the TV\'s address on the phone. On Samsung the computer is only needed for installation; afterwards it can stay off.';

  @override
  String get gTvObsTitle => 'For streamers: OBS';

  @override
  String gTvObsBody(String phone) {
    return 'While translation is on, the subtitles are also served as a web page. In OBS add a \"Browser Source\" and use http://$phone:8787/obs as the address (1920×1080). The page background is transparent; it does not show the subtitles over the game in the TV browser and is only meant for stream and recording layouts.';
  }

  @override
  String get gFirstTitle => 'First use';

  @override
  String get gFirstSubtitle => 'Start translation and see it on the TV';

  @override
  String get gFirstStep1 =>
      'Open the game on the PS5 with your own account and turn on subtitles in the game settings.';

  @override
  String get gFirstStep2 =>
      'Tap the big button on the phone\'s home screen. The first time you are asked for notification permission; allow it so translation can continue in the background.';

  @override
  String get gFirstStep3 =>
      'When the status says \"Translation on\", the PS5 card says \"Connected\". The first connection takes a few seconds.';

  @override
  String get gFirstStep4 =>
      'Open the GameTranslator app on the TV. Within a few seconds the TV card on the phone says \"Connected\".';

  @override
  String get gFirstStep5 =>
      'If the TV shows no game picture, press OK to open the panel and use left/right to select the HDMI input the PS5 is connected to.';

  @override
  String get gFirstStep6 =>
      'If there is no sound from the TV, the PS5 has routed audio to Remote Play: press the PS button, open Sound › Output Device from the menu at the bottom and choose HDMI. This is done once.';

  @override
  String get gFirstStep7 =>
      'On the phone tap \"Send a test subtitle to the TV\". If you see the text on the TV, everything is ready.';

  @override
  String get gFirstTip =>
      'You can turn the phone screen off while translation is on. To stop, tap the button in the app or \"Stop\" in the notification.';

  @override
  String get gFirstNextTitle => 'Next time';

  @override
  String get gFirstNextBody =>
      'Only two steps: start translation on the phone, open GameTranslator on the TV.';

  @override
  String get gFirstBatteryTitle => 'Battery and heat';

  @override
  String get gFirstBatteryBody =>
      'The phone decodes video and reads text continuously; for long sessions keep it plugged in.';

  @override
  String get gRemoteTitle => 'TV remote';

  @override
  String get gRemoteSubtitle => 'The buttons in the TV app';

  @override
  String get gRemoteLead =>
      'While GameTranslator is open on the TV, the remote buttons do this:';

  @override
  String get gRemoteOk => 'OK';

  @override
  String get gRemoteOkText =>
      'Opens and closes the status panel (HDMI input, connection status).';

  @override
  String get gRemoteLeftRight => 'Left / Right';

  @override
  String get gRemoteLeftRightText =>
      'Changes the HDMI input while the panel is open.';

  @override
  String get gRemoteNumbers => '1 – 4';

  @override
  String get gRemoteNumbersText => 'Selects the HDMI input directly.';

  @override
  String get gRemoteUpDown => 'Up / Down';

  @override
  String get gRemoteUpDownText =>
      'Moves the subtitle up or down on the screen.';

  @override
  String get gRemoteRed => 'Red';

  @override
  String get gRemoteRedText => 'Shows the TV\'s own test caption.';

  @override
  String get gRemoteGreen => 'Green';

  @override
  String get gRemoteGreenText => 'Opens and closes the status panel.';

  @override
  String get gRemoteBlue => 'Blue';

  @override
  String get gRemoteBlueText =>
      'Starts or stops the demo with sample subtitles.';

  @override
  String get gRemoteBack => 'Back';

  @override
  String get gRemoteBackText => 'Exits the app.';

  @override
  String get gRemoteTip =>
      'You play with the PS5 controller; the TV remote is only needed for these settings.';

  @override
  String get gRegionTitle => 'Adjust the subtitle region';

  @override
  String get gRegionSubtitle => 'Where the phone looks on the screen';

  @override
  String get gRegionBody =>
      'The phone reads only the area where the subtitles appear, not the whole screen. If the region is in the wrong place, no translation arrives or other text on the screen gets translated.';

  @override
  String get gRegionStep1 =>
      'With translation on, wait for a subtitle to appear in the game.';

  @override
  String get gRegionStep2 =>
      'Look at the blue frame in the preview on the home screen: the whole subtitle must be inside the frame.';

  @override
  String get gRegionStep3 =>
      'If not, tap \"Adjust the subtitle region\". Pick the Top, Bottom, Left or Right edge and move it with the slider.';

  @override
  String get gRegionStep4 =>
      'The \"Read in the frame\" line on the home screen shows what the phone reads at that moment; the whole subtitle should appear there.';

  @override
  String get gRegionBullet1 =>
      'If the start or end of the sentence is cut off, widen the frame.';

  @override
  String get gRegionBullet2 =>
      'If the top line of two-line subtitles disappears, move the top edge up.';

  @override
  String get gRegionBullet3 =>
      'If other text such as objectives or map names is translated, narrow the frame.';

  @override
  String get gRegionTip =>
      'Every game puts subtitles in a different place; when you start a new game, one look at the region is enough.';

  @override
  String get gLookTitle => 'Translation and appearance';

  @override
  String get gLookSubtitle => 'Engine, glossary and the text on the TV';

  @override
  String get gEngineTitle => 'Translation engine';

  @override
  String get gEngineGoogle => 'Google';

  @override
  String get gEngineGoogleText =>
      'Needs internet, no key required. The best starting point for most games.';

  @override
  String get gEngineDeepl => 'DeepL';

  @override
  String get gEngineDeeplText =>
      'Builds more natural sentences. You need to enter your own API key from DeepL.';

  @override
  String get gEngineOnDevice => 'On device';

  @override
  String get gEngineOnDeviceText =>
      'Works offline; its quality is lower than the others. The language model downloads once on first use.';

  @override
  String get gEngineFallback =>
      'If the internet drops, translation switches to the on-device model by itself and switches back when the connection returns.';

  @override
  String get gGlossaryTitle => 'Glossary';

  @override
  String get gGlossaryBody =>
      'To pin character names and game terms that the translation gets wrong (English → Turkish only). Open it from Settings › Translation › Glossary. Terms in \"terms\" are translated to the text you write; names in \"keep\" stay as they are.';

  @override
  String get gLookOnTvTitle => 'Appearance on the TV';

  @override
  String get gLookOnTv1 => 'Font size and color: Settings › On TV.';

  @override
  String get gLookOnTv2 =>
      'Subtitle position: covering the game subtitle, above it, below it, or fixed at the bottom of the screen.';

  @override
  String get gLookOnTv3 =>
      'Background darkness: how dark the black box behind the text is. Keep it high if you are covering the game subtitle.';

  @override
  String get gTroubleTitle => 'Troubleshooting';

  @override
  String get gTroubleSubtitle => 'Common situations';

  @override
  String get gQ1 =>
      'Translation does not start, it stays at \"Connecting to the PS5\"';

  @override
  String get gQ1A1 =>
      'Is the PS5 on? If it is in rest mode, enable waking as described in \"Prepare the PS5\".';

  @override
  String get gQ1A2 =>
      'Is the phone on Wi-Fi and on the same network as the PS5?';

  @override
  String get gQ1A3 => 'Is Remote Play enabled on the PS5?';

  @override
  String get gQ2 => '\"Remote Play is being used by another device\"';

  @override
  String get gQ2A1 =>
      'The PS5 accepts only one Remote Play connection at a time. If GameTranslator on a computer or another Remote Play app is open, close it.';

  @override
  String get gQ2A2 =>
      'If you just stopped it, wait a few seconds; the app retries by itself.';

  @override
  String get gQ3 => 'My controller got detached from the TV';

  @override
  String get gQ3A1 =>
      'The phone connected with the account you play on. Use Settings › PS5 › \"Change the PSN account\" to switch to the second user\'s account.';

  @override
  String get gQ4 => 'The TV card stays at \"Waiting\"';

  @override
  String get gQ4A1 => 'Is the GameTranslator app open on the TV?';

  @override
  String get gQ4A2 =>
      'Is the TV on the same network as the phone? It must not be a guest network or a different router.';

  @override
  String get gQ4A3 =>
      'If GameTranslator on a computer is open, close it; the TV connects to the first one it finds.';

  @override
  String get gQ4A4 =>
      'If the TV app was connected to a computer before, it may be stuck on that address. Follow the \"If the TV cannot find the phone\" steps below.';

  @override
  String get gTvNotFoundTitle => 'If the TV cannot find the phone';

  @override
  String get gRecoveryLead =>
      'The TV app remembers the address it last connected to. If it connected to a computer before, it may keep trying that address instead of looking for the phone. Clearing the saved address makes the app scan the network again and find the phone.';

  @override
  String get gRecoveryAndroidTitle =>
      'Android TV / Google TV (TCL, Sony, Philips, Vestel…)';

  @override
  String get gRecoveryAndroidStep1 =>
      'On the TV go to Settings › Apps and pick GameTranslator from the list (you may need \"Show all apps\").';

  @override
  String get gRecoveryAndroidStep2 =>
      'Choose \"Clear data\" and confirm. The app is not uninstalled; only the saved address and settings are reset.';

  @override
  String get gRecoveryAndroidStep3 =>
      'With translation on, open GameTranslator on the TV again.';

  @override
  String get gRecoveryAndroidStep4 =>
      'Wait up to a minute; the TV card on the phone turns \"Connected\".';

  @override
  String get gRecoverySamsungTitle => 'Samsung and LG';

  @override
  String get gRecoverySamsungStep1 =>
      'On these TVs app data cannot be cleared separately: remove GameTranslator from the TV.';

  @override
  String get gRecoverySamsungStep2 =>
      'Install it again with GameTranslator on a computer (the steps in \"Prepare the TV\").';

  @override
  String get gRecoverySamsungStep3 =>
      'Close GameTranslator on the computer, start translation on the phone and open the app on the TV.';

  @override
  String get gRecoveryStillTitle => 'If it still does not work';

  @override
  String get gRecoveryStill1 =>
      'Is GameTranslator on the computer closed? If it is open, the TV connects to it.';

  @override
  String get gRecoveryStill2 =>
      'Are the phone and the TV on the same Wi-Fi? If \"client isolation\" (AP isolation) is on in the router, the devices cannot see each other.';

  @override
  String get gRecoveryStill3 =>
      'The HDMI setting on the TV is also reset, so press OK to open the panel and select the PS5 input again.';

  @override
  String get gTroubleTip =>
      'If you cannot solve a problem, you can copy the records in Settings › About › Log and share them.';

  @override
  String get gQ5 => 'No game picture on the TV, the screen is black';

  @override
  String get gQ5A1 =>
      'Press OK to open the panel and use left/right to select the HDMI input the PS5 is connected to.';

  @override
  String get gQ5A2 =>
      'Some Android TVs do not hand the HDMI picture to another app; on those TVs the subtitle appears but the background stays black.';

  @override
  String get gQ6 => 'No subtitle at all';

  @override
  String get gQ6A1 => 'Are the game\'s own subtitles turned on?';

  @override
  String get gQ6A2 =>
      'If \"Read in the frame\" on the home screen is empty, the region is in the wrong place; see \"Adjust the subtitle region\".';

  @override
  String get gQ6A3 =>
      'Does the game language match the source language in Settings › Translation?';

  @override
  String get gQ6A4 =>
      'If \"Send a test subtitle to the TV\" works, the TV connection is fine; the problem is in reading.';

  @override
  String get gQ7 => 'The translation is partial or meaningless';

  @override
  String get gQ7A1 =>
      'If the start or end of the sentence is missing, widen the region.';

  @override
  String get gQ7A2 =>
      'If the engine is \"On device\", switch to Google or DeepL.';

  @override
  String get gQ7A3 =>
      'Reading is harder with very decorative or very small fonts; increasing the subtitle size in the game and adding a background helps.';

  @override
  String get gQ8 => 'Translation arrives late';

  @override
  String get gQ8A1 =>
      'Keep the phone and the PS5 close to the router if possible; weak Wi-Fi delays the picture.';

  @override
  String get gQ8A2 => 'With online engines the internet speed matters too.';

  @override
  String get gQ9 => 'Translation stops when I turn the screen off';

  @override
  String get gQ9A1 =>
      'The phone\'s battery saver may be stopping the app. On the phone go to Settings › Apps › GameTranslator › Battery and choose \"Unrestricted\".';

  @override
  String get gQ9A2 =>
      'If you turned off notification permission, turn it back on; the background service runs with a notification.';

  @override
  String get commonOk => 'OK';

  @override
  String get setupTitle => 'Setup';

  @override
  String get setupSubtitleAccount => 'First connect your PlayStation account.';

  @override
  String get setupSubtitlePs5 => 'Finish the connection with the PS5.';

  @override
  String get setupSignInTitle => 'Sign in with PSN';

  @override
  String get setupSignInSubtitle => 'Connect your PlayStation Network account.';

  @override
  String get setupSignedIn => 'PSN account connected.';

  @override
  String get setupChange => 'Change';

  @override
  String get setupSignInBody =>
      'Sign in with the PSN account of the second user (alt account) on the PS5. That way your controller is not detached from the TV while you play on your own account.';

  @override
  String get setupSignInPrivacy =>
      'Sign-in happens on Sony\'s own page. Your password is not stored in this app or anywhere else.';

  @override
  String get setupPairTitle => 'Pair with the PS5';

  @override
  String get setupPairSubtitle => 'Pair your phone with the PS5.';

  @override
  String get setupPairStepA => 'Switch to the second user on the PS5.';

  @override
  String get setupPairStepB =>
      'In Settings › System › Remote Play, turn on \"Enable Remote Play\".';

  @override
  String get setupPairStepC =>
      'Open \"Link Device\". An 8-digit code appears on the screen.';

  @override
  String get setupFoundConsole => 'Found console';

  @override
  String get setupSearching => 'Searching…';

  @override
  String get setupRefresh => 'Refresh';

  @override
  String get setupNotFound =>
      'PS5 not found. The phone and the PS5 must be on the same Wi-Fi network. You can also type the PS5 IP address below (on the PS5: Settings › Network › Connection Status).';

  @override
  String get setupIpLabel => 'PS5 IP address';

  @override
  String get setupEnterIp => 'Enter the IP address manually';

  @override
  String get setupPairCode => 'Pairing code';

  @override
  String get setupErrorNoHost => 'Select the PS5 first or type its IP address.';

  @override
  String get setupErrorPin => 'Enter the 8-digit code shown on the PS5.';

  @override
  String get setupErrorPairFailed => 'Pairing failed.';

  @override
  String get setupPairing => 'Pairing…';

  @override
  String get setupPairAction => 'Pair';

  @override
  String setupStepOf(int number) {
    return 'Step $number / 2';
  }

  @override
  String get setupWaitingPsn => 'Complete the PSN sign-in first.';

  @override
  String get setupConsoleAwake => 'on';

  @override
  String get setupConsoleResting => 'in rest mode';

  @override
  String get setupPsnLoginTitle => 'PSN Sign-in';

  @override
  String get setupLoginIncomplete => 'Sign-in did not complete.';

  @override
  String get setupManualId => 'Enter the account ID manually';

  @override
  String get setupManualIdHelp =>
      'If the sign-in page does not open, you can paste the PSN account ID you got from a tool like Chiaki here.';

  @override
  String get setupManualIdHint => 'Base64 account ID';

  @override
  String get setupManualIdError => 'The account ID must be 8 bytes of base64.';

  @override
  String get setupReload => 'Reload the page';

  @override
  String get setupConnectingAccount => 'Connecting the account…';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get splashTagline => 'Play the game in your own language';

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

  @override
  String get tvInstallTitle => 'Install the TV App';

  @override
  String tvInstallStepLabel(int number) {
    return 'STEP $number OF 4';
  }

  @override
  String get tvInstallBrandQuestion => 'What brand is your TV?';

  @override
  String get tvInstallIntroBody =>
      'We will install the GameTranslator app that shows subtitles on your TV, from your phone. The phone and the TV must be on the same Wi-Fi network.';

  @override
  String get tvInstallSavedHeader => 'SAVED TV';

  @override
  String tvInstallSavedSubtitle(String host, String version, String phone) {
    return '$host · $version on TV · $phone on phone';
  }

  @override
  String get tvInstallUpdateAvailable => 'Update available';

  @override
  String get tvInstallUpdate => 'Update';

  @override
  String get tvInstallReinstall => 'Install again';

  @override
  String get tvInstallBrandHeader => 'BRAND';

  @override
  String get tvInstallBrandAndroidSubtitle =>
      'TCL, Sony, Philips, Xiaomi, Vestel, Arçelik, Beko, Grundig… The home screen shows Google Play or \"Google TV\".';

  @override
  String get tvInstallBrandLgSubtitle =>
      'webOS. The home screen has \"LG Content Store\" and colorful app cards along the bottom bar.';

  @override
  String get tvInstallBrandSamsungSubtitle =>
      'Tizen, 2019 and later. The home screen has \"Samsung TV Plus\" and \"Smart Hub\".';

  @override
  String get tvInstallBrandFooter =>
      'Not sure? The TV\'s Settings › Support (or About) screen shows the model and operating system. Vestel/Arçelik/Beko/Grundig Linux models, Philips Saphi and Titan OS are not supported.';

  @override
  String get tvInstallSamsungStep => 'Samsung: install from a computer';

  @override
  String get tvInstallSamsungNoticeTitle =>
      'Installing on a Samsung TV currently needs a computer';

  @override
  String get tvInstallSamsungNoticeText =>
      'Samsung requires the app to be signed separately with a Samsung account for each TV. Installing from the phone is not ready yet; GameTranslator on a computer does this by itself. Installation is done once, then the computer is not needed.';

  @override
  String get tvInstallSamsungStepsTitle => 'Steps at a glance';

  @override
  String get tvInstallSamsungStep1 =>
      'Open the Apps screen on the TV and press 1 2 3 4 5 on the remote.';

  @override
  String get tvInstallSamsungStep2 =>
      'Set \"Developer mode\" to \"On\", type the COMPUTER\'s address in \"Host PC IP\" and press OK.';

  @override
  String get tvInstallSamsungStep3 =>
      'Fully power the TV off and on by holding the power button.';

  @override
  String get tvInstallSamsungStep4 =>
      'On the computer, choose your Samsung TV in GameTranslator\'s TV step and sign in with your Samsung account on the page that opens.';

  @override
  String get tvInstallShowDetailed => 'Show details in the guide';

  @override
  String get tvInstallOtherBrand => 'Choose another brand';

  @override
  String get tvInstallFindStep => 'Find your TV';

  @override
  String get tvInstallFindBodyAndroid =>
      'Looking for Android TVs with network debugging enabled. If you have not enabled debugging yet, the TV will not appear here; that is fine, continue with \"Show steps\".';

  @override
  String get tvInstallFindBodyLg =>
      'Looking for LG TVs on the same network as the phone. The TV must be on.';

  @override
  String get tvInstallSearchingHeader => 'SEARCHING…';

  @override
  String get tvInstallFoundHeader => 'TVS FOUND';

  @override
  String get tvInstallScanning =>
      'Scanning the network, this takes a few seconds…';

  @override
  String get tvInstallNotFound => 'No TV found';

  @override
  String get tvInstallNotSearched => 'Not searched yet';

  @override
  String get tvInstallNotSearchedNote =>
      'Tap Refresh or type the address manually.';

  @override
  String get tvInstallReady => 'Ready';

  @override
  String get tvInstallRefresh => 'Refresh';

  @override
  String get tvInstallManualHeader => 'TYPE THE ADDRESS MANUALLY';

  @override
  String get tvInstallIpHint => 'e.g. 192.168.1.40';

  @override
  String get tvInstallUseAddress => 'Use this address';

  @override
  String get tvInstallAddressFooterAndroid =>
      'The TV\'s address: Settings › Network & Internet › the Wi-Fi network you are connected to (Google TV: Settings › Network & Internet).';

  @override
  String get tvInstallAddressFooterLg =>
      'The TV\'s address: Settings › General › Network › Wi-Fi Connection › Advanced Wi-Fi Settings (on some models Settings › Network).';

  @override
  String tvInstallSameSubnet(String phone) {
    return 'The phone\'s address is $phone; the TV\'s must share the first three parts.';
  }

  @override
  String get tvInstallShowSteps => 'Show steps';

  @override
  String get tvInstallIpError =>
      'This does not look like an IP address. Example: 192.168.1.40';

  @override
  String get tvInstallDebugStep => 'Enable debugging';

  @override
  String get tvInstallDevModeStep => 'Enable developer mode';

  @override
  String tvInstallStepCounter(int index, int total) {
    return 'Step $index of $total';
  }

  @override
  String get tvInstallCopy => 'Copy';

  @override
  String get tvInstallCopied => 'Address copied';

  @override
  String get tvInstallKeyServerOn => 'Key Server is on. You can continue.';

  @override
  String get tvInstallDeviceReady => 'The TV is ready. You can continue.';

  @override
  String get tvInstallSearchingTv => 'Looking for the TV on the network…';

  @override
  String tvInstallWaitingTv(String host) {
    return 'Waiting for the TV ($host)…';
  }

  @override
  String get tvInstallDifferentMenu => 'If the menu looks different';

  @override
  String get tvInstallDidIt => 'I did this';

  @override
  String get tvInstallGoInstall => 'Go to install';

  @override
  String get tvInstallWaitingFooter =>
      'Waiting for the TV to appear on the network. If it does not, go back and type the TV\'s address manually.';

  @override
  String get tvInstallInstallStep => 'Install';

  @override
  String get tvInstallVersionToInstall => 'Version to install';

  @override
  String get tvInstallPassHeader => 'PASSWORD ON THE TV SCREEN';

  @override
  String get tvInstallPassHint => 'e.g. 2FEEB2';

  @override
  String get tvInstallPassFooter =>
      'The 6 characters shown as \"Passphrase\" in the bottom left of the screen while Key Server is on in the Developer Mode app. Asked only during this first install.';

  @override
  String get tvInstallApproveTitle => 'A prompt will appear on the TV';

  @override
  String get tvInstallApproveText =>
      'On the \"Allow USB debugging?\" prompt, tick \"Always allow from this computer\" and choose \"Allow\". The prompt appears only during the first install.';

  @override
  String get tvInstallLookAtTvTitle => 'Now look at the TV';

  @override
  String get tvInstallLookAtTvText =>
      'The TV is asking \"Allow USB debugging?\". Tick \"Always allow from this computer\" and choose \"Allow\". The install then continues on its own.';

  @override
  String get tvInstallKeepScreenOn =>
      'Keep the phone screen on. Installation usually takes less than a minute.';

  @override
  String get tvInstallTvSaid => 'What the TV said';

  @override
  String get tvInstallStop => 'Stop';

  @override
  String get tvInstallInstallButton => 'Install on TV';

  @override
  String get tvInstallRetry => 'Try again';

  @override
  String get tvInstallBackToSteps => 'Back to steps';

  @override
  String get tvInstallInstalled => 'TV app installed';

  @override
  String get tvInstallAlreadyCurrent => 'TV app is already up to date';

  @override
  String tvInstallVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get tvInstallLaunchedTitle => 'GameTranslator opened on the TV';

  @override
  String get tvInstallOpenOnTvTitle => 'Open GameTranslator on the TV';

  @override
  String get tvInstallLaunchedText =>
      'When you start translating on the phone, the TV app finds the phone on the network by itself.';

  @override
  String get tvInstallOpenOnTvText =>
      'Find GameTranslator in the TV\'s app list and open it. It finds the phone by itself when you start translating.';

  @override
  String get tvInstallLgHoursTitle => 'LG developer mode period';

  @override
  String tvInstallHoursLeft(int hours) {
    return 'Time left: $hours hours.';
  }

  @override
  String get tvInstallLgHoursText =>
      'When the period ends, the TV app is removed. If you will not use it for a long time, press \"EXTEND\" in the Developer Mode app on the TV; installing again from this page also extends it.';

  @override
  String get tvInstallAndroidNote =>
      'If you like, you can now turn USB debugging off on the TV. You will need to turn it on again to install a new version.';

  @override
  String get tvInstallDone => 'Done';

  @override
  String get tvInstallBrandFallback => 'TV';

  @override
  String get tvGuideA1Title => 'Open Settings on the TV';

  @override
  String get tvGuideA1Body =>
      'Press the gear (Settings) button on the TV remote. If the remote does not have one, choose the gear icon at the top right of the home screen.';

  @override
  String get tvGuideA1Different =>
      'On Google TV (newer Sony, TCL, Philips, Xiaomi models) choose the profile picture or the gear at the top right, then go to \"Settings\".';

  @override
  String get tvGuideA2Title => 'Open the \"About\" screen';

  @override
  String get tvGuideA2Body =>
      'Android TV: Settings › Device Preferences › About.\nGoogle TV: Settings › System › About.';

  @override
  String get tvGuideA2Different =>
      'Philips: Settings › Android Settings › Device Preferences › About.\nSony: Settings › System › About (on older models Device Preferences › About).\nTCL and Xiaomi: Settings › System › About or Device Preferences › About.\nIf you cannot find it, type \"About\" in the settings search.';

  @override
  String get tvGuideA3Title => 'Press the build row 7 times';

  @override
  String get tvGuideA3Body =>
      'Select the \"Android TV OS build\" row at the bottom of the list and press the remote\'s OK button 7 times in a row. A \"You are now a developer\" message appears.';

  @override
  String get tvGuideA3Different =>
      'The row may be called \"Build number\", \"Build\" or \"Derleme\" depending on the model. If the TV asks for a PIN, enter the TV\'s lock PIN. If it says \"You are already a developer\", this step is done.';

  @override
  String get tvGuideA4Title => 'Open developer options';

  @override
  String get tvGuideA4Body =>
      'Go back one screen with the back button. A new \"Developer options\" row has appeared under Device Preferences on Android TV and under System on Google TV; open it.';

  @override
  String get tvGuideA4Different =>
      'If you cannot see the row, leave Settings completely and enter again. If it is still missing, repeat pressing 7 times in the previous step.';

  @override
  String get tvGuideA5Title => 'Turn on \"USB debugging\"';

  @override
  String get tvGuideA5Body =>
      'Find \"USB debugging\" in the developer options list and turn it on; choose \"OK\" on the warning. If the list has \"Debug over network\" or \"ADB network debugging\", turn that on too.\n\nWhen the TV is on, this turns green by itself.';

  @override
  String get tvGuideA5Different =>
      'The option may be called \"Debugging (ADB)\" or \"USB debugging\". Models that only offer \"Wireless debugging\" and ask for a pairing code (e.g. Google TV Streamer) cannot be installed from the phone yet; use the USB drive path in the Guide for those.';

  @override
  String get tvGuideL1Title => 'Create a free LG developer account';

  @override
  String get tvGuideL1Body =>
      'Open the address below in your phone\'s browser, choose \"SIGN IN\" at the top right, then \"Create Account\" for a free account. You will type your e-mail and password on the TV in the next step.';

  @override
  String get tvGuideL1Different =>
      'If you already have an LG account (e.g. LG ThinQ) you can sign in with the same e-mail and password; skip this step.';

  @override
  String get tvGuideL2Title => 'Install the \"Developer Mode\" app on the TV';

  @override
  String get tvGuideL2Body =>
      'Open LG Content Store (Apps) on the TV, type \"Developer Mode\" in the search box and install the app.';

  @override
  String get tvGuideL2Different =>
      'If the store does not open, check that the TV is connected to the internet. On older models the store is called \"LG Store\" or \"Apps\". The app appears in English.';

  @override
  String get tvGuideL3Title => 'Sign in and turn on \"Dev Mode Status\"';

  @override
  String get tvGuideL3Body =>
      'Open the Developer Mode app and sign in with your LG account e-mail and password. Turn on the \"Dev Mode Status\" switch. The TV restarts by itself; wait for it to come back.\n\nWhen developer mode is on, this turns green by itself.';

  @override
  String get tvGuideL3Different =>
      'If \"Dev Mode Status\" is grey and cannot be selected, you have not signed in yet. If signing in says \"Login failed\", make sure you have verified your account\'s e-mail.';

  @override
  String get tvGuideL4Title => 'Turn on \"Key Server\"';

  @override
  String get tvGuideL4Body =>
      'After the TV comes back on, open the Developer Mode app again and turn on the \"Key Server\" switch. Leave the app on screen; if you close it, Key Server turns off too.\n\nWhen Key Server is on, this turns green by itself.';

  @override
  String get tvGuideL4Different =>
      'A 6-character \"Passphrase\" appears at the bottom left of the screen; you will type it in the next step.';

  @override
  String get tvErrUnreachableAndroidTitle => 'The TV did not respond';

  @override
  String get tvErrUnreachableAndroidFix =>
      'Is the TV on and on the same Wi-Fi network as the phone? \"USB debugging\" must be on in developer options. On some TVs this setting turns off when the TV restarts; turn it on and try again.';

  @override
  String get tvErrUnreachableLgTitle => 'The TV did not respond';

  @override
  String get tvErrUnreachableLgFix =>
      'Is the TV on and on the same Wi-Fi network as the phone? \"Dev Mode Status\" must be on in the Developer Mode app; after you turn it on the TV restarts, wait for it to come back.';

  @override
  String get tvErrKeyServerOffTitle => 'Key Server is off';

  @override
  String get tvErrKeyServerOffFix =>
      'Open the Developer Mode app on the TV, turn on \"Key Server\" and leave the app on screen. Then try again.';

  @override
  String get tvErrWrongPassphraseTitle => 'The password is not correct';

  @override
  String get tvErrWrongPassphraseFix =>
      'Type the 6-character \"Passphrase\" shown at the bottom left of the Developer Mode app on the TV again. 0 (zero) and the letter O, 1 and the letter I can be confused.';

  @override
  String get tvErrKeyRefusedTitle => 'The TV refused the key';

  @override
  String get tvErrKeyRefusedFix =>
      'If developer mode was turned off and on, the TV generates a new key. Turn on Key Server and type the password again.';

  @override
  String get tvErrNotApprovedTitle => 'Not allowed on the TV';

  @override
  String get tvErrNotApprovedFix =>
      'Try again. When the \"Allow USB debugging?\" prompt appears on the TV, tick \"Always allow from this computer\" and choose \"Allow\". The prompt waits on the TV screen for about a minute and a half.';

  @override
  String get tvErrNoSpaceTitle => 'No space left on the TV';

  @override
  String get tvErrNoSpaceFix =>
      'Uninstall an app you do not use from the TV and try again.';

  @override
  String get tvErrConnectionLostTitle => 'Connection lost';

  @override
  String get tvErrConnectionLostFix =>
      'The connection to the TV was lost during installation. Keep the phone screen on and connected to Wi-Fi; try again.';

  @override
  String get tvErrTooOldTitle => 'This TV is too old';

  @override
  String get tvErrTooOldFix =>
      'The GameTranslator TV app does not run on this TV\'s software.';

  @override
  String get tvErrPackageMissingTitle => 'TV package not found';

  @override
  String get tvErrPackageMissingFix =>
      'This phone app does not contain the TV package. Install the latest version of the app.';

  @override
  String get tvErrCancelledTitle => 'Installation stopped';

  @override
  String get tvErrCancelledFix => 'You can start it again when you are ready.';

  @override
  String get tvErrGenericTitle => 'The TV app could not be installed';

  @override
  String get tvErrGenericFix =>
      'Try again. Restarting the TV fixes most half-finished installs. If it still fails, report it to us together with the \"What the TV said\" text below.';

  @override
  String tvStageUploading(String percent) {
    return 'Sending the app to the TV… %$percent';
  }

  @override
  String get tvStageConnecting => 'Connecting to the TV…';

  @override
  String get tvStageApprove => 'Waiting for approval on the TV…';

  @override
  String get tvStageChecking => 'Checking the version on the TV…';

  @override
  String get tvStageKey => 'Getting a key from the TV…';

  @override
  String get tvStageInstalling => 'Installing on the TV…';

  @override
  String get tvStageVerifying => 'Verifying the installation…';

  @override
  String get tvStageLaunching => 'Opening on the TV…';

  @override
  String get tvStagePreparing => 'Preparing…';

  @override
  String psnErrAuth(int status, String detail) {
    return 'Sony rejected the sign-in (HTTP $status)$detail';
  }

  @override
  String psnErrAccount(int status) {
    return 'Could not get the account ID (HTTP $status)';
  }

  @override
  String psnErrNetwork(String error) {
    return 'Could not reach Sony: $error';
  }

  @override
  String get commonBack => 'Back';
}
