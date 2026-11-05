import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../models/image_ref.dart';
import '../services/app_exception.dart';
import '../services/image_service.dart';

/// [ImagePickerService] bằng `image_picker`. Ảnh được thu nhỏ ngay khi chọn
/// (cạnh dài tối đa [ImageLimits.maxSide], chất lượng [ImageLimits.quality])
/// nên không cần gói nén riêng và upload nhanh trên mạng yếu.
class DeviceImagePickerService implements ImagePickerService {
  DeviceImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(ImagePickSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == ImagePickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: ImageLimits.maxSide,
        maxHeight: ImageLimits.maxSide,
        imageQuality: ImageLimits.quality,
      );
      if (file == null) return null;
      return PickedImage(bytes: await file.readAsBytes(), fileName: file.name);
    } on PlatformException catch (e) {
      throw AppException(
        switch (e.code) {
          'camera_access_denied' ||
          'photo_access_denied' ||
          // iOS: bị hạn chế bởi Screen Time / quản trị thiết bị.
          'camera_access_restricted' ||
          'photo_access_restricted' => AppErrorKind.permissionDenied,
          _ => AppErrorKind.unknown,
        },
        code: e.code,
        detail: e.message,
      );
    }
  }
}
