import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/image_ref.dart';

/// Ảnh đại diện của người dùng hiện tại (trường `photo` trong `users/{uid}`).
abstract interface class ProfilePhotoRepository {
  /// Ảnh hiện tại, `null` khi chưa có. Phát lại mỗi khi đổi.
  Stream<ImageRef?> watch();

  /// Lưu [photo]; `null` là gỡ ảnh.
  Future<void> save(ImageRef? photo);
}

/// Bản không làm gì: mặc định của provider, để các màn (và test) không gắn
/// Firestore vẫn dựng được.
class NoopProfilePhotoRepository implements ProfilePhotoRepository {
  const NoopProfilePhotoRepository();

  @override
  Stream<ImageRef?> watch() => Stream<ImageRef?>.value(null);

  @override
  Future<void> save(ImageRef? photo) async {}
}

final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>(
  (ref) => const NoopProfilePhotoRepository(),
);
