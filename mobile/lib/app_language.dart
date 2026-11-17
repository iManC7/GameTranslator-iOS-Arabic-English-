// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/widgets.dart';

import 'bridge.dart';

/// Arayüz dili (`uiLanguage` ayarı). Değişince [MaterialApp] yeni yerelle kurulur.
class AppLanguage {
  AppLanguage._();

  /// Desteklenen arayüz dilleri; `lib/l10n/app_<kod>.arb` dosyalarıyla aynı olmalı.
  static const supported = ['tr', 'en', 'ar'];

  /// Ayar yoksa/geçersizse kullanılan dil.
  static const fallback = 'tr';

  static final ValueNotifier<String> current = ValueNotifier<String>(fallback);

  static bool isSupported(String code) => supported.contains(code);

  /// Açılışta kayıtlı dili okur; kanal yoksa (test, web) varsayılan kalır.
  static Future<void> load() async {
    try {
      final code = (await Bridge.settings()).uiLanguage;
      current.value = isSupported(code) ? code : fallback;
    } catch (_) {
      current.value = fallback;
    }
  }

  /// Dili hemen uygular ve ayarlara yazar.
  static Future<void> set(String code) async {
    if (!isSupported(code)) return;
    current.value = code;
    try {
      final settings = await Bridge.settings();
      settings.json['uiLanguage'] = code;
      await Bridge.saveSettings(settings);
    } catch (_) {
      // Kaydedilemezse seçim bu oturum için geçerli kalır.
    }
  }
}
