// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'bridge.dart';
import 'home_page.dart';
import 'intro_page.dart';
import 'setup_page.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const GameTranslatorApp());
}

/// Apple'ın tasarım dili (iOS, koyu görünüm, Liquid Glass): sistem renkleri, cam yüzeyler, büyük başlıklar.
/// Renk değerleri iOS'un koyu görünümdeki sistem renkleridir.
class Tokens {
  /// Zeminin taban rengi; ışık lekeleri [GlassBackground] ile bunun üstüne çizilir.
  static const background = Color(0xFF05070D);

  /// Cam yüzey: zemini gösteren yarı saydam beyaz. Kartlarda düz renk yerine [glassFill] kullanılır.
  static const surface = Color(0x1AFFFFFF);
  static const surfaceHigh = Color(0x29FFFFFF);

  /// Camın kenarı ve satır ayraçları (iOS'ta "separator").
  static const border = Color(0x2EFFFFFF);
  static const separator = Color(0x24FFFFFF);

  /// Camın içine gömülü alanlar (metin kutuları, kaydırmalı seçiciler).
  static const inset = Color(0x33000000);

  /// Açılır pencereler ve menüler: altındaki yazıyla karışmasın diye neredeyse opak koyu cam.
  static const sheet = Color(0xF21C1C1E);

  /// iOS "label" ve "secondaryLabel".
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99EBEBF5);

  /// iOS sistem renkleri (koyu görünüm).
  static const accent = Color(0xFF0A84FF);
  static const accentText = Color(0xFF0A84FF);
  static const accentSoft = Color(0x400A84FF);
  static const glow = Color(0xFF64D2FF);
  static const success = Color(0xFF30D158);
  static const warning = Color(0xFFFF9F0A);
  static const danger = Color(0xFFFF453A);
  static const purple = Color(0xFFBF5AF2);
  static const indigo = Color(0xFF5E5CE6);
  static const teal = Color(0xFF40C8E0);
  static const gray = Color(0xFF8E8E93);

  /// Cam kartların dolgusu: sol üstte ışık alan, sağ alta doğru saydamlaşan beyaz.
  static const glassFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2BFFFFFF), Color(0x12FFFFFF)],
  );
}

/// iOS yazı ölçeği (Dynamic Type "Large"). Yazı tipi Inter'dir: SF Pro'ya en yakın açık lisanslı yazı tipi.
class Txt {
  static const largeTitle = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.15);
  static const title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.18);
  static const title2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25);
  static const title3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.25);
  static const headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3);
  static const body = TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.3, height: 1.3);
  static const callout = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.32);
  static const subhead = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.2, height: 1.35);
  static const footnote = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.05, height: 1.38);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35);
}

class GameTranslatorApp extends StatelessWidget {
  const GameTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Tokens.accent, brightness: Brightness.dark).copyWith(
      primary: Tokens.accent,
      onPrimary: Colors.white,
      secondary: Tokens.accent,
      surface: Tokens.background,
      onSurface: Tokens.textPrimary,
      onSurfaceVariant: Tokens.textSecondary,
      surfaceContainerLowest: Tokens.background,
      surfaceContainerLow: Tokens.sheet,
      surfaceContainer: Tokens.sheet,
      surfaceContainerHigh: Tokens.sheet,
      surfaceContainerHighest: Tokens.sheet,
      outline: Tokens.border,
      outlineVariant: Tokens.separator,
      error: Tokens.danger,
    );
    const capsule = StadiumBorder();
    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: width));
    return MaterialApp(
      title: 'GameTranslator',
      debugShowCheckedModeBanner: false,
      // iOS'taki gibi esneyen kaydırma. Sayfalar appleRoute ile (sağdan kayarak) açılır.
      scrollBehavior: const _AppleScroll(),
      theme: ThemeData(
        colorScheme: scheme,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Tokens.background,
        splashFactory: NoSplash.splashFactory,
        highlightColor: const Color(0x1FFFFFFF),
        textTheme: const TextTheme(bodyMedium: Txt.body, bodyLarge: Txt.body, titleMedium: Txt.body),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Tokens.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Tokens.textPrimary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: capsule,
            backgroundColor: Tokens.accent,
            foregroundColor: Colors.white,
            textStyle: Txt.headline.copyWith(fontFamily: 'Inter'),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            backgroundColor: Tokens.surface,
            shape: capsule,
            textStyle: Txt.headline.copyWith(fontFamily: 'Inter'),
            foregroundColor: Tokens.textPrimary,
            side: const BorderSide(color: Tokens.border),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Tokens.accent, textStyle: Txt.body.copyWith(fontFamily: 'Inter')),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Tokens.inset,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: const TextStyle(color: Tokens.textSecondary),
          hintStyle: const TextStyle(color: Color(0x4DEBEBF5)),
          helperStyle: Txt.footnote.copyWith(color: Tokens.textSecondary),
          border: field(Tokens.border),
          enabledBorder: field(Tokens.border),
          focusedBorder: field(Tokens.accent, 1.5),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Tokens.sheet,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Tokens.sheet,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          dragHandleColor: Color(0x4DEBEBF5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Tokens.sheet,
          contentTextStyle: Txt.subhead.copyWith(fontFamily: 'Inter', color: Tokens.textPrimary),
          shape: const StadiumBorder(side: BorderSide(color: Tokens.border)),
        ),
        dividerTheme: const DividerThemeData(color: Tokens.separator, thickness: 0.6, space: 0.6),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: Tokens.accent),
      ),
      home: const RootPage(),
    );
  }
}

/// Her platformda iOS'un esneyen kaydırması; kenar parlaması (Android) gösterilmez.
class _AppleScroll extends MaterialScrollBehavior {
  const _AppleScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// İlk açılışta tanıtım, sonra kurulum (PSN girişi ve PS5 eşleştirmesi), hepsi tamamsa ana ekran.
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  SetupInfo? setup;
  late final AppLifecycleListener lifecycle;

  /// Açılış animasyonu bitti mi? Kayıtlar daha erken okunsa da animasyon yarıda kesilmez.
  bool splashDone = false;

  @override
  void initState() {
    super.initState();
    // Uygulamaya dönüldüğünde kayıtlar yeniden okunur (eşleştirme arka planda değişmiş olabilir).
    lifecycle = AppLifecycleListener(onResume: reload);
    reload();
    Future<void>.delayed(SplashView.minimum, () {
      if (mounted) setState(() => splashDone = true);
    });
  }

  @override
  void dispose() {
    lifecycle.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final info = await Bridge.setup();
    if (mounted) setState(() => setup = info);
  }

  Future<void> finishIntro() async {
    await Bridge.setIntroSeen(true);
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    final info = setup;
    final Widget page;
    if (info == null || !splashDone) {
      page = const SplashView(key: ValueKey('splash'));
    } else if (!info.ready && !info.introSeen) {
      page = IntroPage(key: const ValueKey('intro'), onDone: finishIntro);
    } else if (!info.ready) {
      page = SetupPage(key: const ValueKey('setup'), setup: info, onChanged: reload);
    } else {
      page = HomePage(key: const ValueKey('home'), setup: info, onSetupChanged: reload);
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 420), child: page);
  }
}
