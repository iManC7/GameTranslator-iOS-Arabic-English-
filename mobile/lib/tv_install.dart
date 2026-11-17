// SPDX-License-Identifier: AGPL-3.0-only
// Telefondan TV uygulaması kurma: Android tarafındaki tvinstall/TvInstallChannel ile konuşan köprü ve hata metinleri.
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

enum TvKind { lg, samsung, android }

extension TvKindText on TvKind {
  String get id => name;

  String get title => switch (this) {
        TvKind.lg => 'LG',
        TvKind.samsung => 'Samsung',
        TvKind.android => 'Android TV / Google TV',
      };
}

TvKind? tvKindOf(String? id) => switch (id) {
      'lg' => TvKind.lg,
      'samsung' => TvKind.samsung,
      'android' => TvKind.android,
      _ => null,
    };

class FoundTv {
  const FoundTv(this.kind, this.host, this.name, this.ready);

  final TvKind kind;
  final String host;
  final String name;

  /// Kurulum portu açık: LG'de geliştirici modu, Android'de hata ayıklama.
  final bool ready;
}

class SavedTv {
  const SavedTv(this.kind, this.host, this.name, this.version);

  final TvKind kind;
  final String host;
  final String name;
  final String? version;
}

class TvCheck {
  const TvCheck(this.ready, this.keyServer, this.hasKey);

  final bool ready;
  final bool keyServer;

  /// LG: bu TV'nin anahtarı kayıtlı, parola yeniden sorulmaz.
  final bool hasKey;
}

class TvInstallResult {
  const TvInstallResult({required this.ok, this.version, this.installed = false, this.launched = false, this.hoursLeft, this.error, this.detail});

  final bool ok;
  final String? version;

  /// false: TV'deki sürüm zaten günceldi, yalnız açıldı.
  final bool installed;
  final bool launched;

  /// LG geliştirici modunun kalan süresi (saat).
  final int? hoursLeft;
  final String? error;
  final String? detail;
}

class TvBridge {
  static const _channel = MethodChannel('gt/tv');
  static const _events = EventChannel('gt/tv/events');

  /// Kurulum aşamaları: connecting, approve, checking, key, `uploading:yüzde`, installing, verifying, launching.
  static Stream<String> get stages => _events.receiveBroadcastStream().map((event) => ((event as Map)['stage'] as String?) ?? '');

  /// Uygulamayla gelen TV paketlerinin sürümleri (marka → sürüm).
  static Future<Map<TvKind, String>> bundled() async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('bundled') ?? {};
    final result = <TvKind, String>{};
    for (final entry in map.entries) {
      final kind = tvKindOf(entry.key as String?);
      if (kind != null) result[kind] = entry.value as String;
    }
    return result;
  }

  static Future<String?> phoneAddress() => _channel.invokeMethod<String>('phoneAddress');

  static Future<SavedTv?> saved() async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('saved');
    final kind = tvKindOf(map?['brand'] as String?);
    if (map == null || kind == null) return null;
    return SavedTv(kind, map['host'] as String? ?? '', map['name'] as String? ?? '', map['version'] as String?);
  }

  static Future<void> forget() => _channel.invokeMethod('forget');

  /// Elle yazılan adresi temizler; adres değilse null.
  static Future<String?> normalize(String text) => _channel.invokeMethod<String>('normalize', text);

  static Future<List<FoundTv>> find(TvKind kind) async {
    final list = await _channel.invokeMethod<List<Object?>>('find', kind.id) ?? [];
    return [
      for (final item in list.cast<Map<Object?, Object?>>())
        FoundTv(kind, item['host'] as String, item['name'] as String? ?? kind.title, item['ready'] as bool? ?? false),
    ];
  }

  static Future<TvCheck> check(TvKind kind, String host) async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('check', {'brand': kind.id, 'host': host}) ?? {};
    return TvCheck(map['ready'] as bool? ?? false, map['keyServer'] as bool? ?? false, map['hasKey'] as bool? ?? false);
  }

  static Future<TvInstallResult> install(TvKind kind, String host, {String name = '', String? passphrase, bool force = false}) async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>(
          'install',
          {'brand': kind.id, 'host': host, 'name': name, 'passphrase': passphrase, 'force': force},
        ) ??
        {};
    return TvInstallResult(
      ok: map['ok'] as bool? ?? false,
      version: map['version'] as String?,
      installed: map['installed'] as bool? ?? false,
      launched: map['launched'] as bool? ?? false,
      hoursLeft: (map['hoursLeft'] as num?)?.toInt(),
      error: map['error'] as String?,
      detail: map['detail'] as String?,
    );
  }

  static Future<void> cancel() => _channel.invokeMethod('cancel');
}

/// Hatanın sade dilde açıklaması ve çözümü (Windows'taki TvAppCard.Message ile aynı durumlar).
({String title, String fix}) tvErrorText(String? error, TvKind kind, AppLocalizations l) {
  final android = kind == TvKind.android;
  return switch (error) {
    'UNREACHABLE' => android
        ? (title: l.tvErrUnreachableAndroidTitle, fix: l.tvErrUnreachableAndroidFix)
        : (title: l.tvErrUnreachableLgTitle, fix: l.tvErrUnreachableLgFix),
    'KEY_SERVER_OFF' => (title: l.tvErrKeyServerOffTitle, fix: l.tvErrKeyServerOffFix),
    'WRONG_PASSPHRASE' => (title: l.tvErrWrongPassphraseTitle, fix: l.tvErrWrongPassphraseFix),
    'KEY_REFUSED' => (title: l.tvErrKeyRefusedTitle, fix: l.tvErrKeyRefusedFix),
    'NOT_APPROVED' => (title: l.tvErrNotApprovedTitle, fix: l.tvErrNotApprovedFix),
    'NOT_ENOUGH_SPACE' => (title: l.tvErrNoSpaceTitle, fix: l.tvErrNoSpaceFix),
    'CONNECTION_LOST' => (title: l.tvErrConnectionLostTitle, fix: l.tvErrConnectionLostFix),
    'TOO_OLD' => (title: l.tvErrTooOldTitle, fix: l.tvErrTooOldFix),
    'PACKAGE_MISSING' => (title: l.tvErrPackageMissingTitle, fix: l.tvErrPackageMissingFix),
    'CANCELLED' => (title: l.tvErrCancelledTitle, fix: l.tvErrCancelledFix),
    _ => (title: l.tvErrGenericTitle, fix: l.tvErrGenericFix),
  };
}

/// Kurulum aşamasının adı.
String tvStageText(String stage, AppLocalizations l) {
  if (stage.startsWith('uploading:')) return l.tvStageUploading(stage.substring(10));
  return switch (stage) {
    'connecting' => l.tvStageConnecting,
    'approve' => l.tvStageApprove,
    'checking' => l.tvStageChecking,
    'key' => l.tvStageKey,
    'installing' => l.tvStageInstalling,
    'verifying' => l.tvStageVerifying,
    'launching' => l.tvStageLaunching,
    _ => l.tvStagePreparing,
  };
}
