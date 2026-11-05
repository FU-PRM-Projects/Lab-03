import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../models/image_ref.dart';
import '../services/app_exception.dart';
import '../services/image_service.dart';

/// [ImageService] trên Cloudinary bằng unsigned upload preset.
///
/// Không có API secret trong app: chỉ `cloudName` và `uploadPreset` (truyền
/// bằng `--dart-define`). Giới hạn định dạng / dung lượng đặt ở preset trên
/// Cloudinary. Unsigned upload không xoá được ảnh từ máy khách, nên "xoá
/// ảnh" chỉ gỡ tham chiếu trong Firestore.
class CloudinaryImageService implements ImageService {
  CloudinaryImageService({
    required this.currentUid,
    required this.cloudName,
    required this.uploadPreset,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 60),
               receiveTimeout: const Duration(seconds: 30),
             ),
           );

  /// Uid của người đang đăng nhập; chỉ dùng để chặn tải ảnh khi đã đăng xuất.
  final String? Function() currentUid;
  final String cloudName;
  final String uploadPreset;
  final Dio _dio;

  @override
  Stream<ImageUploadProgress> upload(
    PickedImage image, {
    required ImageFolder folder,
  }) {
    final controller = StreamController<ImageUploadProgress>();
    final cancelToken = CancelToken();
    controller.onCancel = () {
      if (!cancelToken.isCancelled) cancelToken.cancel();
    };
    unawaited(_run(image, folder, controller, cancelToken));
    return controller.stream;
  }

  Future<void> _run(
    PickedImage image,
    ImageFolder folder,
    StreamController<ImageUploadProgress> out,
    CancelToken cancelToken,
  ) async {
    try {
      if (currentUid() == null) {
        throw const AppException(
          AppErrorKind.permissionDenied,
          code: 'signed-out',
        );
      }
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw const AppException(
          AppErrorKind.unknown,
          code: 'cloudinary-not-configured',
          detail: 'Thiếu CLOUDINARY_CLOUD_NAME / CLOUDINARY_UPLOAD_PRESET.',
        );
      }
      final form = FormData.fromMap(<String, Object>{
        'file': MultipartFile.fromBytes(image.bytes, filename: image.fileName),
        'upload_preset': uploadPreset,
        // public_id ngẫu nhiên: không đoán được, không ghi đè được.
        'public_id': 'not/${folder.id}/${_randomId()}',
      });
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: form,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total > 0 && !out.isClosed) {
            // Dành 5% cuối cho lúc server xử lý.
            out.add(ImageUploadProgress(sent / total * 0.95));
          }
        },
      );
      final data = response.data;
      final url = data?['secure_url'];
      final publicId = data?['public_id'];
      if (url is! String || publicId is! String) {
        throw const AppException(
          AppErrorKind.unknown,
          code: 'cloudinary-bad-response',
        );
      }
      out.add(
        ImageUploadProgress(1, image: ImageRef(url: url, publicId: publicId)),
      );
    } on DioException catch (e, stack) {
      if (!out.isClosed) out.addError(_map(e), stack);
    } on Object catch (e, stack) {
      if (!out.isClosed) out.addError(e, stack);
    } finally {
      await out.close();
    }
  }

  static String? _cloudinaryMessage(Object? body) {
    if (body is Map && body['error'] is Map) {
      final message = (body['error'] as Map)['message'];
      if (message is String) return message;
    }
    return null;
  }

  static AppException _map(DioException e) {
    final message = _cloudinaryMessage(e.response?.data);
    switch (e.type) {
      case DioExceptionType.cancel:
        return const AppException(AppErrorKind.cancelled, code: 'cancelled');
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException(AppErrorKind.network, code: e.type.name);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        // 400 do ảnh sai định dạng / quá lớn là lỗi của người dùng; 400 do
        // preset sai là lỗi cấu hình nên phải lên Crashlytics (kind unknown).
        final presetProblem = (message ?? '').toLowerCase().contains('preset');
        return AppException(
          status == 400 && !presetProblem
              ? AppErrorKind.invalidInput
              : AppErrorKind.unknown,
          code: 'cloudinary-$status',
          detail: message,
        );
      default:
        return AppException(
          AppErrorKind.unknown,
          code: e.type.name,
          detail: e.message,
        );
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return List<int>.generate(
      12,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
