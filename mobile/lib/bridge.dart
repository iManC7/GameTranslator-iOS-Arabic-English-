// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:convert';

import 'package:flutter/services.dart';

/// Çekirdeğin (Android tarafındaki Engine) arayüze bildirdiği durum.
class EngineState {
  const EngineState({
    this.phase = 'idle',
    this.message = '',
    this.running = false,
    this.tvClients = 0,
    this.serverPort = 0,
    this.localAddress,
    this.lastSource = '',
    this.lastTranslation = '',
    this.lastRead = '',
    this.frames = 0,
    this.frameWidth = 0,
    this.frameHeight = 0,
    this.translated = 0,
    this.packHits = 0,
    this.packGame = '',
    this.nativeAvailable = true,
  });

  /// idle, starting, waking, connecting, streaming, reconnecting, stopping, failed
  final String phase;
  final String message;
  final bool running;
  final int tvClients;
  final int serverPort;
  final String? localAddress;
  final String lastSource;
  final String lastTranslation;
  final String lastRead;
  final int frames;
  final int frameWidth;
  final int frameHeight;
  final int translated;

  /// Oyun paketinden gösterilen satır sayısı ve paketin (oynanan oyunun) adı.
  final int packHits;
  final String packGame;
  final bool nativeAvailable;

  factory EngineState.fromMap(Map<Object?, Object?> map) => EngineState(
        phase: map['phase'] as String? ?? 'idle',
        message: map['message'] as String? ?? '',
        running: map['running'] as bool? ?? false,
        tvClients: (map['tvClients'] as num?)?.toInt() ?? 0,
        serverPort: (map['serverPort'] as num?)?.toInt() ?? 0,
        localAddress: map['localAddress'] as String?,
        lastSource: map['lastSource'] as String? ?? '',
        lastTranslation: map['lastTranslation'] as String? ?? '',
        lastRead: map['lastRead'] as String? ?? '',
        frames: (map['frames'] as num?)?.toInt() ?? 0,
        frameWidth: (map['frameWidth'] as num?)?.toInt() ?? 0,
        frameHeight: (map['frameHeight'] as num?)?.toInt() ?? 0,
        translated: (map['translated'] as num?)?.toInt() ?? 0,
        packHits: (map['packHits'] as num?)?.toInt() ?? 0,
        packGame: map['packGame'] as String? ?? '',
        nativeAvailable: map['nativeAvailable'] as bool? ?? true,
      );
}

/// Kayıtlı PSN hesabı ve eşleştirilmiş PS5.
class SetupInfo {
  const SetupInfo({this.hasAccount = false, this.consoleHost, this.consoleName, this.introSeen = false, this.version = ''});

  final bool hasAccount;
  final String? consoleHost;
  final String? consoleName;
  final bool introSeen;
  final String version;

  bool get hasConsole => consoleHost != null && consoleHost!.isNotEmpty;
  bool get ready => hasAccount && hasConsole;
}

class FoundConsole {
  const FoundConsole(this.host, this.name, this.awake);

  final String host;
  final String name;
  final bool awake;
}

class RegisterResult {
  const RegisterResult(this.ok, this.name, this.detail);

  final bool ok;
  final String? name;
  final String? detail;
}

/// Uygulama ayarları; Android tarafındaki Settings ile aynı alanlar (JSON olarak taşınır).
class AppSettings {
  AppSettings(this.json);

  final Map<String, dynamic> json;

  Map<String, dynamic> get region => (json['region'] as Map).cast<String, dynamic>();
  Map<String, dynamic> get style => (json['style'] as Map).cast<String, dynamic>();

  double regionValue(String edge) => (region[edge] as num).toDouble();
  String get engine => json['engine'] as String? ?? 'google';
  String get targetLanguage => json['targetLanguage'] as String? ?? 'tr';
  String get sourceLanguage => json['sourceLanguage'] as String? ?? 'en';
  String get deepLKey => json['deepLKey'] as String? ?? '';
  String get geminiKey => json['geminiKey'] as String? ?? '';
  bool get autoWake => json['autoWake'] as bool? ?? true;
  String get glossary => json['glossary'] as String? ?? '';
  bool get packsEnabled => json['packsEnabled'] as bool? ?? true;
  bool get hideButtonHints => json['hideButtonHints'] as bool? ?? true;
  String get packChoice => json['packChoice'] as String? ?? '';

  AppSettings copy() => AppSettings(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
}

/// Android tarafındaki "gt/bridge" ve "gt/events" kanalları.
class Bridge {
  static const _channel = MethodChannel('gt/bridge');
  static const _events = EventChannel('gt/events');

  static Stream<EngineState> get states =>
      _events.receiveBroadcastStream().map((event) => EngineState.fromMap(event as Map<Object?, Object?>));

  static Future<EngineState> state() async =>
      EngineState.fromMap((await _channel.invokeMethod<Map<Object?, Object?>>('getState'))!);

  static Future<SetupInfo> setup() async {
    final map = (await _channel.invokeMethod<Map<Object?, Object?>>('getSetup'))!;
    return SetupInfo(
      hasAccount: map['hasAccount'] as bool? ?? false,
      consoleHost: map['consoleHost'] as String?,
      consoleName: map['consoleName'] as String?,
      introSeen: map['introSeen'] as bool? ?? false,
      version: map['version'] as String? ?? '',
    );
  }

  static Future<AppSettings> settings() async =>
      AppSettings(jsonDecode((await _channel.invokeMethod<String>('getSettings'))!) as Map<String, dynamic>);

  static Future<void> saveSettings(AppSettings settings) => _channel.invokeMethod('setSettings', jsonEncode(settings.json));

  /// [accountId]: 8 baytlık hesap kimliği.
  static Future<void> setAccountId(Uint8List accountId) => _channel.invokeMethod('setAccountId', base64Encode(accountId));

  static Future<void> setIntroSeen(bool seen) => _channel.invokeMethod('setIntroSeen', seen);
  static Future<void> forgetAccount() => _channel.invokeMethod('forgetAccount');
  static Future<void> forgetConsole() => _channel.invokeMethod('forgetConsole');

  static Future<List<FoundConsole>> discover({List<String> hosts = const [], int timeoutMs = 3000}) async {
    final list = await _channel.invokeMethod<List<Object?>>('discover', {'hosts': hosts, 'timeoutMs': timeoutMs}) ?? [];
    return list.map((item) {
      final map = item as Map<Object?, Object?>;
      return FoundConsole(map['host'] as String, map['name'] as String? ?? 'PS5', map['awake'] as bool? ?? false);
    }).toList();
  }

  static Future<RegisterResult> register(String host, int pin) async {
    final map = (await _channel.invokeMethod<Map<Object?, Object?>>('register', {'host': host, 'pin': pin}))!;
    return RegisterResult(map['ok'] as bool? ?? false, map['name'] as String?, map['detail'] as String?);
  }

  static Future<void> start() => _channel.invokeMethod('start');
  static Future<void> stop() => _channel.invokeMethod('stop');
  static Future<void> testSubtitle() => _channel.invokeMethod('testSubtitle');
  static Future<Uint8List?> snapshot({int width = 960}) => _channel.invokeMethod<Uint8List>('snapshot', width);

  /// Türkçe yaması olan oyunlar (kimlik, başlık, satır sayısı); yalnız iOS.
  static Future<List<({String id, String title, int entries})>> packList() async {
    try {
      final list = await _channel.invokeMethod<List<Object?>>('packList') ?? [];
      return [
        for (final item in list.cast<Map<Object?, Object?>>())
          (id: item['id'] as String, title: item['title'] as String? ?? '', entries: (item['entries'] as num?)?.toInt() ?? 0),
      ];
    } on MissingPluginException {
      return [];
    }
  }

  /// Topluluk yamalarını (GitLab patches/) hemen günceller (yalnız iOS). (başarılı mı, gösterilecek metin)
  static Future<(bool, String)> updatePatches() async {
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>('updatePatches') ?? {};
      return (map['ok'] as bool? ?? false, map['detail'] as String? ?? '');
    } on MissingPluginException {
      return (false, 'Bu telefonda desteklenmiyor.');
    }
  }

  /// Gemini anahtarını bir deneme çevirisiyle sınar (yalnız iOS). (başarılı mı, gösterilecek metin)
  static Future<(bool, String)> checkGemini(String key) async {
    try {
      final map = await _channel.invokeMethod<Map<Object?, Object?>>('checkGemini', key) ?? {};
      return (map['ok'] as bool? ?? false, map['detail'] as String? ?? '');
    } on MissingPluginException {
      return (false, 'Bu telefonda desteklenmiyor.');
    }
  }

  /// Adresi tarayıcıda açar (yalnız iOS'ta; Android'de false döner).
  static Future<bool> openUrl(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', url) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<List<String>> logs() async =>
      (await _channel.invokeMethod<List<Object?>>('logs') ?? []).cast<String>();
}
