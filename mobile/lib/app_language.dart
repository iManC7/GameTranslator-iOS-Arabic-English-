// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/widgets.dart';

import 'bridge.dart';

/// Arayüz dili (`uiLanguage` ayarı). Değişince [MaterialApp] yeni yerelle kurulur.
///
/// Kayıtlı değer [auto] ise cihazın dili izlenir: desteklenen ilk cihaz dili,
/// yoksa [fallback] (İngilizce).
class AppLanguage {
  AppLanguage._();

  /// Desteklenen arayüz dilleri; `lib/l10n/app_<kod>.arb` dosyalarıyla aynı olmalı.
  static const supported = ['tr', 'en', 'ar'];

  /// "Cihaz dili": kayıtlı değer bu ise cihazın diline uyulur.
  static const auto = 'auto';

  /// Aygıtın dili desteklenmiyorsa kullanılan dil.
  static const fallback = 'en';

  /// Ekranda kullanılan (çözülmüş) dil.
  static final ValueNotifier<String> current = ValueNotifier<String>(fallback);

  /// Kullanıcının tercihi: [auto] ya da desteklenen bir kod.
  static String stored = auto;

  static bool isSupported(String code) => supported.contains(code);

  /// Cihazın desteklenen ilk dili; yoksa [fallback] (İngilizce).
  static String deviceLanguage() {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      final code = locale.languageCode.toLowerCase();
      if (isSupported(code)) return code;
    }
    return fallback;
  }

  /// Tercihi gerçek dile çevirir: [auto] ise cihaz dili.
  static String resolve(String code) => isSupported(code) ? code : deviceLanguage();

  /// Açılışta kayıtlı tercihi okur; kanal yoksa (test, web) cihaz dili kullanılır.
  static Future<void> load() async {
    try {
      final code = (await Bridge.settings()).uiLanguage;
      stored = code == auto ? auto : (isSupported(code) ? code : auto);
    } catch (_) {
      stored = auto;
    }
    current.value = resolve(stored);
    // Otomatik moddayken cihaz dili değişirse uygula.
    WidgetsBinding.instance.platformDispatcher.onLocaleChanged = () {
      if (stored == auto) current.value = deviceLanguage();
    };
  }

  /// Dili hemen uygular ve ayarlara yazar. [auto] cihaz dilini izler.
  static Future<void> set(String code) async {
    if (code != auto && !isSupported(code)) return;
    stored = code;
    current.value = resolve(code);
    try {
      final settings = await Bridge.settings();
      settings.json['uiLanguage'] = code;
      await Bridge.saveSettings(settings);
    } catch (_) {
      // Kaydedilemezse seçim bu oturum için geçerli kalır.
    }
  }
}
