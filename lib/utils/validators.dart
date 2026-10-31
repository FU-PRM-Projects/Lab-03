/// Kiểm tra dữ liệu nhập theo handout S01 (P2). Trả về câu lỗi tiếng Việt
/// hiện dưới ô, hoặc `null` khi hợp lệ.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int emailMaxLength = 254;
  static const int passwordMinLength = 8;

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Nhập email của bạn.';
    if (email.length > emailMaxLength) return 'Email dài quá 254 ký tự.';
    if (!_email.hasMatch(email)) {
      return 'Email chưa đúng dạng, ví dụ ten@gmail.com.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Nhập mật khẩu.';
    if (value.length < passwordMinLength) {
      return 'Mật khẩu cần ít nhất 8 ký tự.';
    }
    return null;
  }
}
