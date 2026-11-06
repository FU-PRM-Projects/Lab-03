import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/image_ref.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/app_exception.dart';
import '../services/crash_reporter.dart';
import '../services/image_service.dart';

enum ImageUploadPhase { idle, picking, uploading, done, failed }

class ImageUploadState {
  const ImageUploadState({
    this.phase = ImageUploadPhase.idle,
    this.progress = 0,
    this.image,
    this.message,
  });

  final ImageUploadPhase phase;

  /// 0–1 khi đang tải lên.
  final double progress;

  /// Ảnh vừa tải xong (có khi [phase] là `done`).
  final ImageRef? image;

  /// Câu lỗi tiếng Việt cho Error state / SnackBar (khi `failed`).
  final String? message;

  bool get busy =>
      phase == ImageUploadPhase.picking || phase == ImageUploadPhase.uploading;
}

/// Mỗi nơi dùng ảnh (avatar, nốt, nhóm, thử thách) có một state riêng theo
/// [ImageFolder].
final imageUploadViewModelProvider = NotifierProvider.autoDispose
    .family<ImageUploadViewModel, ImageUploadState, ImageFolder>(
      ImageUploadViewModel.new,
    );

/// Chọn ảnh → kiểm tra → tải lên Cloudinary có tiến độ. Chỉ giữ trạng thái
/// của lần tải; lưu `ImageRef` vào Firestore là việc của ViewModel chủ.
class ImageUploadViewModel extends Notifier<ImageUploadState> {
  ImageUploadViewModel(this.folder);

  final ImageFolder folder;
  StreamSubscription<ImageUploadProgress>? _sub;

  @override
  ImageUploadState build() {
    ref.onDispose(() => unawaited(_sub?.cancel()));
    return const ImageUploadState();
  }

  Future<void> pickAndUpload(ImagePickSource source) async {
    if (state.busy) return;
    state = const ImageUploadState(phase: ImageUploadPhase.picking);
    final PickedImage? picked;
    try {
      picked = await ref.read(imagePickerServiceProvider).pick(source);
    } on Object catch (error, stack) {
      _fail(error, stack);
      return;
    }
    if (!ref.mounted) return;
    if (picked == null) {
      // Người dùng đóng hộp chọn ảnh: không phải lỗi, không báo gì.
      state = const ImageUploadState();
      return;
    }
    if (picked.bytes.length > ImageLimits.maxBytes) {
      state = const ImageUploadState(
        phase: ImageUploadPhase.failed,
        message: 'Ảnh lớn quá (tối đa 5 MB). Chọn ảnh khác nhé.',
      );
      return;
    }
    state = const ImageUploadState(phase: ImageUploadPhase.uploading);
    await _upload(picked);
  }

  Future<void> _upload(PickedImage picked) {
    final finished = Completer<void>();
    _sub = ref
        .read(imageServiceProvider)
        .upload(picked, folder: folder)
        .listen(
          (step) {
            if (!ref.mounted) return;
            final image = step.image;
            if (image == null) {
              state = ImageUploadState(
                phase: ImageUploadPhase.uploading,
                progress: step.fraction,
              );
              return;
            }
            state = ImageUploadState(
              phase: ImageUploadPhase.done,
              progress: 1,
              image: image,
            );
            unawaited(
              ref.read(analyticsServiceProvider).track(
                AnalyticsEvents.imageUploaded,
                <String, Object>{
                  AnalyticsParams.imageFolder: folder.id,
                  AnalyticsParams.fileSizeKb: (picked.bytes.length / 1024)
                      .round(),
                },
              ),
            );
          },
          onError: (Object error, StackTrace stack) {
            _fail(error, stack);
            if (!finished.isCompleted) finished.complete();
          },
          onDone: () {
            if (!finished.isCompleted) finished.complete();
          },
          cancelOnError: true,
        );
    return finished.future;
  }

  /// Nút "Huỷ" lúc đang tải.
  void cancel() {
    unawaited(_sub?.cancel());
    state = const ImageUploadState();
  }

  /// Quay về trạng thái đầu (sau khi host đã lưu ảnh, hoặc khi gỡ ảnh).
  void reset() => state = const ImageUploadState();

  void _fail(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    // Chỉ lỗi bất thường mới lên Crashlytics: mất mạng, từ chối quyền, ảnh
    // sai định dạng và người dùng huỷ là tình huống bình thường.
    if (error is! AppException || error.kind == AppErrorKind.unknown) {
      final reporter = ref.read(crashReporterProvider);
      unawaited(reporter.setKey('image_folder', folder.id));
      unawaited(reporter.recordError(error, stack, reason: 'image_upload'));
    }
    if (error is AppException && error.kind == AppErrorKind.cancelled) {
      state = const ImageUploadState();
      return;
    }
    state = ImageUploadState(
      phase: ImageUploadPhase.failed,
      message: _message(error),
    );
  }

  static String _message(Object error) => switch (error) {
    AppException(kind: AppErrorKind.network) =>
      'Chưa tải ảnh lên được: kiểm tra Wi-Fi rồi thử lại.',
    AppException(kind: AppErrorKind.permissionDenied, code: 'signed-out') =>
      'Phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại.',
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Chưa mở được camera hoặc thư viện ảnh. Cấp quyền trong Cài đặt rồi '
          'thử lại.',
    AppException(kind: AppErrorKind.invalidInput) =>
      'Ảnh chưa hợp lệ (JPG, PNG hoặc WebP, tối đa 5 MB). Chọn ảnh khác nhé.',
    _ => 'Chưa tải được ảnh. Thử lại nhé.',
  };
}
