// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'guide_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'tv_install.dart';
import 'ui.dart';

/// TV uygulamasını telefondan kurma sihirbazı: marka → TV'yi bul → geliştirici modu adımları (her ekranda tek iş)
/// → kurulum → TV'de aç. Kurulum Android tarafında yapılır (tvinstall/); bu sayfa yalnız yol gösterir.
class TvInstallPage extends StatefulWidget {
  const TvInstallPage({super.key});

  @override
  State<TvInstallPage> createState() => _TvInstallPageState();
}

enum _Step { brand, samsung, find, guide, install, done }

/// Geliştirici modu adımlarından biri. [check]: adım yapılınca TV'de açılan port (canlı denetim).
class _GuideStep {
  const _GuideStep(this.title, this.body, {this.different, this.check = _Check.none, this.copy});

  final String title;
  final String body;

  /// "Menü farklı görünüyorsa" açıklaması.
  final String? different;
  final _Check check;

  /// Kopyalanabilecek yazı (ör. web adresi).
  final String? copy;
}

enum _Check { none, ready, keyServer }

List<_GuideStep> _androidSteps(AppLocalizations l) => [
  _GuideStep(
    l.tvGuideA1Title,
    l.tvGuideA1Body,
    different: l.tvGuideA1Different,
  ),
  _GuideStep(
    l.tvGuideA2Title,
    l.tvGuideA2Body,
    different: l.tvGuideA2Different,
  ),
  _GuideStep(
    l.tvGuideA3Title,
    l.tvGuideA3Body,
    different: l.tvGuideA3Different,
  ),
  _GuideStep(
    l.tvGuideA4Title,
    l.tvGuideA4Body,
    different: l.tvGuideA4Different,
  ),
  _GuideStep(
    l.tvGuideA5Title,
    l.tvGuideA5Body,
    different: l.tvGuideA5Different,
    check: _Check.ready,
  ),
];

List<_GuideStep> _lgSteps(AppLocalizations l) => [
  _GuideStep(
    l.tvGuideL1Title,
    l.tvGuideL1Body,
    different: l.tvGuideL1Different,
    copy: 'https://webostv.developer.lge.com',
  ),
  _GuideStep(
    l.tvGuideL2Title,
    l.tvGuideL2Body,
    different: l.tvGuideL2Different,
  ),
  _GuideStep(
    l.tvGuideL3Title,
    l.tvGuideL3Body,
    different: l.tvGuideL3Different,
    check: _Check.ready,
  ),
  _GuideStep(
    l.tvGuideL4Title,
    l.tvGuideL4Body,
    different: l.tvGuideL4Different,
    check: _Check.keyServer,
  ),
];

class _TvInstallPageState extends State<TvInstallPage> {
  AppLocalizations get l => AppLocalizations.of(context);

  _Step step = _Step.brand;
  TvKind? kind;
  String? host;
  String tvName = '';
  bool force = false;

  SavedTv? saved;
  Map<TvKind, String> bundled = {};
  String? phone;

  List<FoundTv> found = [];
  bool searching = false;
  bool searched = false;
  final manualController = TextEditingController();
  String? manualError;

  int guideIndex = 0;
  TvCheck? check;
  Timer? poll;
  bool polling = false;

  final passController = TextEditingController();
  bool installing = false;
  String stage = '';
  TvInstallResult? result;
  StreamSubscription<String>? stages;

  @override
  void initState() {
    super.initState();
    stages = TvBridge.stages.listen((value) {
      if (mounted) setState(() => stage = value);
    });
    () async {
      final values = await Future.wait([TvBridge.saved(), TvBridge.bundled(), TvBridge.phoneAddress()]);
      if (!mounted) return;
      setState(() {
        saved = values[0] as SavedTv?;
        bundled = values[1] as Map<TvKind, String>;
        phone = values[2] as String?;
      });
    }();
  }

  @override
  void dispose() {
    poll?.cancel();
    stages?.cancel();
    if (installing || searching) TvBridge.cancel();
    manualController.dispose();
    passController.dispose();
    super.dispose();
  }

  List<_GuideStep> get guideSteps => switch (kind) {
        TvKind.android => _androidSteps(l),
        // Anahtarı kayıtlı TV'de Key Server adımı gerekmez.
        TvKind.lg => check?.hasKey == true ? _lgSteps(l).sublist(0, 3) : _lgSteps(l),
        _ => const [],
      };

  // ------------------------------------------------------------------------------------------- gezinme

  void go(_Step next) {
    poll?.cancel();
    setState(() {
      step = next;
      if (next != _Step.install) result = null;
    });
    if (next == _Step.find) search();
    if (next == _Step.guide) startPolling();
  }

  void chooseBrand(TvKind value) {
    setState(() {
      kind = value;
      host = null;
      found = [];
      searched = false;
      check = null;
      guideIndex = 0;
      force = false;
    });
    go(value == TvKind.samsung ? _Step.samsung : _Step.find);
  }

  /// Kayıtlı TV'ye doğrudan kurulum (güncelleme ya da yeniden kurulum).
  Future<void> reinstallSaved(SavedTv tv) async {
    setState(() {
      kind = tv.kind;
      host = tv.host;
      tvName = tv.name;
      force = true;
      guideIndex = 0;
    });
    final status = await TvBridge.check(tv.kind, tv.host);
    if (!mounted) return;
    setState(() => check = status);
    if (status.ready && (tv.kind != TvKind.lg || status.hasKey)) {
      go(_Step.install);
      install();
    } else {
      go(_Step.guide);
    }
  }

  void back() {
    switch (step) {
      case _Step.brand:
        Navigator.of(context).pop();
      case _Step.samsung || _Step.find:
        go(_Step.brand);
      case _Step.guide:
        if (guideIndex > 0) {
          setState(() => guideIndex--);
          startPolling();
        } else {
          go(_Step.find);
        }
      case _Step.install:
        if (installing) {
          TvBridge.cancel();
          return;
        }
        setState(() => guideIndex = guideSteps.length - 1);
        go(_Step.guide);
      case _Step.done:
        Navigator.of(context).pop();
    }
  }

  // ------------------------------------------------------------------------------------------- arama

  Future<void> search() async {
    final current = kind;
    if (current == null || searching) return;
    setState(() {
      searching = true;
      manualError = null;
    });
    final list = await TvBridge.find(current);
    if (!mounted || kind != current) return;
    setState(() {
      searching = false;
      searched = true;
      found = list;
    });
  }

  Future<void> useManual() async {
    final address = await TvBridge.normalize(manualController.text);
    if (!mounted) return;
    if (address == null) {
      setState(() => manualError = l.tvInstallIpError);
      return;
    }
    FocusScope.of(context).unfocus();
    selectTv(address, kind?.title ?? l.tvInstallBrandFallback);
  }

  Future<void> selectTv(String address, String name) async {
    setState(() {
      host = address;
      tvName = name;
      guideIndex = 0;
      manualError = null;
    });
    final status = await TvBridge.check(kind!, address);
    if (!mounted) return;
    setState(() => check = status);
    // Geliştirici modu zaten açıksa adımlar atlanır.
    if (status.ready && (kind == TvKind.android || status.hasKey)) {
      go(_Step.install);
    } else {
      if (status.ready && kind == TvKind.lg) guideIndex = 3; // yalnız Key Server kaldı
      go(_Step.guide);
    }
  }

  // ------------------------------------------------------------------------------------------- canlı denetim

  void startPolling() {
    poll?.cancel();
    final current = guideSteps.elementAtOrNull(guideIndex);
    if (current == null || current.check == _Check.none) return;
    poll = Timer.periodic(const Duration(seconds: 3), (_) => probe());
    probe();
  }

  Future<void> probe() async {
    final current = kind;
    if (polling || current == null) return;
    polling = true;
    try {
      var address = host;
      if (address == null && current == TvKind.android) {
        // TV hata ayıklama açılmadan ağda görünmez: açılınca burada bulunur.
        final list = await TvBridge.find(current);
        if (list.isNotEmpty) {
          address = list.first.host;
          if (mounted) setState(() => host = address);
        }
      }
      if (address == null) return;
      final status = await TvBridge.check(current, address);
      if (mounted) setState(() => check = status);
    } finally {
      polling = false;
    }
  }

  bool stepDone(_GuideStep s) => switch (s.check) {
        _Check.none => false,
        _Check.ready => check?.ready == true,
        _Check.keyServer => check?.keyServer == true,
      };

  void nextGuide() {
    if (guideIndex + 1 < guideSteps.length) {
      setState(() => guideIndex++);
      startPolling();
    } else {
      go(_Step.install);
    }
  }

  // ------------------------------------------------------------------------------------------- kurulum

  bool get needsPassphrase => kind == TvKind.lg && check?.hasKey != true;

  Future<void> install() async {
    final current = kind;
    final address = host;
    if (current == null || address == null || installing) return;
    final pass = passController.text.trim();
    if (current == TvKind.lg && needsPassphrase && pass.isEmpty) {
      setState(() => result = const TvInstallResult(ok: false, error: 'WRONG_PASSPHRASE', detail: 'parola boş'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      installing = true;
      result = null;
      stage = 'connecting';
    });
    final outcome = await TvBridge.install(current, address, name: tvName, passphrase: needsPassphrase ? pass : null, force: force);
    if (!mounted) return;
    setState(() {
      installing = false;
      result = outcome;
      if (outcome.ok) step = _Step.done;
      // Kayıtlı anahtar geçmediyse parola yeniden sorulur.
      if (outcome.error == 'KEY_REFUSED' || outcome.error == 'WRONG_PASSPHRASE') check = TvCheck(check?.ready ?? false, check?.keyServer ?? false, false);
    });
    if (outcome.ok) TvBridge.saved().then((value) => mounted ? setState(() => saved = value) : null);
  }

  // ------------------------------------------------------------------------------------------- görünüm

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: step == _Step.brand || step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: GlassScaffold(
        title: l.tvInstallTitle,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('$step-$guideIndex'),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: switch (step) {
                _Step.brand => brandView(),
                _Step.samsung => samsungView(),
                _Step.find => findView(),
                _Step.guide => guideView(),
                _Step.install => installView(),
                _Step.done => doneView(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget progress(int index, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsetsDirectional.only(end: 4),
                      decoration: BoxDecoration(
                        color: i <= index ? Tokens.accent : Tokens.surfaceHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.tvInstallStepLabel(index + 1), style: Txt.footnote.copyWith(color: Tokens.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(title, style: Txt.title2),
          ],
        ),
      );

  // ----- 1. marka

  List<Widget> brandView() {
    final tv = saved;
    return [
      progress(0, l.tvInstallBrandQuestion),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Text(l.tvInstallIntroBody, style: Txt.subhead.copyWith(color: Tokens.textSecondary)),
      ),
      if (tv != null) ...[
        GroupHeader(l.tvInstallSavedHeader),
        Group(
          inset: 60,
          children: [
            Cell(
              icon: CupertinoIcons.tv_fill,
              iconColor: Tokens.success,
              title: tv.name.isEmpty ? tv.kind.title : tv.name,
              subtitle: l.tvInstallSavedSubtitle(tv.host, tv.version ?? '?', bundled[tv.kind] ?? '?'),
              trailing: tv.version != null && bundled[tv.kind] != null && _newer(bundled[tv.kind]!, tv.version!)
                  ? Pill(text: l.tvInstallUpdateAvailable, color: Tokens.warning)
                  : null,
            ),
            Cell(
              title: tv.version != null && bundled[tv.kind] != null && _newer(bundled[tv.kind]!, tv.version!) ? l.tvInstallUpdate : l.tvInstallReinstall,
              titleColor: Tokens.accent,
              onTap: () => reinstallSaved(tv),
            ),
          ],
        ),
      ],
      GroupHeader(l.tvInstallBrandHeader),
      Group(
        inset: 60,
        children: [
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.success,
            title: 'Android TV / Google TV',
            subtitle: l.tvInstallBrandAndroidSubtitle,
            chevron: true,
            onTap: () => chooseBrand(TvKind.android),
          ),
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.danger,
            title: 'LG',
            subtitle: l.tvInstallBrandLgSubtitle,
            chevron: true,
            onTap: () => chooseBrand(TvKind.lg),
          ),
          Cell(
            icon: CupertinoIcons.tv,
            iconColor: Tokens.accent,
            title: 'Samsung',
            subtitle: l.tvInstallBrandSamsungSubtitle,
            chevron: true,
            onTap: () => chooseBrand(TvKind.samsung),
          ),
        ],
      ),
      GroupFooter(l.tvInstallBrandFooter),
    ];
  }

  // ----- Samsung: şimdilik bilgisayardan

  List<Widget> samsungView() => [
        progress(0, l.tvInstallSamsungStep),
        Notice(
          icon: CupertinoIcons.desktopcomputer,
          color: Tokens.warning,
          title: l.tvInstallSamsungNoticeTitle,
          text: l.tvInstallSamsungNoticeText,
        ),
        const SizedBox(height: 14),
        SectionCard(
          icon: CupertinoIcons.list_number,
          title: l.tvInstallSamsungStepsTitle,
          children: [
            _Numbered(1, l.tvInstallSamsungStep1),
            _Numbered(2, l.tvInstallSamsungStep2),
            _Numbered(3, l.tvInstallSamsungStep3),
            _Numbered(4, l.tvInstallSamsungStep4),
          ],
        ),
        const SizedBox(height: 16),
        GlowButton(
          icon: CupertinoIcons.book_fill,
          label: l.tvInstallShowDetailed,
          onPressed: () => Navigator.of(context).push(appleRoute<void>((_) => const GuideChapterPage(index: 3))),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => go(_Step.brand), child: Text(l.tvInstallOtherBrand)),
      ];

  // ----- 2. TV'yi bul

  List<Widget> findView() {
    final current = kind!;
    final android = current == TvKind.android;
    return [
      progress(1, l.tvInstallFindStep),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Text(
          android ? l.tvInstallFindBodyAndroid : l.tvInstallFindBodyLg,
          style: Txt.subhead.copyWith(color: Tokens.textSecondary),
        ),
      ),
      GroupHeader(searching ? l.tvInstallSearchingHeader : l.tvInstallFoundHeader),
      Group(
        inset: 60,
        children: [
          if (searching)
            Cell(title: l.tvInstallScanning, trailing: const CupertinoActivityIndicator())
          else if (found.isEmpty)
            Cell(title: searched ? l.tvInstallNotFound : l.tvInstallNotSearched, subtitle: searched ? l.tvInstallNotSearchedNote : null),
          for (final tv in found)
            Cell(
              icon: CupertinoIcons.tv_fill,
              iconColor: tv.ready ? Tokens.success : Tokens.gray,
              title: tv.name,
              subtitle: tv.host,
              trailing: tv.ready ? Pill(text: l.tvInstallReady, color: Tokens.success) : null,
              chevron: true,
              onTap: () => selectTv(tv.host, tv.name),
            ),
          Cell(title: l.tvInstallRefresh, titleColor: Tokens.accent, onTap: searching ? null : search),
        ],
      ),
      GroupHeader(l.tvInstallManualHeader),
      Glass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: manualController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: ipAddressFormatters,
              decoration: InputDecoration(hintText: l.tvInstallIpHint, errorText: manualError),
              onSubmitted: (_) => useManual(),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: useManual, child: Text(l.tvInstallUseAddress)),
          ],
        ),
      ),
      GroupFooter('${android ? l.tvInstallAddressFooterAndroid : l.tvInstallAddressFooterLg}'
          '${phone == null ? '' : ' ${l.tvInstallSameSubnet(phone!)}'}'),
      if (android) ...[
        const SizedBox(height: 16),
        GlowButton(
          label: l.tvInstallShowSteps,
          icon: CupertinoIcons.list_number,
          onPressed: () {
            setState(() => guideIndex = 0);
            go(_Step.guide);
          },
        ),
      ],
    ];
  }

  // ----- 3. geliştirici modu

  List<Widget> guideView() {
    final steps = guideSteps;
    final index = guideIndex.clamp(0, steps.length - 1);
    final s = steps[index];
    final done = stepDone(s);
    final waiting = s.check != _Check.none && !done;
    return [
      progress(2, kind == TvKind.android ? l.tvInstallDebugStep : l.tvInstallDevModeStep),
      Glass(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: done ? Tokens.success : Tokens.accent, shape: BoxShape.circle),
                  child: done
                      ? const Icon(CupertinoIcons.checkmark_alt, size: 20, color: Colors.white)
                      : Text('${index + 1}', style: Txt.headline.copyWith(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s.title, style: Txt.title3)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 46),
              child: Text(l.tvInstallStepCounter(index + 1, steps.length), style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
            ),
            const SizedBox(height: 14),
            Text(s.body, style: Txt.callout),
            if (s.copy != null) ...[
              const SizedBox(height: 12),
              Glass(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: SelectableText(s.copy!, style: Txt.subhead.copyWith(fontWeight: FontWeight.w600))),
                    IconButton(
                      tooltip: l.tvInstallCopy,
                      icon: const Icon(CupertinoIcons.doc_on_clipboard, color: Tokens.accent),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: s.copy!));
                        toast(context, l.tvInstallCopied);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      if (s.check != _Check.none) ...[
        const SizedBox(height: 12),
        done
            ? Notice(
                icon: CupertinoIcons.checkmark_circle_fill,
                color: Tokens.success,
                compact: true,
                text: s.check == _Check.keyServer ? l.tvInstallKeyServerOn : l.tvInstallDeviceReady,
              )
            : Glass(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        host == null ? l.tvInstallSearchingTv : l.tvInstallWaitingTv(host!),
                        style: Txt.subhead.copyWith(color: Tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
      ],
      if (s.different != null) ...[
        const SizedBox(height: 12),
        _Expandable(title: l.tvInstallDifferentMenu, text: s.different!),
      ],
      const SizedBox(height: 18),
      GlowButton(
        label: waiting || index + 1 < steps.length ? l.tvInstallDidIt : l.tvInstallGoInstall,
        icon: CupertinoIcons.checkmark_alt,
        // Canlı denetimde TV henüz görünmüyorsa yine de geçilebilir: bazı ağlar denetimi engeller, kurulum kendisi dener.
        onPressed: (s.check == _Check.ready && host == null && waiting) ? null : nextGuide,
      ),
      if (s.check == _Check.ready && host == null && waiting)
        GroupFooter(l.tvInstallWaitingFooter),
    ];
  }

  // ----- 4. kurulum

  List<Widget> installView() {
    final current = kind!;
    final failure = result != null && !result!.ok ? result : null;
    final text = failure == null ? null : tvErrorText(failure.error, current, l);
    return [
      progress(3, l.tvInstallInstallStep),
      Group(
        inset: 60,
        children: [
          Cell(icon: CupertinoIcons.tv_fill, iconColor: Tokens.purple, title: tvName.isEmpty ? current.title : tvName, subtitle: host),
          Cell(icon: CupertinoIcons.cube_box_fill, iconColor: Tokens.indigo, title: l.tvInstallVersionToInstall, value: bundled[current] ?? '?'),
        ],
      ),
      if (current == TvKind.lg && needsPassphrase) ...[
        GroupHeader(l.tvInstallPassHeader),
        Glass(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: passController,
                enabled: !installing,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                maxLength: 10,
                style: Txt.title2.copyWith(letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: l.tvInstallPassHint, counterText: ''),
                onSubmitted: (_) => install(),
              ),
            ],
          ),
        ),
        GroupFooter(l.tvInstallPassFooter),
      ],
      if (current == TvKind.android && !installing && failure == null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Notice(
            icon: CupertinoIcons.hand_raised_fill,
            title: l.tvInstallApproveTitle,
            text: l.tvInstallApproveText,
          ),
        ),
      if (installing) ...[
        const SizedBox(height: 14),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tvStageText(stage, l), style: Txt.headline)),
                ],
              ),
              if (stage.startsWith('uploading:')) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: (int.tryParse(stage.substring(10)) ?? 0) / 100, borderRadius: BorderRadius.circular(4)),
              ],
            ],
          ),
        ),
        if (stage == 'approve') ...[
          const SizedBox(height: 12),
          Notice(
            icon: CupertinoIcons.tv,
            color: Tokens.warning,
            title: l.tvInstallLookAtTvTitle,
            text: l.tvInstallLookAtTvText,
          ),
        ],
        const SizedBox(height: 10),
        GroupFooter(l.tvInstallKeepScreenOn),
      ],
      if (failure != null) ...[
        const SizedBox(height: 14),
        Notice(icon: CupertinoIcons.exclamationmark_triangle_fill, color: Tokens.danger, title: text!.title, text: text.fix),
        if ((failure.detail ?? '').isNotEmpty && failure.error != 'CANCELLED') ...[
          const SizedBox(height: 10),
          _Expandable(title: l.tvInstallTvSaid, text: failure.detail!),
        ],
      ],
      const SizedBox(height: 18),
      if (installing)
        OutlinedButton(onPressed: TvBridge.cancel, child: Text(l.tvInstallStop))
      else ...[
        GlowButton(
          icon: failure == null ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_clockwise,
          label: failure == null ? l.tvInstallInstallButton : l.tvInstallRetry,
          onPressed: install,
        ),
        if (failure != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              setState(() => guideIndex = failure.error == 'KEY_SERVER_OFF' ? guideSteps.length - 1 : 0);
              go(_Step.guide);
            },
            child: Text(l.tvInstallBackToSteps),
          ),
        ],
      ],
    ];
  }

  // ----- 5. tamam

  List<Widget> doneView() {
    final r = result!;
    return [
      const SizedBox(height: 24),
      const Center(child: Icon(CupertinoIcons.checkmark_seal_fill, size: 84, color: Tokens.success)),
      const SizedBox(height: 16),
      Center(child: Text(r.installed ? l.tvInstallInstalled : l.tvInstallAlreadyCurrent, style: Txt.title2, textAlign: TextAlign.center)),
      const SizedBox(height: 6),
      Center(child: Text(l.tvInstallVersionLabel(r.version ?? '?'), style: Txt.subhead.copyWith(color: Tokens.textSecondary))),
      const SizedBox(height: 22),
      Notice(
        icon: CupertinoIcons.tv_fill,
        color: r.launched ? Tokens.success : Tokens.accent,
        title: r.launched ? l.tvInstallLaunchedTitle : l.tvInstallOpenOnTvTitle,
        text: r.launched ? l.tvInstallLaunchedText : l.tvInstallOpenOnTvText,
      ),
      if (kind == TvKind.lg) ...[
        const SizedBox(height: 12),
        Notice(
          icon: CupertinoIcons.clock_fill,
          color: Tokens.warning,
          title: l.tvInstallLgHoursTitle,
          text: '${r.hoursLeft != null ? '${l.tvInstallHoursLeft(r.hoursLeft!)} ' : ''}${l.tvInstallLgHoursText}',
        ),
      ],
      if (kind == TvKind.android) ...[
        const SizedBox(height: 12),
        Notice(
          icon: CupertinoIcons.info_circle_fill,
          text: l.tvInstallAndroidNote,
        ),
      ],
      const SizedBox(height: 22),
      GlowButton(label: l.tvInstallDone, onPressed: () => Navigator.of(context).pop()),
    ];
  }
}

bool _newer(String a, String b) {
  List<int> parts(String v) => v.split(RegExp(r'[.-]')).map((p) => int.tryParse(p) ?? 0).toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final l = i < x.length ? x[i] : 0, r = i < y.length ? y[i] : 0;
    if (l != r) return l > r;
  }
  return false;
}

class _Numbered extends StatelessWidget {
  const _Numbered(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Tokens.accentSoft, shape: BoxShape.circle),
              child: Text('$number', style: Txt.footnote.copyWith(fontWeight: FontWeight.w700, color: Tokens.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Txt.subhead)),
          ],
        ),
      );
}

/// Dokununca açılan ek açıklama.
class _Expandable extends StatefulWidget {
  const _Expandable({required this.title, required this.text});

  final String title;
  final String text;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool open = false;

  @override
  Widget build(BuildContext context) => Glass(
        radius: 18,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Cell(
              icon: CupertinoIcons.question_circle_fill,
              iconColor: Tokens.gray,
              title: widget.title,
              trailing: Icon(open ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 16, color: Tokens.textSecondary),
              onTap: () => setState(() => open = !open),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SelectableText(widget.text, style: Txt.subhead.copyWith(color: const Color(0xD9EBEBF5))),
              ),
          ],
        ),
      );
}
