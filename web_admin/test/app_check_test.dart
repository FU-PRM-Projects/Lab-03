import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_admin/firebase/app_check.dart';

void main() {
  test('không có site key lẫn debug token: không bật App Check', () {
    expect(webAppCheckProvider(siteKey: '', debugToken: ''), isNull);
  });

  test('có site key: dùng reCAPTCHA v3', () {
    final provider = webAppCheckProvider(siteKey: 'site-key', debugToken: '');
    expect(provider, isA<ReCaptchaV3Provider>());
    expect(provider!.siteKey, 'site-key');
  });

  test('debug token được ưu tiên hơn reCAPTCHA', () {
    final provider = webAppCheckProvider(
      siteKey: 'site-key',
      debugToken: 'debug-token',
    );
    expect(provider, isA<WebDebugProvider>());
    expect((provider! as WebDebugProvider).debugToken, 'debug-token');
  });
}
