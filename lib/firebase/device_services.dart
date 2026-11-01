import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../services/self_control_services.dart';

/// [LocalAuthService] bằng `local_auth`: vân tay, khuôn mặt hoặc mã máy.
///
/// Nằm trong `firebase/` cùng các hiện thực service khác: đây là lớp được
/// phép gọi SDK của nền tảng.
class DeviceLocalAuthService implements LocalAuthService {
  DeviceLocalAuthService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // biometricOnly: false cho phép dùng mã PIN / hình vẽ của máy.
      return await _auth.authenticate(localizedReason: reason);
    } on LocalAuthException {
      // Huỷ, sai quá số lần, hoặc máy chưa đặt khoá màn hình.
      return false;
    } on PlatformException {
      return false;
    }
  }
}

/// [ScreenGuard] qua kênh `lab03/window` trong `MainActivity.kt`.
class MethodChannelScreenGuard implements ScreenGuard {
  const MethodChannelScreenGuard();

  static const MethodChannel _channel = MethodChannel('lab03/window');

  Future<void> _call(String method, bool enabled) async {
    try {
      await _channel.invokeMethod<void>(method, <String, Object?>{
        'enabled': enabled,
      });
    } on MissingPluginException {
      // Nền tảng khác Android (web build trên CI): không có cờ cửa sổ.
    } on PlatformException {
      // Cờ cửa sổ chỉ là phần thêm; không chặn màn hình vì lỗi này.
    }
  }

  @override
  Future<void> setSecure(bool enabled) => _call('setSecure', enabled);

  @override
  Future<void> setKeepScreenOn(bool enabled) =>
      _call('setKeepScreenOn', enabled);
}
