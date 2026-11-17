// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:convert';

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_language.dart';
import 'bridge.dart';
import 'home_page.dart';
import 'intro_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'tv_install_page.dart';
import 'ui.dart';

/// Ayarlar sekmesi, iOS ayarları düzeninde: çeviri, altyazı bölgesi, TV'deki görünüm, PS5 ve hakkında.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, required this.setup, required this.onSetupChanged, required this.active});

  final SetupInfo setup;
  final Future<void> Function() onSetupChanged;

  /// Sekme ekranda mı? Arkadayken oyun görüntüsü istenmez.
  final bool active;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  /// Oyun/çeviri dilleri: kod → o dilin kendi adı (çevrilmez).
  static const languages = {
    'tr': 'Türkçe',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ar': 'العربية',
    'ja': '日本語',
  };

  static const flags = {
    'tr': '🇹🇷',
    'en': '🇬🇧',
    'de': '🇩🇪',
    'fr': '🇫🇷',
    'es': '🇪🇸',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ar': '🇸🇦',
    'ja': '🇯🇵',
  };

  /// Arayüz dillerinin kendi adlarıyla listesi (sistem dilinden bağımsız).
  static const uiLanguages = {'tr': 'Türkçe', 'en': 'English', 'ar': 'العربية'};

  static const defaultRegion = {'top': 0.62, 'bottom': 0.97, 'left': 0.14, 'right': 0.86};

  AppSettings? settings;
  final deepLController = TextEditingController();
  final geminiController = TextEditingController();
  bool checkingGemini = false;
  bool updatingPatches = false;
  (bool, String)? patchesResult;

  /// Arayüz dilini seçer: seçim hemen uygulanır, ayarlara yazılır.
  Future<void> pickAppLanguage() async {
    final picked = await showApplePicker(
      context,
      title: AppLocalizations.of(context).settingsAppLanguage,
      options: uiLanguages,
      selected: settings?.uiLanguage ?? AppLanguage.fallback,
    );
    if (picked == null || !mounted) return;
    change((s) => s.json['uiLanguage'] = picked);
    AppLanguage.current.value = picked;
  }

  /// Bilgisayar sürümündeki "Oyun" seçimi: en üstte Otomatik, altında Türkçe yaması olan oyunlar.
  Future<void> pickGame() async {
    final l = AppLocalizations.of(context);
    final games = await Bridge.packList();
    if (!mounted) return;
    final options = <String, String>{'': l.settingsGameAutoOption};
    for (final game in games) {
      options[game.id] = l.settingsGameOptionLine(game.title, game.entries);
    }
    final picked = await showApplePicker(context, title: l.settingsGame, options: options, selected: settings?.packChoice ?? '');
    if (picked != null) change((s) => s.json['packChoice'] = picked);
    if (games.isNotEmpty) setState(() => gameTitles = {for (final game in games) game.id: game.title});
  }

  Map<String, String> gameTitles = {};

  /// Paket listesi henüz alınmadıysa kimlikten okunur ad: "mafia-the-old-country" → "Mafia The Old Country".
  static String titleFromId(String id) => id
      .split(RegExp('[-_]'))
      .where((w) => w.isNotEmpty)
      .map((w) => RegExp(r'^(ii|iii|iv|v|vi|vii|viii|ix|x|xi|xii)$').hasMatch(w) ? w.toUpperCase() : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Future<void> updatePatches() async {
    setState(() {
      updatingPatches = true;
      patchesResult = null;
    });
    final result = await Bridge.updatePatches();
    if (!mounted) return;
    setState(() {
      updatingPatches = false;
      patchesResult = result;
    });
  }
  (bool, String)? geminiResult;

  /// Anahtarı hemen kaydeder ve bir deneme çevirisiyle sınar.
  Future<void> checkGemini() async {
    final current = settings;
    if (current == null) return;
    current.json['geminiKey'] = geminiController.text.trim();
    saveTimer?.cancel();
    setState(() {
      checkingGemini = true;
      geminiResult = null;
    });
    await Bridge.saveSettings(current);
    final result = await Bridge.checkGemini(geminiController.text.trim());
    if (!mounted) return;
    setState(() {
      checkingGemini = false;
      geminiResult = result;
    });
  }
  Uint8List? preview;
  Timer? saveTimer;
  Timer? previewTimer;

  /// Altyazı bölgesinde sürgünün ayarladığı kenar.
  String edge = 'top';

  @override
  void initState() {
    super.initState();
    load();
    // Bölge ayarlanırken oyun görüntüsü güncel kalsın.
    previewTimer = Timer.periodic(const Duration(seconds: 2), (_) => refreshPreview());
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    previewTimer?.cancel();
    final current = settings;
    if (current != null) Bridge.saveSettings(current);
    deepLController.dispose();
    geminiController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final loaded = await Bridge.settings();
    final image = await Bridge.snapshot(width: 640);
    if (!mounted) return;
    setState(() {
      settings = loaded;
      preview = image;
      deepLController.text = loaded.deepLKey;
      geminiController.text = loaded.geminiKey;
    });
  }

  Future<void> refreshPreview() async {
    if (!mounted || !widget.active) return;
    final image = await Bridge.snapshot(width: 640);
    if (mounted && image != null) setState(() => preview = image);
  }

  /// Değişiklik hemen ekrana yansır; kaydetme sürgü sürüklenirken her adımda değil, kısa bir aradan sonra yapılır.
  void change(void Function(AppSettings) edit) {
    final current = settings;
    if (current == null) return;
    setState(() => edit(current));
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 300), () => Bridge.saveSettings(current));
  }

  void setRegion(String edge, double value) => change((s) {
        final region = s.region;
        region[edge] = value;
        // Bölge en az %5 yüksekliğinde ve genişliğinde kalır.
        if (edge == 'top' && region['bottom'] < value + 0.05) region['bottom'] = (value + 0.05).clamp(0.0, 1.0);
        if (edge == 'bottom' && region['top'] > value - 0.05) region['top'] = (value - 0.05).clamp(0.0, 1.0);
        if (edge == 'left' && region['right'] < value + 0.05) region['right'] = (value + 0.05).clamp(0.0, 1.0);
        if (edge == 'right' && region['left'] > value - 0.05) region['left'] = (value - 0.05).clamp(0.0, 1.0);
        s.json['region'] = region;
      });

  void setStyle(String key, Object value) => change((s) {
        final style = s.style;
        style[key] = value;
        s.json['style'] = style;
      });

  Future<void> pickLanguage(String key, String title) async {
    final picked = await showApplePicker(context, title: title, options: languages, selected: settings?.json[key] as String?, leading: flags);
    if (picked != null) change((s) => s.json[key] = picked);
  }

  Future<void> pickPlacement() async {
    final l = AppLocalizations.of(context);
    final picked = await showApplePicker(
      context,
      title: l.settingsPlacement,
      options: {
        'cover': l.settingsPlacementCover,
        'above': l.settingsPlacementAbove,
        'below': l.settingsPlacementBelow,
        'fixed': l.settingsPlacementFixed,
      },
      selected: settings?.style['placement'] as String?,
    );
    if (picked != null) setStyle('placement', picked);
  }

  Future<void> editGlossary() async {
    final current = settings;
    if (current == null) return;
    final text = await Navigator.of(context).push<String>(appleRoute((_) => GlossaryPage(initial: current.glossary)));
    if (text != null) change((s) => s.json['glossary'] = text);
  }

  Future<void> sendTest() async {
    final l = AppLocalizations.of(context);
    await Bridge.testSubtitle();
    if (mounted) toast(context, l.settingsTestSent);
  }

  Future<void> confirmForget({required bool account}) async {
    final l = AppLocalizations.of(context);
    final confirmed = await confirmApple(
      context,
      title: account ? l.settingsForgetTitleAccount : l.settingsForgetTitleConsole,
      message: account ? l.settingsForgetMessageAccount : l.settingsForgetMessageConsole,
      action: l.settingsForgetAction,
      destructive: true,
    );
    if (!confirmed) return;
    await Bridge.stop();
    if (account) {
      await Bridge.forgetAccount();
    } else {
      await Bridge.forgetConsole();
    }
    await widget.onSetupChanged();
  }

  void showIntro() {
    Navigator.of(context).push(appleRoute<void>((context) => IntroPage(replay: true, onDone: () async => Navigator.of(context).pop())));
  }

  Future<void> showLogs() async {
    final l = AppLocalizations.of(context);
    final lines = await Bridge.logs();
    if (!mounted) return;
    final text = lines.isEmpty ? l.settingsLogsEmpty : lines.reversed.join('\n');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (sheet, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Row(
              children: [
                Expanded(child: Text(l.settingsLogTitle, style: Txt.title2)),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.of(sheet).pop();
                    toast(context, l.settingsLogCopied);
                  },
                  child: Text(l.settingsCopy),
                ),
              ],
            ),
            Text(l.settingsLogNote, style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
            const SizedBox(height: 12),
            SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Tokens.textSecondary, height: 1.45)),
          ],
        ),
      ),
    );
  }

  String glossarySummaryOf(AppLocalizations l) {
    final (terms, keep, problem) = GlossaryPage.inspect(settings?.glossary ?? '');
    if (problem != null) return l.settingsGlossaryInvalid;
    if (terms + keep == 0) return l.settingsGlossaryEmpty;
    return l.settingsGlossaryCount(terms + keep);
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    if (s == null) return const Center(child: CupertinoActivityIndicator(radius: 14));
    final style = s.style;
    final l = AppLocalizations.of(context);
    return LargeTitleList(
      title: l.settingsTitle,
      children: [
        GroupHeader(l.settingsGroupApp),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.globe,
              iconColor: Tokens.teal,
              title: l.settingsAppLanguage,
              subtitle: l.settingsAppLanguageNote,
              value: uiLanguages[s.uiLanguage] ?? s.uiLanguage,
              chevron: true,
              onTap: pickAppLanguage,
            ),
          ],
        ),
        // ---------------------------------------------------------------- Çeviri
        GroupHeader(l.settingsGroupTranslate),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.gamecontroller_fill,
              iconColor: Tokens.indigo,
              title: l.settingsSourceLanguage,
              value: '${flags[s.sourceLanguage] ?? ''} ${languages[s.sourceLanguage] ?? s.sourceLanguage}',
              chevron: true,
              onTap: () => pickLanguage('sourceLanguage', l.settingsSourceLanguage),
            ),
            Cell(
              icon: CupertinoIcons.globe,
              iconColor: Tokens.accent,
              title: l.settingsTargetLanguage,
              value: '${flags[s.targetLanguage] ?? ''} ${languages[s.targetLanguage] ?? s.targetLanguage}',
              chevron: true,
              onTap: () => pickLanguage('targetLanguage', l.settingsTargetLanguage),
            ),
            if (s.sourceLanguage == 'en' && s.targetLanguage == 'tr')
              Cell(
                icon: CupertinoIcons.book_fill,
                iconColor: Tokens.warning,
                title: l.settingsGlossary,
                value: glossarySummaryOf(l),
                chevron: true,
                onTap: editGlossary,
              ),
            if (s.sourceLanguage == 'en' && s.targetLanguage == 'tr')
              Cell(
                icon: CupertinoIcons.cube_box_fill,
                iconColor: Tokens.success,
                title: l.settingsPacks,
                subtitle: l.settingsPacksNote,
                trailing: CupertinoSwitch(
                  value: s.packsEnabled,
                  activeTrackColor: Tokens.success,
                  onChanged: (value) => change((s) => s.json['packsEnabled'] = value),
                ),
              ),
            if (Platform.isIOS && s.packsEnabled && s.sourceLanguage == 'en' && s.targetLanguage == 'tr')
              Cell(
                icon: CupertinoIcons.gamecontroller_fill,
                iconColor: Tokens.accent,
                title: l.settingsGame,
                value: s.packChoice.isEmpty ? l.settingsGameAuto : (gameTitles[s.packChoice] ?? titleFromId(s.packChoice)),
                chevron: true,
                onTap: pickGame,
              ),
            if (Platform.isIOS && s.packsEnabled && s.sourceLanguage == 'en' && s.targetLanguage == 'tr')
              Cell(
                icon: CupertinoIcons.arrow_down_circle_fill,
                iconColor: Tokens.success,
                title: updatingPatches ? l.settingsPatchesBusy : l.settingsPatches,
                subtitle: patchesResult?.$2 ?? l.settingsPatchesNote,
                onTap: updatingPatches ? null : updatePatches,
              ),
            if (Platform.isIOS)
              Cell(
                icon: CupertinoIcons.game_controller_solid,
                iconColor: Tokens.accent,
                title: l.settingsHideButtonHints,
                subtitle: l.settingsHideButtonHintsNote,
                trailing: CupertinoSwitch(
                  value: s.hideButtonHints,
                  activeTrackColor: Tokens.success,
                  onChanged: (value) => change((s) => s.json['hideButtonHints'] = value),
                ),
              ),
          ],
        ),
        if (s.sourceLanguage == 'en' && s.targetLanguage == 'tr') GroupFooter(l.settingsPacksFooter),
        GroupHeader(l.settingsGroupEngine),
        Group(
          children: [
            Cell(
              title: 'Google',
              subtitle: l.settingsEngineGoogleNote,
              checked: s.engine == 'google',
              onTap: () => change((s) => s.json['engine'] = 'google'),
            ),
            Cell(
              title: 'DeepL',
              subtitle: l.settingsEngineDeeplNote,
              checked: s.engine == 'deepl',
              onTap: () => change((s) => s.json['engine'] = 'deepl'),
            ),
            if (s.engine == 'deepl')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: TextField(
                  controller: deepLController,
                  autocorrect: false,
                  decoration: InputDecoration(hintText: l.settingsDeeplKeyHint),
                  onChanged: (value) => change((s) => s.json['deepLKey'] = value.trim()),
                ),
              ),
            // Yapay zekâ çevirisi (bilgisayar sürümündeki gibi); şimdilik yalnız iPhone'da.
            if (Platform.isIOS)
              Cell(
                title: 'Google Gemini',
                subtitle: l.settingsEngineGeminiNote,
                checked: s.engine == 'gemini',
                onTap: () => change((s) => s.json['engine'] = 'gemini'),
              ),
            if (Platform.isIOS && s.engine == 'gemini')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: geminiController,
                      autocorrect: false,
                      obscureText: true,
                      decoration: InputDecoration(hintText: l.settingsGeminiKeyHint),
                      onChanged: (value) => change((s) => s.json['geminiKey'] = value.trim()),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: checkingGemini ? null : checkGemini,
                      child: Text(checkingGemini ? l.settingsGeminiChecking : l.settingsGeminiSaveTest),
                    ),
                    if (geminiResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          geminiResult!.$2,
                          style: Txt.subhead.copyWith(color: geminiResult!.$1 ? Tokens.success : Tokens.danger),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                      onPressed: () => Bridge.openUrl('https://aistudio.google.com/apikey'),
                      child: Text(l.settingsGeminiGetKey),
                    ),
                  ],
                ),
              ),
            Cell(
              title: l.settingsEngineOnDevice,
              subtitle: Platform.isIOS ? l.settingsEngineOnDeviceIosNote : l.settingsEngineOnDeviceAndroidNote,
              checked: s.engine == 'mlkit',
              onTap: () => change((s) => s.json['engine'] = 'mlkit'),
            ),
          ],
        ),
        GroupFooter(l.settingsEngineFooter),

        // ---------------------------------------------------------------- Altyazı bölgesi
        GroupHeader(l.settingsGroupRegion),
        Glass(
          clip: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preview != null) RegionPreview(image: preview!, settings: s) else _RegionPlaceholder(settings: s),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: edge,
                  backgroundColor: Tokens.inset,
                  thumbColor: const Color(0xFF636366),
                  children: {
                    for (final entry in {
                      'top': l.settingsEdgeTop,
                      'bottom': l.settingsEdgeBottom,
                      'left': l.settingsEdgeLeft,
                      'right': l.settingsEdgeRight,
                    }.entries)
                      entry.key: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(entry.value, style: Txt.subhead.copyWith(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                  },
                  onValueChanged: (value) => setState(() => edge = value ?? edge),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoSlider(
                        value: s.regionValue(edge).clamp(0.0, 1.0),
                        activeColor: Tokens.accent,
                        onChanged: (value) => setRegion(edge, (value * 100).round() / 100),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text('%${(s.regionValue(edge) * 100).round()}', textAlign: TextAlign.end, style: Txt.body.copyWith(color: Tokens.textSecondary)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Cell(title: l.settingsResetDefault, titleColor: Tokens.accent, onTap: () => change((s) => s.json['region'] = Map<String, dynamic>.from(defaultRegion))),
            ],
          ),
        ),
        GroupFooter(l.settingsRegionFooter),

        // ---------------------------------------------------------------- TV'de görünüm
        GroupHeader(l.settingsGroupTvLook),
        Group(
          children: [
            _ControlRow(
              title: l.settingsFontSize,
              child: _Segmented(
                value: '${style['fontSize']}',
                items: {
                  '36': l.settingsFontSmall,
                  '46': l.settingsFontMedium,
                  '58': l.settingsFontLarge,
                  '72': l.settingsFontHuge,
                },
                onChanged: (value) => setStyle('fontSize', int.parse(value)),
              ),
            ),
            _ControlRow(
              title: l.settingsTextColor,
              child: _Segmented(
                value: style['textColor'] as String,
                items: {'white': l.settingsWhite, 'yellow': l.settingsYellow},
                onChanged: (value) => setStyle('textColor', value),
              ),
            ),
            Cell(
              title: l.settingsPlacement,
              subtitle: switch (style['placement'] as String?) {
                'cover' => l.settingsPlacementCover,
                'above' => l.settingsPlacementAbove,
                'below' => l.settingsPlacementBelow,
                'fixed' => l.settingsPlacementFixed,
                _ => '',
              },
              chevron: true,
              onTap: pickPlacement,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l.settingsBackground, style: Txt.body)),
                      Text('%${style['background']}', style: Txt.body.copyWith(color: Tokens.textSecondary)),
                    ],
                  ),
                  CupertinoSlider(
                    value: (style['background'] as num).toDouble().clamp(0, 100),
                    max: 100,
                    divisions: 20,
                    activeColor: Tokens.accent,
                    onChanged: (value) => setStyle('background', value.round()),
                  ),
                ],
              ),
            ),
            Cell(
              title: l.settingsBold,
              trailing: CupertinoSwitch(value: style['bold'] as bool, activeTrackColor: Tokens.success, onChanged: (value) => setStyle('bold', value)),
            ),
            // Bilgisayar sürümündeki "Konuşmacı adı renkli"; TV uygulaması adı ("ENZO:") ayrı renkte yazar.
            if (Platform.isIOS)
              Cell(
                title: l.settingsSpeakerColor,
                subtitle: l.settingsSpeakerColorNote,
                trailing: CupertinoSwitch(
                  value: style['speakerColor'] as bool? ?? false,
                  activeTrackColor: Tokens.success,
                  onChanged: (value) => setStyle('speakerColor', value),
                ),
              ),
            Cell(title: l.settingsSendTest, titleColor: Tokens.accent, onTap: sendTest),
          ],
        ),

        // ---------------------------------------------------------------- TV uygulaması
        GroupHeader(l.settingsGroupTvApp),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.tv_fill,
              iconColor: Tokens.purple,
              title: l.settingsInstallTv,
              subtitle: l.settingsInstallTvNote,
              chevron: true,
              onTap: () => Navigator.of(context).push(appleRoute<void>((_) => const TvInstallPage())),
            ),
          ],
        ),

        // ---------------------------------------------------------------- PS5
        GroupHeader(l.devicePs5),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.gamecontroller_fill,
              iconColor: Tokens.gray,
              title: widget.setup.consoleName ?? l.devicePs5,
              subtitle: widget.setup.consoleHost ?? '',
              trailing: Pill(text: l.settingsPaired, color: Tokens.success),
            ),
            Cell(
              icon: CupertinoIcons.power,
              iconColor: Tokens.success,
              title: l.settingsAutoWake,
              trailing: CupertinoSwitch(
                value: s.autoWake,
                activeTrackColor: Tokens.success,
                onChanged: (value) => change((s) => s.json['autoWake'] = value),
              ),
            ),
          ],
        ),
        GroupFooter(l.settingsAutoWakeFooter),
        const SizedBox(height: 14),
        Group(
          children: [
            Cell(title: l.settingsRepair, titleColor: Tokens.accent, onTap: () => confirmForget(account: false)),
            Cell(title: l.settingsChangeAccount, titleColor: Tokens.danger, onTap: () => confirmForget(account: true)),
          ],
        ),

        // ---------------------------------------------------------------- Hakkında
        GroupHeader(l.settingsGroupAbout),
        Group(
          inset: 60,
          children: [
            Cell(icon: CupertinoIcons.play_circle_fill, iconColor: Tokens.purple, title: l.settingsShowIntro, chevron: true, onTap: showIntro),
            Cell(icon: CupertinoIcons.doc_text_fill, iconColor: Tokens.gray, title: l.settingsLogs, chevron: true, onTap: showLogs),
            Cell(
              icon: CupertinoIcons.info,
              iconColor: Tokens.accent,
              title: l.settingsVersion,
              value: widget.setup.version.isEmpty ? '—' : widget.setup.version,
            ),
          ],
        ),
        GroupFooter(l.settingsAboutFooter),
      ],
    );
  }
}

/// Başlığı üstte, denetimi altında olan satır (parçalı seçiciler için).
class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(title, style: Txt.body), const SizedBox(height: 10), child],
      ),
    );
  }
}

/// iOS'un kayan parçalı seçicisi.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.items, required this.onChanged});

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: items.containsKey(value) ? value : null,
      backgroundColor: Tokens.inset,
      thumbColor: const Color(0xFF636366),
      children: {
        for (final entry in items.entries)
          entry.key: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(entry.value, style: Txt.subhead.copyWith(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w500)),
          ),
      },
      onValueChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

/// Çeviri kapalıyken oyun görüntüsü yoktur; bölge boş bir ekran üstünde gösterilir.
class _RegionPlaceholder extends StatelessWidget {
  const _RegionPlaceholder({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black)),
            Positioned(
              left: 0,
              right: 0,
              top: 18,
              child: Text(AppLocalizations.of(context).settingsRegionPreviewNote,
                  textAlign: TextAlign.center, style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
            ),
            Positioned(
              left: settings.regionValue('left') * constraints.maxWidth,
              top: settings.regionValue('top') * constraints.maxHeight,
              width: (settings.regionValue('right') - settings.regionValue('left')) * constraints.maxWidth,
              height: (settings.regionValue('bottom') - settings.regionValue('top')) * constraints.maxHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Tokens.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                  color: Tokens.accent.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sözlük metnindeki sorun türü; metin arayüz diline göre yazılır.
enum GlossaryProblem { shape, syntax }

/// Terim sözlüğü düzenleyicisi: bilgisayardaki sözlük dosyalarıyla aynı JSON biçimi.
class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key, required this.initial});

  final String initial;

  static const example = '{\n  "terms": {\n    "Leviathan Axe": "Leviathan Baltası"\n  },\n  "keep": ["Kratos", "Atreus"]\n}';

  /// Sözlük metnindeki terim ve korunan ad sayısı; okunamıyorsa üçüncü değer sorunu söyler.
  static (int, int, GlossaryProblem?) inspect(String text) {
    if (text.trim().isEmpty) return (0, 0, null);
    try {
      final root = jsonDecode(text);
      if (root is! Map) return (0, 0, GlossaryProblem.shape);
      final terms = root['terms'] is Map ? (root['terms'] as Map).values.whereType<String>().length : 0;
      final keep = root['keep'] is List ? (root['keep'] as List).whereType<String>().length : 0;
      return (terms, keep, null);
    } on FormatException {
      return (0, 0, GlossaryProblem.syntax);
    }
  }

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (terms, keep, problem) = GlossaryPage.inspect(controller.text);
    final empty = controller.text.trim().isEmpty;
    final problemText = switch (problem) {
      GlossaryProblem.shape => l.settingsGlossaryErrorShape,
      GlossaryProblem.syntax => l.settingsGlossaryErrorSyntax,
      null => null,
    };
    return GlassScaffold(
      title: l.settingsGlossaryTitle,
      actions: [
        TextButton(
          onPressed: problem == null ? () => Navigator.of(context).pop(controller.text.trim()) : null,
          child: Text(l.settingsSave, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.settingsGlossaryHelp, style: Txt.subhead.copyWith(color: Tokens.textSecondary)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 10,
            maxLines: 22,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, height: 1.45),
            decoration: InputDecoration(
              hintText: GlossaryPage.example,
              hintMaxLines: 8,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Tokens.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Tokens.border)),
            ),
          ),
          const SizedBox(height: 12),
          if (problemText != null)
            Notice(icon: CupertinoIcons.exclamationmark_circle_fill, color: Tokens.danger, text: problemText)
          else if (empty)
            Notice(
              icon: CupertinoIcons.wand_stars,
              text: l.settingsGlossaryEmptyNote,
              action: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                onPressed: () => setState(() => controller.text = GlossaryPage.example),
                child: Text(l.settingsGlossaryAddExample),
              ),
            )
          else
            Notice(icon: CupertinoIcons.checkmark_circle_fill, color: Tokens.success, text: l.settingsGlossaryRead(terms, keep)),
          GroupFooter(l.settingsGlossaryFooter),
        ],
      ),
    );
  }
}
