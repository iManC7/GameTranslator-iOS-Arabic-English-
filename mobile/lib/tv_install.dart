// SPDX-License-Identifier: AGPL-3.0-only
// Telefondan TV uygulaması kurma: Android tarafındaki tvinstall/TvInstallChannel ile konuşan köprü ve hata metinleri.
import 'package:flutter/services.dart';

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
({String title, String fix}) tvErrorText(String? error, TvKind kind) {
  final android = kind == TvKind.android;
  return switch (error) {
    'UNREACHABLE' => android
        ? (
            title: 'TV yanıt vermedi',
            fix: 'TV açık mı ve telefonla aynı Wi-Fi ağında mı? Geliştirici seçeneklerinde "USB hata ayıklama" açık olmalı. '
                'Bazı TV\'lerde bu ayar TV yeniden başlayınca kapanır; açıp yeniden dene.',
          )
        : (
            title: 'TV yanıt vermedi',
            fix: 'TV açık mı ve telefonla aynı Wi-Fi ağında mı? Developer Mode uygulamasında "Dev Mode Status" açık olmalı; '
                'açtıktan sonra TV yeniden başlar, açılmasını bekle.',
          ),
    'KEY_SERVER_OFF' => (
        title: 'Key Server kapalı',
        fix: 'TV\'de Developer Mode uygulamasını aç, "Key Server"ı aç ve uygulamayı ekranda bırak. Sonra yeniden dene.',
      ),
    'WRONG_PASSPHRASE' => (
        title: 'Parola doğru değil',
        fix: 'TV ekranında Developer Mode uygulamasının sol altındaki 6 karakterlik "Passphrase"i yeniden yaz. '
            '0 (sıfır) ile O harfi, 1 ile I harfi karışabilir.',
      ),
    'KEY_REFUSED' => (
        title: 'TV anahtarı kabul etmedi',
        fix: 'Geliştirici modu kapatılıp açıldıysa TV yeni bir anahtar üretir. Key Server\'ı açıp parolayı yeniden yaz.',
      ),
    'NOT_APPROVED' => (
        title: 'TV\'de izin verilmedi',
        fix: 'Yeniden dene. TV\'de "USB hata ayıklamaya izin verilsin mi?" sorusu çıkınca "Bu bilgisayardan her zaman izin ver"i '
            'işaretleyip "İzin ver"i seç. Soru TV ekranında yaklaşık bir buçuk dakika bekler.',
      ),
    'NOT_ENOUGH_SPACE' => (
        title: 'TV\'de yer kalmamış',
        fix: 'TV\'den kullanmadığın bir uygulamayı kaldır ve yeniden dene.',
      ),
    'CONNECTION_LOST' => (
        title: 'Bağlantı koptu',
        fix: 'Kurulum sırasında TV ile bağlantı kesildi. Telefonun ekranı açık ve Wi-Fi\'ye bağlı kalsın; yeniden dene.',
      ),
    'TOO_OLD' => (
        title: 'Bu TV çok eski',
        fix: 'GameTranslator TV uygulaması bu TV\'nin yazılımında çalışmıyor.',
      ),
    'PACKAGE_MISSING' => (
        title: 'TV paketi bulunamadı',
        fix: 'Bu telefon uygulamasının içinde TV paketi yok. Uygulamanın son sürümünü kur.',
      ),
    'CANCELLED' => (title: 'Kurulum durduruldu', fix: 'Hazır olduğunda yeniden başlatabilirsin.'),
    _ => (
        title: 'TV uygulaması kurulamadı',
        fix: 'Yeniden dene. TV\'yi kapatıp açmak yarım kalan kurulumların çoğunu düzeltir. Yine olmazsa aşağıdaki "TV\'nin söylediği" '
            'yazısıyla birlikte bize bildir.',
      ),
  };
}

/// Kurulum aşamasının Türkçe adı.
String tvStageText(String stage) {
  if (stage.startsWith('uploading:')) return 'Uygulama TV\'ye gönderiliyor… %${stage.substring(10)}';
  return switch (stage) {
    'connecting' => 'TV\'ye bağlanılıyor…',
    'approve' => 'TV\'de izin bekleniyor…',
    'checking' => 'TV\'deki sürüme bakılıyor…',
    'key' => 'TV\'den anahtar alınıyor…',
    'installing' => 'TV\'ye kuruluyor…',
    'verifying' => 'Kurulum doğrulanıyor…',
    'launching' => 'TV\'de açılıyor…',
    _ => 'Hazırlanıyor…',
  };
}
