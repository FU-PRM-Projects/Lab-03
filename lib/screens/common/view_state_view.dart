import 'package:material_ui/material_ui.dart';

import '../../viewmodels/view_state.dart';
import '../../widgets/state_views.dart';

/// Vẽ đúng một trong bốn trạng thái của [ViewState] bằng component Lab 2.
///
/// Màn hình truyền nội dung cho từng trạng thái; mặc định Loading là vòng
/// xoay và Error có nút Thử lại gọi [onRetry].
class ViewStateView<T> extends StatelessWidget {
  const ViewStateView({
    required this.state,
    required this.data,
    required this.empty,
    required this.onRetry,
    this.loading = const LoadingState.spinner(),
    this.errorTitle = 'Chưa tải được dữ liệu',
    super.key,
  });

  final ViewState<T> state;
  final Widget Function(T value) data;
  final Widget empty;
  final Widget loading;
  final String errorTitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      Loading<T>() => loading,
      Empty<T>() => empty,
      Failure<T>(:final message, :final offline) => ErrorState(
        title: errorTitle,
        cause: message,
        kind: offline ? ErrorKind.offline : ErrorKind.loadFailed,
        onRetry: onRetry,
      ),
      Data<T>(:final value) => data(value),
    };
  }
}
