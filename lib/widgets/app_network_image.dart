import 'package:material_ui/material_ui.dart';

import '../models/image_ref.dart';
import '../theme/app_tokens.dart';
import '../utils/cloudinary_url.dart';

/// Hiển thị một [ImageRef] trên Cloudinary với đủ 3 trạng thái:
/// đang tải (ô xám + vòng xoay), lỗi (chạm để thử lại) và chưa có ảnh.
///
/// URL được đổi sang bản đã cắt / nén cho đúng kích thước hiển thị
/// (`CloudinaryUrl`), nên ảnh nhỏ không tải cả file gốc.
class AppNetworkImage extends StatefulWidget {
  /// Ô vuông [size] dp: avatar, ảnh nhóm, thumbnail. [circle] cho avatar.
  const AppNetworkImage.square({
    required this.image,
    required this.semanticLabel,
    required this.size,
    this.circle = false,
    this.fallback,
    super.key,
  }) : aspectRatio = null;

  /// Rộng hết chiều ngang của cha, giữ tỉ lệ [aspectRatio]: ảnh trong nốt.
  const AppNetworkImage.wide({
    required this.image,
    required this.semanticLabel,
    this.aspectRatio = 4 / 3,
    this.fallback,
    super.key,
  }) : size = null,
       circle = false;

  /// `null` là chưa có ảnh: hiện [fallback] hoặc ô xám có icon.
  final ImageRef? image;

  /// Mô tả ảnh cho TalkBack (ví dụ "Ảnh đại diện").
  final String semanticLabel;
  final double? size;
  final double? aspectRatio;
  final bool circle;

  /// Nội dung thay thế khi chưa có ảnh (ví dụ avatar mặc định).
  final Widget? fallback;

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  /// Tăng khi chạm "thử lại" để Image.network tải lại.
  int _attempt = 0;

  /// Làm tròn lên bội số của 32 px để các màn dùng chung vài URL, đỡ tải trùng.
  static int _pixels(double dp, double ratio) =>
      ((dp * ratio / 32).ceil() * 32).clamp(64, 1024);

  @override
  Widget build(BuildContext context) {
    final ref = widget.image;
    final size = widget.size;
    final ratio = MediaQuery.devicePixelRatioOf(context);

    final Widget content;
    if (ref == null) {
      content = widget.fallback ?? const _Placeholder(icon: Icons.image_outlined);
    } else {
      final url = size != null
          ? CloudinaryUrl.thumb(ref.url, size: _pixels(size, ratio))
          : CloudinaryUrl.fit(ref.url, width: 800);
      content = Image.network(
        url,
        key: ValueKey<String>('$url#$_attempt'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _Placeholder(loading: true),
        errorBuilder: (context, error, stack) =>
            _ErrorPlaceholder(onRetry: () => setState(() => _attempt++)),
      );
    }

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.circle ? AppRadius.full : AppRadius.r12,
      ),
      child: content,
    );
    final sized = size != null
        ? SizedBox.square(dimension: size, child: clipped)
        : AspectRatio(aspectRatio: widget.aspectRatio!, child: clipped);

    return Semantics(image: true, label: widget.semanticLabel, child: sized);
  }
}

/// Ô xám nền `surface-container-highest`: đang tải hoặc chưa có ảnh.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.icon, this.loading = false});

  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Lỗi tải ảnh: biểu tượng ảnh hỏng, chạm để thử lại (không chỉ dựa vào màu).
class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Không tải được ảnh. Chạm để thử lại',
      excludeSemantics: true,
      child: InkWell(
        onTap: onRetry,
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
