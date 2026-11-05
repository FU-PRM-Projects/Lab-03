import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/image_ref.dart';
import '../services/app_exception.dart';
import '../services/crash_reporter.dart';
import '../services/profile_photo_repository.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'image_upload_view_model.dart';

class ProfilePhotoState {
  const ProfilePhotoState({this.photo, this.saving = false, this.message});

  /// Ảnh đại diện đã lưu; `null` thì các màn dùng avatar mặc định.
  final ImageRef? photo;

  /// Đang ghi ảnh vào hồ sơ.
  final bool saving;

  /// Lỗi lưu ảnh (SnackBar), màn hình gọi [ProfilePhotoViewModel.clearMessage].
  final String? message;
}

/// Sống suốt phiên đăng nhập: thanh đầu 4 tab và Cài đặt cùng đọc một ảnh.
final profilePhotoViewModelProvider =
    NotifierProvider<ProfilePhotoViewModel, ProfilePhotoState>(
      ProfilePhotoViewModel.new,
    );

/// Giữ ảnh đại diện đã lưu, và lưu ảnh mới ngay khi `ImageUploadViewModel`
/// (thư mục avatar) tải xong lên Cloudinary.
class ProfilePhotoViewModel extends Notifier<ProfilePhotoState> {
  StreamSubscription<ImageRef?>? _sub;

  @override
  ProfilePhotoState build() {
    // Đổi tài khoản thì dựng lại: huỷ nghe tài khoản cũ, nghe tài khoản mới.
    final uid = ref.watch(authUserProvider.select((user) => user.value?.uid));
    ref.onDispose(() => unawaited(_sub?.cancel()));

    ref.listen(imageUploadViewModelProvider(ImageFolder.avatar), (
      previous,
      next,
    ) {
      final image = next.image;
      if (next.phase == ImageUploadPhase.done &&
          image != null &&
          previous?.phase != ImageUploadPhase.done) {
        unawaited(_save(image));
      }
    });

    if (uid == null) return const ProfilePhotoState();
    _sub = ref
        .read(profilePhotoRepositoryProvider)
        .watch()
        .listen(
          (photo) {
            if (!ref.mounted) return;
            state = ProfilePhotoState(
              photo: photo,
              saving: state.saving,
              message: state.message,
            );
          },
          onError: (Object _) {
            // Không đọc được ảnh thì giữ avatar mặc định, không báo lỗi.
          },
        );
    return const ProfilePhotoState();
  }

  /// Gỡ ảnh đại diện (ảnh cũ vẫn còn trên Cloudinary: unsigned upload không
  /// xoá được từ app).
  Future<void> remove() => _save(null);

  void clearMessage() {
    state = ProfilePhotoState(photo: state.photo, saving: state.saving);
  }

  Future<void> _save(ImageRef? photo) async {
    state = ProfilePhotoState(photo: state.photo, saving: true);
    try {
      await ref.read(profilePhotoRepositoryProvider).save(photo);
      if (!ref.mounted) return;
      state = ProfilePhotoState(photo: photo);
    } on Object catch (error, stack) {
      if (!ref.mounted) return;
      if (error is! AppException || error.kind == AppErrorKind.unknown) {
        final reporter = ref.read(crashReporterProvider);
        unawaited(reporter.setKey('image_folder', ImageFolder.avatar.id));
        unawaited(
          reporter.recordError(error, stack, reason: 'profile_photo_save'),
        );
      }
      state = ProfilePhotoState(
        photo: state.photo,
        message: ErrorMessages.update(error),
      );
    }
    // Đưa khối chọn ảnh về trạng thái đầu: nó sẽ hiện ảnh đã lưu. Bỏ qua nếu
    // người dùng đã bắt đầu một lần tải mới trong lúc lưu: reset lúc này sẽ xoá
    // tiến độ/nút huỷ của lần tải đó và cho phép mở thêm lần thứ hai song song.
    if (ref.mounted &&
        !ref.read(imageUploadViewModelProvider(ImageFolder.avatar)).busy) {
      ref
          .read(imageUploadViewModelProvider(ImageFolder.avatar).notifier)
          .reset();
    }
  }
}
