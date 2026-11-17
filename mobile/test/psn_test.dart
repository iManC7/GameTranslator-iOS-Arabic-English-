// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslator_mobile/psn.dart';

void main() {
  test('user_id becomes 8 little-endian bytes', () {
    expect(PsnAccount.accountIdBytes('1'), [1, 0, 0, 0, 0, 0, 0, 0]);
    expect(PsnAccount.accountIdBytes('4660'), [0x34, 0x12, 0, 0, 0, 0, 0, 0]);
    expect(PsnAccount.accountIdBytes('18446744073709551615'), List.filled(8, 0xff));
    expect(PsnAccount.accountIdBytes('18446744073709551616'), isNull);
    expect(PsnAccount.accountIdBytes('abc'), isNull);
    expect(PsnAccount.accountIdBytes('-5'), isNull);
  });

  test('code and error are read from the redirect', () {
    const redirect = '${PsnAccount.redirectPrefix}?code=AbC123&cid=x';
    expect(PsnAccount.codeFromRedirect(redirect), 'AbC123');
    expect(PsnAccount.codeFromRedirect('https://example.com/?code=AbC123'), isNull);
    expect(PsnAccount.errorFromRedirect('${PsnAccount.redirectPrefix}?error=access_denied&error_description=User+cancelled'),
        'access_denied: User cancelled');
    expect(PsnAccount.errorFromRedirect(redirect), isNull);
  });

  test('query keeps the characters Sony expects unescaped', () {
    expect(PsnAccount.query({'redirect_uri': PsnAccount.redirectPrefix, 'scope': 'a b'}),
        'redirect_uri=https://remoteplay.dl.playstation.net/remoteplay/redirect&scope=a%20b');
    expect(PsnAccount.authorizeUrl.toString(), contains('client_id=${PsnAccount.clientId}'));
  });
}
