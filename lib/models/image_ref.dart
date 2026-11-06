import 'dart:typed_data';

/// Thư mục logic của ảnh trên Cloudinary; cũng là tham số của
/// `imageUploadViewModelProvider`, để mỗi nơi dùng ảnh có state riêng.
enum ImageFolder {
  avatar('avatars'),
  note('notes'),
  group('groups'),
  challenge('challenges');

  const ImageFolder(this.id);

  final String id;
}

/// Nguồn chọn ảnh. Không đặt tên `ImageSource` để khỏi trùng với
/// `image_picker`.
enum ImagePickSource { gallery, camera }

/// Giới hạn ảnh. Ảnh được thu nhỏ ngay lúc chọn (xem
/// `DeviceImagePickerService`) nên [maxBytes] chỉ là lưới an toàn.
abstract final class ImageLimits {
  static const int maxBytes = 5 * 1024 * 1024;
  static const double maxSide = 1600;
  static const int quality = 85;
}

/// Ảnh đã lưu trên Cloudinary, tham chiếu bằng map `{url, publicId}` trong
/// tài liệu Firestore (hồ sơ, nốt, nhóm, thẻ thử thách).
class ImageRef {
  const ImageRef({required this.url, required this.publicId});

  /// Link HTTPS gốc (`secure_url`). Muốn ảnh nhỏ dùng `CloudinaryUrl`.
  final String url;

  /// Mã ảnh trên Cloudinary, để xoá / đổi phép biến đổi về sau.
  final String publicId;

  Map<String, Object?> toMap() => <String, Object?>{
    'url': url,
    'publicId': publicId,
  };

  /// `null` khi [raw] không phải map hợp lệ (tài liệu cũ chưa có ảnh).
  static ImageRef? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'];
    final publicId = raw['publicId'];
    if (url is! String || publicId is! String) return null;
    return ImageRef(url: url, publicId: publicId);
  }

  @override
  bool operator ==(Object other) =>
      other is ImageRef && other.url == url && other.publicId == publicId;

  @override
  int get hashCode => Object.hash(url, publicId);
}

/// Ảnh người dùng vừa chọn, còn nằm trên máy.
class PickedImage {
  const PickedImage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

/// Một bước của lần tải ảnh lên. [image] chỉ có ở bước cuối.
class ImageUploadProgress {
  const ImageUploadProgress(this.fraction, {this.image});

  /// 0–1.
  final double fraction;
  final ImageRef? image;
}
