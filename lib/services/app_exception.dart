/// Loại lỗi mà ViewModel cần phân biệt để chọn câu thông báo.
enum AppErrorKind {
  /// Không có mạng hoặc server không trả lời.
  network,

  /// Security Rules từ chối.
  permissionDenied,

  /// Người dùng tự huỷ (ví dụ đóng hộp chọn tài khoản Google).
  cancelled,

  /// Dữ liệu nhập sai (email/mật khẩu không đúng, email đã có tài khoản…).
  invalidInput,

  notFound,
  unknown,
}

/// Lỗi của tầng service. Hiện thực Firebase đổi lỗi SDK sang lớp này để
/// ViewModel không phụ thuộc kiểu lỗi của Firebase.
class AppException implements Exception {
  const AppException(this.kind, {this.code, this.detail});

  final AppErrorKind kind;

  /// Mã lỗi gốc của SDK (ví dụ `email-already-in-use`), để ViewModel chọn câu
  /// cụ thể hơn và để ghi log.
  final String? code;
  final String? detail;

  @override
  String toString() => 'AppException($kind, $code, $detail)';
}
