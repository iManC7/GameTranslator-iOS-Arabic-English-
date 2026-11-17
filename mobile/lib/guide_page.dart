// SPDX-License-Identifier: AGPL-3.0-only
import 'package:material_ui/material_ui.dart';

import 'bridge.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'tv_install_page.dart';
import 'ui.dart';

/// Ayrıntılı kullanım rehberi: PS5 hazırlığından sorun gidermeye kadar her adım. iOS ayarlarındaki gibi bölüm
/// listesi ve her bölümün kendi sayfası. TV kurulum adımları docs/tv-kurulum.md ile aynıdır.
class GuideChapter {
  const GuideChapter({required this.icon, required this.color, required this.title, required this.subtitle, required this.children});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> children;
}

/// Rehber sekmesi: bölüm listesi.
class GuideTab extends StatelessWidget {
  const GuideTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LargeTitleList(
      title: l.tabGuide,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text(l.guideIntro, style: Txt.body.copyWith(color: Tokens.textSecondary)),
        ),
        const GuideList(),
      ],
    );
  }
}

/// Bölümlerin gruplu listesi; satıra dokununca bölüm sayfası açılır.
class GuideList extends StatelessWidget {
  const GuideList({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chapters = guideChapters(null, l);
    Widget cell(int index) => Cell(
          icon: chapters[index].icon,
          iconColor: chapters[index].color,
          title: chapters[index].title,
          subtitle: chapters[index].subtitle,
          chevron: true,
          onTap: () => Navigator.of(context).push(appleRoute<void>((_) => GuideChapterPage(index: index))),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GroupHeader(l.guideGroupStart),
        Group(inset: 60, children: [for (var i = 0; i < 5; i++) cell(i)]),
        GroupHeader(l.guideGroupUsage),
        Group(inset: 60, children: [for (var i = 5; i < 8; i++) cell(i)]),
        GroupHeader(l.guideGroupHelp),
        Group(inset: 60, children: [cell(8)]),
      ],
    );
  }
}

/// Tek bir bölümün sayfası. Kurulumdaki yardım düğmesi doğrudan ilgili bölümü açar.
class GuideChapterPage extends StatefulWidget {
  const GuideChapterPage({super.key, required this.index});

  final int index;

  @override
  State<GuideChapterPage> createState() => _GuideChapterPageState();
}

class _GuideChapterPageState extends State<GuideChapterPage> {
  String? address;

  @override
  void initState() {
    super.initState();
    Bridge.state().then((state) {
      if (mounted) setState(() => address = state.localAddress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chapters = guideChapters(address, l);
    final chapter = chapters[widget.index];
    final next = widget.index + 1 < chapters.length ? widget.index + 1 : null;
    return GlassScaffold(
      title: l.tabGuide,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                IconTile(chapter.icon, chapter.color, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chapter.title, style: Txt.title2),
                      Text(chapter.subtitle, style: Txt.subhead.copyWith(color: Tokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Glass(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: chapter.children),
          ),
          if (next != null) ...[
            GroupHeader(l.guideNextChapter),
            Group(
              inset: 60,
              children: [
                Cell(
                  icon: chapters[next].icon,
                  iconColor: chapters[next].color,
                  title: chapters[next].title,
                  subtitle: chapters[next].subtitle,
                  chevron: true,
                  onTap: () => Navigator.of(context).pushReplacement(appleRoute<void>((_) => GuideChapterPage(index: next))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bölümlerin içeriği. [address]: telefonun ağ adresi (OBS adresini tam yazmak için); bilinmiyorsa genel yazılır.
List<GuideChapter> guideChapters(String? address, AppLocalizations l) {
  final phone = address ?? l.guidePhoneAddress;
  return [
    GuideChapter(
      icon: CupertinoIcons.arrow_right_arrow_left,
      color: Tokens.accent,
      title: l.gHowTitle,
      subtitle: l.gHowSubtitle,
      children: [
        _P(l.gHowLead),
        _Steps([
          l.gHowStep1,
          l.gHowStep2,
          l.gHowStep3,
        ]),
        _Sub(l.gHowNeedsTitle),
        _Bullets([
          l.gHowNeed1,
          l.gHowNeed2,
          l.gHowNeed3,
          l.gHowNeed4,
        ]),
        _Tip(l.gHowTip),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.gamecontroller_fill,
      color: Tokens.indigo,
      title: l.gPs5Title,
      subtitle: l.gPs5Subtitle,
      children: [
        _Sub(l.gPs5UserTitle),
        _P(l.gPs5UserBody),
        _Steps([
          l.gPs5UserStep1,
          l.gPs5UserStep2,
          l.gPs5UserStep3,
        ]),
        _Sub(l.gPs5RemoteTitle),
        _Steps([
          l.gPs5RemoteStep1,
          l.gPs5RemoteStep2,
          l.gPs5RemoteStep3,
        ]),
        _Sub(l.gPs5WakeTitle),
        _P(l.gPs5WakeBody),
        _Steps([
          l.gPs5WakeStep1,
          l.gPs5WakeStep2,
        ]),
        _Tip(l.gPs5Tip),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.link,
      color: Tokens.success,
      title: l.gPairTitle,
      subtitle: l.gPairSubtitle,
      children: [
        _Sub(l.gPairSignInTitle),
        _Steps([
          l.gPairSignInStep1,
          l.gPairSignInStep2,
          l.gPairSignInStep3,
        ]),
        _Tip(l.gPairSignInTip),
        _Sub(l.gPairCodeTitle),
        _Steps([
          l.gPairCodeStep1,
          l.gPairCodeStep2,
          l.gPairCodeStep3,
          l.gPairCodeStep4,
        ]),
        _Sub(l.gPairMissingTitle),
        _Bullets([
          l.gPairMissing1,
          l.gPairMissing2,
          l.gPairMissing3,
        ]),
        _Tip(l.gPairTip),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.tv_fill,
      color: Tokens.purple,
      title: l.gTvTitle,
      subtitle: l.gTvSubtitle,
      children: [
        _P(l.gTvLead),
        const InstallTvButton(),
        _Sub(l.gTvSupportedTitle),
        _Table([
          (l.gTvTableLg, l.gTvTableLgDetail, true),
          (l.gTvTableSamsung, l.gTvTableSamsungDetail, true),
          (l.gTvTableAndroid, l.gTvTableAndroidDetail, true),
          (l.gTvTableOther, l.gTvTableOtherDetail, false),
        ]),
        _Tip(l.gTvAndroidTip),
        _Sub(l.gTvLgTitle),
        _Steps([
          l.gTvLgStep1,
          l.gTvLgStep2,
          l.gTvLgStep3,
          l.gTvLgStep4,
        ]),
        _P(l.gTvLgNote),
        _Sub(l.gTvSamsungTitle),
        _Steps([
          l.gTvSamsungStep1,
          l.gTvSamsungStep2,
          l.gTvSamsungStep3,
          l.gTvSamsungStep4,
        ]),
        _Sub(l.gTvAndroidTitle),
        _Steps([
          l.gTvAndroidStep1,
          l.gTvAndroidStep2,
          l.gTvAndroidStep3,
          l.gTvAndroidStep4,
        ]),
        _P(l.gTvAndroidNote),
        _Sub(l.gTvAfterTitle),
        _P(l.gTvAfterBody),
        _Sub(l.gTvObsTitle),
        _P(l.gTvObsBody(phone)),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.play_fill,
      color: Tokens.accent,
      title: l.gFirstTitle,
      subtitle: l.gFirstSubtitle,
      children: [
        _Steps([
          l.gFirstStep1,
          l.gFirstStep2,
          l.gFirstStep3,
          l.gFirstStep4,
          l.gFirstStep5,
          l.gFirstStep6,
          l.gFirstStep7,
        ]),
        _Tip(l.gFirstTip),
        _Sub(l.gFirstNextTitle),
        _P(l.gFirstNextBody),
        _Sub(l.gFirstBatteryTitle),
        _P(l.gFirstBatteryBody),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.dot_radiowaves_left_right,
      color: Tokens.gray,
      title: l.gRemoteTitle,
      subtitle: l.gRemoteSubtitle,
      children: [
        _P(l.gRemoteLead),
        _Keys([
          (l.gRemoteOk, l.gRemoteOkText),
          (l.gRemoteLeftRight, l.gRemoteLeftRightText),
          (l.gRemoteNumbers, l.gRemoteNumbersText),
          (l.gRemoteUpDown, l.gRemoteUpDownText),
          (l.gRemoteRed, l.gRemoteRedText),
          (l.gRemoteGreen, l.gRemoteGreenText),
          (l.gRemoteBlue, l.gRemoteBlueText),
          (l.gRemoteBack, l.gRemoteBackText),
        ]),
        _Tip(l.gRemoteTip),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.crop,
      color: Tokens.teal,
      title: l.gRegionTitle,
      subtitle: l.gRegionSubtitle,
      children: [
        _P(l.gRegionBody),
        _Steps([
          l.gRegionStep1,
          l.gRegionStep2,
          l.gRegionStep3,
          l.gRegionStep4,
        ]),
        _Bullets([
          l.gRegionBullet1,
          l.gRegionBullet2,
          l.gRegionBullet3,
        ]),
        _Tip(l.gRegionTip),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.textformat,
      color: Tokens.warning,
      title: l.gLookTitle,
      subtitle: l.gLookSubtitle,
      children: [
        _Sub(l.gEngineTitle),
        _Keys([
          (l.gEngineGoogle, l.gEngineGoogleText),
          (l.gEngineDeepl, l.gEngineDeeplText),
          (l.gEngineOnDevice, l.gEngineOnDeviceText),
        ]),
        _P(l.gEngineFallback),
        _Sub(l.gGlossaryTitle),
        _P(l.gGlossaryBody),
        _Sub(l.gLookOnTvTitle),
        _Bullets([
          l.gLookOnTv1,
          l.gLookOnTv2,
          l.gLookOnTv3,
        ]),
      ],
    ),
    GuideChapter(
      icon: CupertinoIcons.wrench_fill,
      color: Tokens.danger,
      title: l.gTroubleTitle,
      subtitle: l.gTroubleSubtitle,
      children: [
        _Qa(l.gQ1, [
          l.gQ1A1,
          l.gQ1A2,
          l.gQ1A3,
        ]),
        _Qa(l.gQ2, [
          l.gQ2A1,
          l.gQ2A2,
        ]),
        _Qa(l.gQ3, [l.gQ3A1]),
        _Qa(l.gQ4, [
          l.gQ4A1,
          l.gQ4A2,
          l.gQ4A3,
          l.gQ4A4,
        ]),
        _Sub(l.gTvNotFoundTitle),
        ...tvRecoverySteps(l),
        _Qa(l.gQ5, [
          l.gQ5A1,
          l.gQ5A2,
        ]),
        _Qa(l.gQ6, [
          l.gQ6A1,
          l.gQ6A2,
          l.gQ6A3,
          l.gQ6A4,
        ]),
        _Qa(l.gQ7, [
          l.gQ7A1,
          l.gQ7A2,
          l.gQ7A3,
        ]),
        _Qa(l.gQ8, [
          l.gQ8A1,
          l.gQ8A2,
        ]),
        _Qa(l.gQ9, [
          l.gQ9A1,
          l.gQ9A2,
        ]),
        _Tip(l.gTroubleTip),
      ],
    ),
  ];
}

/// Paragraf.
class _P extends StatelessWidget {
  const _P(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: const TextStyle(color: Tokens.textSecondary, fontSize: 15.5, height: 1.45, letterSpacing: -0.2)),
      );
}

/// Bölüm içi ara başlık.
class _Sub extends StatelessWidget {
  const _Sub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Text(text, style: Txt.headline),
      );
}

/// Numaralı adımlar.
class _Steps extends StatelessWidget {
  const _Steps(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Tokens.accentSoft, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(color: Tokens.accentText, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(items[i], style: const TextStyle(fontSize: 15.5, height: 1.42, letterSpacing: -0.2)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sırasız liste.
class _Bullets extends StatelessWidget {
  const _Bullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 8, start: 9, end: 12),
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Tokens.accentText, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(item, style: const TextStyle(color: Tokens.textSecondary, fontSize: 15.5, height: 1.42, letterSpacing: -0.2))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// İpucu kutusu.
class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Notice(icon: CupertinoIcons.lightbulb_fill, text: text),
      );
}

/// Ad ve açıklama çiftleri: kumanda tuşları, çeviri motorları.
class _Keys extends StatelessWidget {
  const _Keys(this.items);

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          for (final (name, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 104,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Tokens.inset,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Tokens.border),
                    ),
                    child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(text, style: const TextStyle(color: Tokens.textSecondary, fontSize: 14, height: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Desteklenen TV'ler: marka, ayrıntı ve destek durumu.
class _Table extends StatelessWidget {
  const _Table(this.rows);

  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(color: Tokens.inset, borderRadius: BorderRadius.circular(16), border: Border.all(color: Tokens.border, width: 0.8)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rows[i].$3 ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                      size: 20,
                      color: rows[i].$3 ? Tokens.success : Tokens.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(rows[i].$2, style: const TextStyle(color: Tokens.textSecondary, fontSize: 13.5, height: 1.35)),
                          if (!rows[i].$3)
                            Text(l.gTvNotSupported, style: const TextStyle(color: Tokens.danger, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sorun ve denenecekler.
class _Qa extends StatelessWidget {
  const _Qa(this.question, this.answers);

  final String question;
  final List<String> answers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: 2, end: 10),
                child: Icon(CupertinoIcons.question_circle_fill, size: 18, color: Tokens.warning),
              ),
              Expanded(child: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35))),
            ],
          ),
          _Bullets(answers),
        ],
      ),
    );
  }
}

/// TV uygulaması eski bir adrese (ör. kapalı bilgisayara) takılı kaldığında yapılacaklar. Sorun gidermede ve
/// ana ekrandaki uyarıdan açılan sayfada aynı metin kullanılır.
List<Widget> tvRecoverySteps(AppLocalizations l) => [
      _P(l.gRecoveryLead),
      _Sub(l.gRecoveryAndroidTitle),
      _Steps([
        l.gRecoveryAndroidStep1,
        l.gRecoveryAndroidStep2,
        l.gRecoveryAndroidStep3,
        l.gRecoveryAndroidStep4,
      ]),
      _Sub(l.gRecoverySamsungTitle),
      _Steps([
        l.gRecoverySamsungStep1,
        l.gRecoverySamsungStep2,
        l.gRecoverySamsungStep3,
      ]),
      _Sub(l.gRecoveryStillTitle),
      _Bullets([
        l.gRecoveryStill1,
        l.gRecoveryStill2,
        l.gRecoveryStill3,
      ]),
    ];

/// Ana ekrandaki "TV hâlâ bağlanmadı" uyarısından açılan yardım sayfası.
class TvHelpPage extends StatelessWidget {
  const TvHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassScaffold(
      title: l.guideTvHelpTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Glass(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: tvRecoverySteps(l)),
          ),
        ],
      ),
    );
  }
}

/// Rehberdeki "TV uygulamasını kur" düğmesi: telefondan kurulum sihirbazını açar.
class InstallTvButton extends StatelessWidget {
  const InstallTvButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: GlowButton(
          icon: CupertinoIcons.tv_fill,
          label: AppLocalizations.of(context).homeInstallTvTitle,
          onPressed: () => Navigator.of(context).push(appleRoute<void>((_) => const TvInstallPage())),
        ),
      );
}
