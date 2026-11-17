// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:ui' show ImageFilter;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoDialogAction,
        CupertinoIcons,
        CupertinoPageRoute,
        showCupertinoDialog,
        showCupertinoModalPopup;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'main.dart';

export 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoActivityIndicator, CupertinoIcons, CupertinoSlider, CupertinoSlidingSegmentedControl, CupertinoSwitch;

export 'flow.dart';

/// Ekranlar arasında ortak kullanılan parçalar: Apple'ın tasarım dilindeki (iOS, Liquid Glass) yüzeyler,
/// gruplu listeler, başlıklar, düğmeler ve pencereler.

// ---------------------------------------------------------------------------------------------- zemin ve cam

/// Bütün ekranların arkasındaki zemin: koyu taban üstünde yumuşak, renkli ışık lekeleri. Cam yüzeyler bu
/// ışığı geçirdiği için derinlik duygusu verir. Bulanıklık filtresi kullanılmaz; lekeler geçişli boyanır.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _BackgroundPainter(), size: Size.infinite));
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = Tokens.background);
    void blob(double x, double y, double radius, Color color) {
      final center = Offset(size.width * x, size.height * y);
      final r = size.width * radius;
      canvas.drawCircle(
        center,
        r,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    blob(0.00, 0.22, 1.00, const Color(0x660A84FF)); // mavi, sol üst
    blob(1.05, 0.50, 0.90, const Color(0x4D5E5CE6)); // çivit, sağ orta
    blob(0.25, 1.00, 0.95, const Color(0x4032ADE6)); // camgöbeği, sol alt
    blob(0.95, 0.05, 0.60, const Color(0x33BF5AF2)); // mor, sağ üst
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => false;
}

/// Cam yüzey: yarı saydam, sol üstten ışık alan dolgu ve ince parlak kenar.
/// [tint] camı renklendirir (seçili ya da etkin öğeler). [blur] yalnızca altında görüntü ya da kayan içerik olan
/// yüzeylerde açılır: arkasını gerçekten bulandırır ama pahalıdır.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.radius = 26, this.padding, this.tint, this.blur = false, this.clip = false});

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final bool blur;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final color = tint;
    Widget surface = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: color == null
            ? Tokens.glassFill
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.40), color.withValues(alpha: 0.18)],
              ),
        border: Border.all(color: color == null ? Tokens.border : color.withValues(alpha: 0.55), width: 0.8),
      ),
      child: clip ? ClipRRect(borderRadius: BorderRadius.circular(radius - 1), child: child) : child,
    );
    if (blur) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: surface),
      );
    }
    return surface;
  }
}

// ---------------------------------------------------------------------------------------------- sayfa iskeletleri

/// Geri düğmeli alt sayfa (iOS gezinme çubuğu): solda cam daire içinde geri oku, ortada başlık.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({super.key, this.appBar, required this.body, this.title, this.actions});

  /// Hazır bir başlık çubuğu; verilmezse ve [title] varsa iOS tarzı çubuk kurulur.
  final PreferredSizeWidget? appBar;
  final String? title;
  final List<Widget>? actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final bar = appBar ?? (title == null ? null : navBar(context, title!, actions: actions));
    return Stack(
      fit: StackFit.expand,
      children: [
        const GlassBackground(),
        Scaffold(backgroundColor: Colors.transparent, appBar: bar, body: bar == null ? body : SafeArea(top: false, child: body)),
      ],
    );
  }

  static PreferredSizeWidget navBar(BuildContext context, String title, {List<Widget>? actions, PreferredSizeWidget? bottom}) {
    return AppBar(
      toolbarHeight: 52,
      leadingWidth: 64,
      automaticallyImplyLeading: false,
      leading: Navigator.of(context).canPop() ? const Center(child: GlassBackButton()) : null,
      title: Text(title),
      actions: actions == null ? null : [...actions, const SizedBox(width: 8)],
      bottom: bottom,
    );
  }
}

class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key});

  @override
  Widget build(BuildContext context) => GlassIconButton(
        icon: CupertinoIcons.chevron_back,
        tooltip: 'Geri',
        onTap: () => Navigator.of(context).maybePop(),
      );
}

/// Cam daire içinde ikon düğmesi (başlık çubuklarında).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.tooltip, this.size = 40});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Tokens.surface,
        shape: const CircleBorder(side: BorderSide(color: Tokens.border, width: 0.8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: Tokens.textPrimary)),
        ),
      ),
    );
  }
}

/// Sekme sayfası: iOS'taki gibi sola yaslı büyük başlık ve altında kayan içerik. Alt boşluk, yüzen sekme
/// çubuğunun altında içerik kalmasın diye bırakılır.
class LargeTitleList extends StatelessWidget {
  const LargeTitleList({super.key, required this.title, required this.children, this.trailing, this.bottomSpace = 118});

  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, top + 14, 16, bottomSpace),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 14),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: Txt.largeTitle)),
                  ?trailing,
                ],
              ),
            ),
            ...children,
          ],
        ),
        // Saat ve pil satırının arkası: içerik buradan geçerken bulanır, yazılarla karışmaz.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: const ColoredBox(color: Color(0x33000000)),
            ),
          ),
        ),
      ],
    );
  }
}

/// iOS 26'nın yüzen cam sekme çubuğu: ekranın altında, içeriğin üstünde duran hap. Seçili sekme daha parlak
/// bir cam kapsülle ve mavi ikonla gösterilir. Altından içerik kaydığı için arkasını gerçekten bulandırır.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.items, required this.index, required this.onTap});

  final List<(IconData, IconData, String)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x40FFFFFF), Color(0x1FFFFFFF)],
            ),
            border: Border.all(color: const Color(0x40FFFFFF), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 96,
                    decoration: BoxDecoration(
                      color: i == index ? const Color(0x38FFFFFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(i == index ? items[i].$2 : items[i].$1, size: 24, color: i == index ? Tokens.accent : Tokens.textPrimary),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: i == index ? Tokens.accent : Tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------- gruplu listeler

/// Grup başlığı: iOS ayarlarındaki küçük, gri bölüm adı.
class GroupHeader extends StatelessWidget {
  const GroupHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
        child: Text(text, style: Txt.footnote.copyWith(color: Tokens.textSecondary, fontWeight: FontWeight.w500)),
      );
}

/// Grup altı açıklaması.
class GroupFooter extends StatelessWidget {
  const GroupFooter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Text(text, style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
      );
}

/// iOS'un gruplu (inset grouped) listesi: cam bir kutu içinde, ince çizgilerle ayrılmış satırlar.
class Group extends StatelessWidget {
  const Group({super.key, required this.children, this.inset = 16});

  final List<Widget> children;

  /// Ayraç çizgisinin soldan boşluğu: ikonlu satırlarda yazıyla hizalanır.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Glass(
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Padding(padding: EdgeInsets.only(left: inset), child: const Divider()),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Renkli, yuvarlak köşeli kare içinde beyaz ikon: iOS ayarlarındaki satır ikonları.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, this.color, {super.key, this.size = 30});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.24)),
      child: Icon(icon, size: size * 0.6, color: Colors.white),
    );
  }
}

/// Liste satırı: solda ikon, başlık (ve alt yazı), sağda değer, ok ya da bir denetim.
class Cell extends StatelessWidget {
  const Cell({
    super.key,
    this.icon,
    this.iconColor = Tokens.accent,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.titleColor,
    this.checked,
  });

  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  /// Sağdaki gri değer yazısı.
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final Color? titleColor;

  /// Seçim listelerinde: true ise sağda mavi onay işareti (false ise yer tutulur).
  final bool? checked;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.fromLTRB(16, subtitle == null ? 12 : 10, 14, subtitle == null ? 12 : 10),
      child: Row(
        children: [
          if (icon != null) ...[IconTile(icon!, iconColor), const SizedBox(width: 14)],
          Flexible(
            flex: value == null ? 1 : 0,
            fit: value == null ? FlexFit.tight : FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Txt.body.copyWith(color: titleColor)),
                if (subtitle != null) Text(subtitle!, style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: Txt.body.copyWith(color: Tokens.textSecondary)),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (checked != null) ...[
            const SizedBox(width: 10),
            Icon(CupertinoIcons.checkmark_alt, size: 22, color: checked! ? Tokens.accent : Colors.transparent),
          ],
          if (chevron) ...[
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_forward, size: 15, color: Color(0x4DEBEBF5)),
          ],
        ],
      ),
    );
    if (onTap == null) return ConstrainedBox(constraints: const BoxConstraints(minHeight: 46), child: row);
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 46), child: row)),
    );
  }
}

// ---------------------------------------------------------------------------------------------- düğmeler ve etiketler

/// Ana eylem düğmesi: mavi, hap biçimli (iOS'un belirgin düğmesi).
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.onPressed, required this.label, this.icon, this.busy = false});

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(disabledBackgroundColor: Tokens.accent.withValues(alpha: 0.5), disabledForegroundColor: Colors.white70),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else if (icon != null)
              Icon(icon, size: 20),
            if (busy || icon != null) const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Renkli kenarlı bilgi kutusu: ipucu, uyarı ya da hata.
class Notice extends StatelessWidget {
  const Notice({super.key, required this.icon, required this.text, this.color = Tokens.accent, this.title, this.action, this.compact = false});

  final IconData icon;
  final String text;
  final String? title;
  final Color color;
  final Widget? action;

  /// Daha az iç boşluk ve rengiyle yazı; tek satırlık onay mesajları için.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      tint: color,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: Txt.subhead.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                ],
                Text(
                  text,
                  style: Txt.footnote.copyWith(
                    fontSize: 13.5,
                    color: compact ? color : const Color(0xD9EBEBF5),
                    fontWeight: compact ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 4), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Küçük, yuvarlak köşeli durum etiketi.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, this.color = Tokens.textSecondary, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
          Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Başlıklı cam kart (rehberdeki ve ana ekrandaki bölümler).
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.icon, this.title, this.subtitle, this.trailing, required this.children, this.padding = const EdgeInsets.all(18)});

  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Row(
                children: [
                  if (icon != null) ...[IconTile(icon!, Tokens.accent, size: 34), const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: Txt.title3),
                        if (subtitle != null) Text(subtitle!, style: Txt.footnote.copyWith(color: Tokens.textSecondary)),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            if (title != null && children.isNotEmpty) const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------- pencereler

/// iOS geçişiyle (sağdan kayarak, kenardan geri çekilebilir) sayfa açar.
Route<T> appleRoute<T>(WidgetBuilder builder) => CupertinoPageRoute<T>(builder: builder);

/// Alttan açılan seçim listesi (iOS eylem sayfası). Seçilen anahtarı döner; vazgeçilirse null.
Future<String?> showApplePicker(BuildContext context, {required String title, required Map<String, String> options, String? selected, Map<String, String>? leading}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final entry in options.entries)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(entry.key),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading?[entry.key] != null) ...[Text(leading![entry.key]!, style: const TextStyle(fontSize: 20)), const SizedBox(width: 10)],
                Flexible(
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: entry.key == selected ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                if (entry.key == selected) ...[const SizedBox(width: 8), const Icon(CupertinoIcons.checkmark_alt, size: 20)],
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Vazgeç', style: TextStyle(fontFamily: 'Inter')),
      ),
    ),
  );
}

/// iOS uyarı penceresi; onaylanırsa true döner.
Future<bool> confirmApple(BuildContext context, {required String title, required String message, required String action, bool destructive = false}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title, style: const TextStyle(fontFamily: 'Inter')),
      content: Padding(padding: const EdgeInsets.only(top: 4), child: Text(message, style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.35))),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç', style: TextStyle(fontFamily: 'Inter'))),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action, style: const TextStyle(fontFamily: 'Inter')),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Ekranın altında kısa süre görünen bildirim.
void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, textAlign: TextAlign.center),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 96),
      duration: const Duration(seconds: 3),
    ));
}

// ---------------------------------------------------------------------------------------------- logo ve açılış

/// Uygulama simgesi; iOS simgeleri gibi yumuşak köşeli ve hafif gölgeli.
class GtLogo extends StatelessWidget {
  const GtLogo({super.key, this.size = 96, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: glow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.23),
              boxShadow: [BoxShadow(color: Tokens.accent.withValues(alpha: 0.35), blurRadius: size * 0.5, offset: Offset(0, size * 0.08))],
            )
          : null,
      child: Image.asset('assets/logo.png', width: size, height: size, filterQuality: FilterQuality.medium),
    );
  }
}

/// Açılış ekranı. Sistemin açılış ekranındaki simgeyle aynı yerde başlar; simgenin etrafında ışık halkaları
/// yayılır, altında ad ve slogan belirir. Kayıtlar okunurken ve kısa bir süre boyunca gösterilir.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  /// Animasyonun tamamlanması için gereken en kısa süre.
  static const minimum = Duration(milliseconds: 1900);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController rings = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    intro.dispose();
    rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = CurvedAnimation(parent: intro, curve: const Interval(0, 0.5, curve: Curves.easeOutBack));
    final name = CurvedAnimation(parent: intro, curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic));
    final tagline = CurvedAnimation(parent: intro, curve: const Interval(0.55, 1, curve: Curves.easeOutCubic));
    return GlassScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: rings,
                    builder: (context, _) => CustomPaint(size: const Size(260, 260), painter: _RingsPainter(rings.value, intro.value)),
                  ),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(logo),
                    child: const GtLogo(size: 124),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: name,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(name),
                child: const Text('GameTranslator', style: Txt.largeTitle),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: tagline,
              child: Text('Oyunu kendi dilinde oyna', style: Txt.body.copyWith(color: Tokens.textSecondary)),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

/// Logonun etrafında dışa doğru yayılıp sönen ışık halkaları.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.phase, this.strength);

  final double phase;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final t = (phase + i / 3) % 1;
      final radius = 62 + 66 * t;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1 - t) + 0.5
          ..color = Colors.white.withValues(alpha: (1 - t) * 0.35 * strength),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.phase != phase || old.strength != strength;
}

/// IP adresi alanları için: Türkçe sayı klavyesinde nokta yerine virgül çıkar; yazılan virgül noktaya çevrilir.
const ipAddressFormatters = <TextInputFormatter>[_CommaToDot()];

class _CommaToDot extends TextInputFormatter {
  const _CommaToDot();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.text.contains(',') ? newValue.copyWith(text: newValue.text.replaceAll(',', '.')) : newValue;
}
