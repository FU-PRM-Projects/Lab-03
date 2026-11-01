import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/self_control.dart';
import '../services/self_control_services.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

class SettingsState {
  const SettingsState({
    this.settings = const Loading<UserSettings>(),
    this.authenticating = false,
    this.message,
  });

  final ViewState<UserSettings> settings;

  /// Đang chờ `local_auth` để bật / tắt "Khoá phần Tự chủ".
  final bool authenticating;

  /// Lỗi lưu hoặc xác thực cho SnackBar.
  final String? message;

  SettingsState copyWith({
    ViewState<UserSettings>? settings,
    bool? authenticating,
    String? Function()? message,
  }) => SettingsState(
    settings: settings ?? this.settings,
    authenticating: authenticating ?? this.authenticating,
    message: message == null ? this.message : message(),
  );
}

final settingsViewModelProvider =
    NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );

/// ViewModel của S12 · Cài đặt (flow P8). Đăng xuất ở `AuthViewModel`.
class SettingsViewModel extends Notifier<SettingsState> {
  UserSettings? _current;

  /// Số lệnh lưu chưa xong. Trong lúc đó bỏ qua giá trị Firestore phát lại,
  /// vì nó có thể là bản cũ hơn thay đổi người dùng vừa bấm.
  int _saving = 0;

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _current = null;
    _saving = 0;
    final sub = _repo.watch().listen(
      (settings) {
        if (_saving > 0) return;
        _current = settings;
        state = state.copyWith(settings: Data<UserSettings>(settings));
      },
      onError: (Object error) {
        if (_current == null) {
          state = state.copyWith(settings: ErrorMessages.failure(error));
        }
      },
    );
    ref.onDispose(sub.cancel);
    return const SettingsState();
  }

  void retry() => ref.invalidateSelf();

  /// Lưu ngay (handout S12). Stage 5: đặt lại lịch thông báo nhắc.
  Future<void> _save(UserSettings Function(UserSettings) change) async {
    final current = _current;
    if (current == null) return;
    final next = change(current);
    // Hiện ngay giá trị mới, không chờ Firestore phát lại.
    _current = next;
    state = state.copyWith(settings: Data<UserSettings>(next));
    _saving++;
    try {
      await _repo.save(next);
    } on Object catch (error) {
      if (!ref.mounted) return;
      _current = current;
      state = state.copyWith(
        settings: Data<UserSettings>(current),
        message: () => ErrorMessages.update(error),
      );
    } finally {
      _saving--;
    }
  }

  Future<void> setEveningReminder(int minutes) =>
      _save((s) => s.copyWith(eveningReminder: minutes));

  Future<void> setAwakeEnabled(bool enabled) =>
      _save((s) => s.copyWith(awakeEnabled: enabled));

  Future<void> setAwakeTimes(int start, int end) =>
      _save((s) => s.copyWith(awakeStart: start, awakeEnd: end));

  Future<void> setAiEnabled(bool enabled) =>
      _save((s) => s.copyWith(aiEnabled: enabled));

  Future<void> setHideNotificationContent(bool hide) =>
      _save((s) => s.copyWith(hideNotificationContent: hide));

  /// "Khoá phần Tự chủ": xác thực `local_auth` trước khi đổi, cả khi tắt,
  /// để người cầm máy không tự gỡ khoá được (deviation D-19).
  Future<void> setLockSelfControl(bool locked) async {
    if (state.authenticating || _current == null) return;
    state = state.copyWith(authenticating: true);
    final ok = await ref
        .read(localAuthServiceProvider)
        .authenticate(locked ? 'Bật khoá phần Tự chủ' : 'Tắt khoá phần Tự chủ');
    if (!ref.mounted) return;
    state = state.copyWith(authenticating: false);
    if (!ok) {
      state = state.copyWith(
        message: () =>
            'Chưa xác thực được nên chưa đổi khoá. Máy cần có khoá màn hình.',
      );
      return;
    }
    await _save((s) => s.copyWith(lockSelfControl: locked));
  }

  void clearMessage() => state = state.copyWith(message: () => null);
}
