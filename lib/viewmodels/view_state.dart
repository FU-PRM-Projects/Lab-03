/// State tường minh của một màn tải dữ liệu, do ViewModel sở hữu.
///
/// Màn hình `switch` trên kiểu con để chọn Loading state, Empty state, Error
/// state hoặc nội dung; không màn nào tự suy ra trạng thái từ dữ liệu.
sealed class ViewState<T> {
  const ViewState();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Empty<T> extends ViewState<T> {
  const Empty();
}

/// Tải lỗi. [message] đã là câu tiếng Việt hiển thị được (nguyên nhân và
/// cách sửa); [offline] chọn kiểu Error state Offline.
final class Failure<T> extends ViewState<T> {
  const Failure(this.message, {this.offline = false});

  final String message;
  final bool offline;
}

final class Data<T> extends ViewState<T> {
  const Data(this.value);

  final T value;
}
