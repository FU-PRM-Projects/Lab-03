import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/image_ref.dart';

/// Chọn ảnh từ thư viện hoặc camera. Tách khỏi [ImageService] vì đây là SDK
/// thiết bị (widget và ViewModel không được gọi `image_picker`).
abstract interface class ImagePickerService {
  /// `null` khi người dùng đóng hộp chọn ảnh. Từ chối quyền là
  /// `AppException(permissionDenied)`.
  Future<PickedImage?> pick(ImagePickSource source);
}

/// Lưu ảnh trên Cloudinary.
abstract interface class ImageService {
  /// Tải [image] lên [folder]. Phát tiến độ; bước cuối có `image`. Lỗi là
  /// `AppException`; huỷ subscription thì huỷ luôn request.
  Stream<ImageUploadProgress> upload(
    PickedImage image, {
    required ImageFolder folder,
  });
}

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => throw UnimplementedError('imagePickerServiceProvider chưa được gắn'),
);

final imageServiceProvider = Provider<ImageService>(
  (ref) => throw UnimplementedError('imageServiceProvider chưa được gắn'),
);
