/// Chính sách thử lại cho `ProviderScope(retry: noRetry)` của cả hai app.
///
/// Riverpod 3 mặc định tự thử lại provider lỗi tới 10 lần (chờ 0,2 → 6,4
/// giây) và giữ trạng thái loading trong lúc đó. Màn lỗi vì vậy chỉ hiện sau
/// vài chục giây, còn Tổng quan của web admin (chờ tối đa 15 giây mỗi lần)
/// quay vòng hơn 3 phút khi mất mạng. Mọi màn đã có nút "Thử lại", nên báo lỗi
/// ngay và để người dùng tự thử lại.
///
/// Cùng chữ ký với `Retry` của Riverpod; để ở đây để `not_core` không phải phụ
/// thuộc Riverpod.
Duration? noRetry(int retryCount, Object error) => null;
