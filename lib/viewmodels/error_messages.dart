import '../services/app_exception.dart';
import 'view_state.dart';

/// Câu thông báo tiếng Việt cho lỗi của tầng service (tone Lab 2: nêu lý do
/// và cách sửa).
abstract final class ErrorMessages {
  static const String offline = 'Kiểm tra Wi-Fi rồi thử lại.';
  static const String slow =
      'Mạng chậm hơn bình thường. Kiểm tra Wi-Fi rồi thử lại.';

  /// Lỗi tải dữ liệu, dùng làm `cause` của Error state.
  static String load(Object error) => switch (error) {
    AppException(kind: AppErrorKind.network) => offline,
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại.',
    AppException(kind: AppErrorKind.notFound) =>
      'Không tìm thấy nốt này. Có thể nốt đã bị xoá.',
    _ => 'Có lỗi khi đọc dữ liệu. Thử lại sau ít phút.',
  };

  /// Lỗi khi lưu (SnackBar).
  static String save(Object error) => switch (error) {
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Chưa lưu được: phiên đăng nhập đã hết. Nốt vẫn được giữ làm nháp.',
    AppException(kind: AppErrorKind.invalidInput) =>
      'Chưa lưu được: nội dung không hợp lệ. Kiểm tra lại rồi thử lại.',
    _ => 'Chưa lưu được. Nốt vẫn được giữ làm nháp, thử lại nhé.',
  };

  /// Lỗi khi sửa nốt ở S06 (nội dung còn trên màn hình, không có nháp).
  static String update(Object error) => switch (error) {
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Chưa lưu được: phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại.',
    AppException(kind: AppErrorKind.notFound) =>
      'Chưa lưu được: nốt này đã bị xoá ở thiết bị khác.',
    _ => 'Chưa lưu được thay đổi. Thử lại nhé.',
  };

  /// [ViewState] lỗi cho [error].
  static Failure<T> failure<T>(Object error) => Failure<T>(
    load(error),
    offline: error is AppException && error.kind == AppErrorKind.network,
  );
}
