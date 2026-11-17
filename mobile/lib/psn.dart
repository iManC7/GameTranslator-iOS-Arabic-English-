// SPDX-License-Identifier: AGPL-3.0-only
// PSN girişiyle Remote Play kaydı için gereken hesap kimliğini alır.
// Akış ve istemci bilgileri chiaki-ng'den; Windows'taki GameTranslator.RemotePlay/PsnAccount.cs ile aynı.
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class PsnException implements Exception {
  PsnException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PsnAccount {
  static const clientId = 'ba495a24-818c-472b-b12d-ff231c1b5745';
  static const clientSecret = 'mvaiZkRsAsI1IBkY';
  static const tokenUrl = 'https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/token';
  static const scope =
      'psn:clientapp referenceDataService:countryConfig.read pushNotification:webSocket.desktop.connect sessionManager:remotePlaySession.system.update';
  static const redirectPrefix = 'https://remoteplay.dl.playstation.net/remoteplay/redirect';

  /// Uygulama içi tarayıcıda açılacak Sony giriş sayfası.
  static final Uri authorizeUrl = Uri.parse('https://auth.api.sonyentertainmentnetwork.com/2.0/oauth/authorize?${query({
        'service_entity': 'urn:service-entity:psn',
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectPrefix,
        'scope': scope,
        'request_locale': 'en_US',
        'ui': 'pr',
        'service_logo': 'ps',
        'layout_type': 'popup',
        'smcid': 'remoteplay',
        'prompt': 'always',
        'PlatformPrivacyWs1': 'minimal',
      })}');

  static bool isRedirect(String url) => url.startsWith(redirectPrefix);

  /// Giriş bitince tarayıcının gittiği yönlendirme adresinden tek kullanımlık kod.
  static String? codeFromRedirect(String url) => isRedirect(url) ? Uri.parse(url).queryParameters['code'] : null;

  /// Sony girişi tamamlamadıysa yönlendirmedeki hata (ör. "access_denied: ..."); yoksa null.
  static String? errorFromRedirect(String url) {
    if (!isRedirect(url)) return null;
    final parameters = Uri.parse(url).queryParameters;
    final error = parameters['error'];
    if (error == null || error.isEmpty) return null;
    final description = parameters['error_description'];
    return description == null || description.isEmpty ? error : '$error: $description';
  }

  /// Kodu token'a, token'ı hesap kimliğine (8 bayt) çevirir. Token saklanmaz.
  static Future<Uint8List> accountId(String code, {http.Client? client}) async {
    final own = client == null;
    final c = client ?? http.Client();
    try {
      final auth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
      final token = await c
          .post(Uri.parse(tokenUrl),
              headers: {'Authorization': auth, 'Content-Type': 'application/x-www-form-urlencoded'},
              body: query({'grant_type': 'authorization_code', 'code': code, 'scope': scope, 'redirect_uri': redirectPrefix}))
          .timeout(const Duration(seconds: 30));
      final tokenJson = _object(token.body);
      final accessToken = tokenJson?['access_token'];
      if (token.statusCode != 200 || accessToken is! String) {
        throw PsnException('Sony girişi kabul etmedi (HTTP ${token.statusCode})${_sonyError(tokenJson)}');
      }
      final info = await c
          .get(Uri.parse('$tokenUrl/${Uri.encodeComponent(accessToken)}'), headers: {'Authorization': auth})
          .timeout(const Duration(seconds: 30));
      final userId = _object(info.body)?['user_id'];
      final bytes = userId == null ? null : accountIdBytes('$userId');
      if (info.statusCode != 200 || bytes == null) throw PsnException('Hesap kimliği alınamadı (HTTP ${info.statusCode})');
      return bytes;
    } on PsnException {
      rethrow;
    } catch (error) {
      throw PsnException('Sony\'ye ulaşılamadı: $error');
    } finally {
      if (own) c.close();
    }
  }

  /// Ondalık `user_id`'yi 8 baytlık little-endian dizisine çevirir.
  static Uint8List? accountIdBytes(String userId) {
    final value = BigInt.tryParse(userId);
    if (value == null || value.isNegative || value.bitLength > 64) return null;
    final bytes = Uint8List(8);
    var rest = value;
    for (var i = 0; i < 8; i++) {
      bytes[i] = (rest & BigInt.from(0xff)).toInt();
      rest = rest >> 8;
    }
    return bytes;
  }

  static Map<String, dynamic>? _object(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }

  static String _sonyError(Map<String, dynamic>? json) {
    final error = json?['error'];
    if (error == null) return '';
    final description = json?['error_description'];
    return description == null ? ': $error' : ': $error: $description';
  }

  /// İzinli karakterler (":" ve "/" dahil) olduğu gibi kalır; Sony'nin beklediği biçim.
  static String query(Map<String, String> items) => items.entries.map((e) => '${_encode(e.key)}=${_encode(e.value)}').join('&');

  static String _encode(String text) {
    const allowed = "-._~:/?@!\$'()*,;";
    final out = StringBuffer();
    for (final byte in utf8.encode(text)) {
      final c = String.fromCharCode(byte);
      final alphanumeric = (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5a) || (byte >= 0x61 && byte <= 0x7a);
      if (alphanumeric || allowed.contains(c)) {
        out.write(c);
      } else {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }
}
