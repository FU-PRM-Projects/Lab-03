import 'package:material_ui/material_ui.dart';

import '../models/image_ref.dart';
import '../theme/app_tokens.dart';
import '../viewmodels/image_upload_view_model.dart';
import 'app_button.dart';
import 'app_network_image.dart';

/// Khối "Thêm ảnh": xem trước, nút Thư viện / Chụp ảnh, tiến độ tải lên,
/// thông báo lỗi và nút Gỡ ảnh.
///
/// Widget thuần: không gọi service. Màn hình truyền [upload] (state của
/// `imageUploadViewModelProvider`) và nối các callback vào ViewModel.
class AppImagePicker extends StatelessWidget {
  const AppImagePicker({
    required this.upload,
    required this.image,
    required this.previewLabel,
    required this.onPick,
    this.onCancel,
    this.onRemove,
    this.circle = false,
    this.aspectRatio = 16 / 9,
    super.key,
  });

  /// Trạng thái lần chọn / tải ảnh hiện tại.
  final ImageUploadState upload;

  /// Ảnh đang gắn (đã lưu hoặc vừa tải xong); `null` là chưa có.
  final ImageRef? image;

  /// Mô tả bản xem trước cho TalkBack.
  final String previewLabel;
  final ValueChanged<ImagePickSource> onPick;

  /// Có thì hiện nút "Huỷ" khi đang tải lên.
  final VoidCallback? onCancel;

  /// Có thì hiện nút "Gỡ ảnh" khi đã có ảnh.
  final VoidCallback? onRemove;

  /// Xem trước hình tròn 96 dp (avatar) thay vì khung 16:9.
  final bool circle;

  /// Tỉ lệ khung xem trước hình chữ nhật (rộng / cao). Mặc định 16:9.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final busy = upload.busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s12,
      children: <Widget>[
        if (circle)
          Center(
            child: AppNetworkImage.square(
              image: image,
              semanticLabel: previewLabel,
              size: 96,
              circle: true,
            ),
          )
        else
          AppNetworkImage.wide(
            image: image,
            semanticLabel: previewLabel,
            aspectRatio: aspectRatio,
          ),
        if (busy)
          _Progress(upload: upload, onCancel: onCancel)
        else if (upload.phase == ImageUploadPhase.failed &&
            upload.message != null)
          _ErrorMessage(message: upload.message!),
        Row(
          spacing: AppSpace.s8,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Thư viện',
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: busy ? null : () => onPick(ImagePickSource.gallery),
              ),
            ),
            Expanded(
              child: AppButton(
                label: 'Chụp ảnh',
                icon: Icons.photo_camera_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: busy ? null : () => onPick(ImagePickSource.camera),
              ),
            ),
          ],
        ),
        if (image != null && onRemove != null && !busy)
          AppButton(
            label: 'Gỡ ảnh',
            icon: Icons.delete_outline,
            variant: AppButtonVariant.text,
            onPressed: onRemove,
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.upload, required this.onCancel});

  final ImageUploadState upload;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final uploading = upload.phase == ImageUploadPhase.uploading;
    final percent = (upload.progress * 100).round();
    final text = uploading
        ? 'Đang tải ảnh lên… $percent%'
        : 'Đang mở thư viện ảnh…';

    return Semantics(
      liveRegion: true,
      label: uploading ? 'Đang tải ảnh lên, $percent phần trăm' : text,
      // Không dùng excludeSemantics: nó sẽ loại luôn nút "Huỷ" bên trong.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s8,
        children: <Widget>[
          LinearProgressIndicator(value: uploading ? upload.progress : null),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (uploading && onCancel != null)
                AppButton(
                  label: 'Huỷ',
                  variant: AppButtonVariant.text,
                  onPressed: onCancel,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lỗi chọn / tải ảnh: có icon và chữ, không chỉ dựa vào màu đỏ.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s8,
        children: <Widget>[
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
