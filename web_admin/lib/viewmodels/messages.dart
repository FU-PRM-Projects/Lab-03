import 'package:not_core/not_core.dart';

/// Câu báo lỗi cho staff, theo loại lỗi của tầng service.
String errorMessage(Object error) {
  if (error is AppException) {
    return switch (error.kind) {
      AppErrorKind.network =>
        'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
      AppErrorKind.permissionDenied =>
        'Tài khoản này không có quyền làm việc này.',
      AppErrorKind.invalidInput when error.code == 'reason-required' =>
        'Cần ghi lý do khi từ chối.',
      AppErrorKind.invalidInput => 'Dữ liệu chưa hợp lệ. Kiểm tra lại các ô.',
      AppErrorKind.notFound => 'Không tìm thấy dữ liệu. Có thể đã bị xoá.',
      AppErrorKind.cancelled => 'Đã huỷ.',
      AppErrorKind.unknown => 'Có lỗi xảy ra. Thử lại sau ít phút.',
    };
  }
  return 'Có lỗi xảy ra. Thử lại sau ít phút.';
}
