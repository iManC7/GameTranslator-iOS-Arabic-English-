// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslator_mobile/app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kayıtlı dil destekleniyorsa o kullanılır', () {
    expect(AppLanguage.resolve('tr'), 'tr');
    expect(AppLanguage.resolve('en'), 'en');
    expect(AppLanguage.resolve('ar'), 'ar');
  });

  test('desteklenmeyen kod cihaz diline düşer', () {
    expect(AppLanguage.isSupported(AppLanguage.resolve('de')), isTrue);
    expect(AppLanguage.resolve(''), AppLanguage.deviceLanguage());
  });

  test('auto cihaz dilini izler', () {
    expect(AppLanguage.resolve(AppLanguage.auto), AppLanguage.deviceLanguage());
  });

  test('cihaz dili desteklenenlerden biri ya da yedek dil', () {
    expect(AppLanguage.supported.contains(AppLanguage.deviceLanguage()) || AppLanguage.deviceLanguage() == AppLanguage.fallback, isTrue);
  });
}
