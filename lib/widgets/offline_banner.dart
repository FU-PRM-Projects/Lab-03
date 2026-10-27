import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Banner "Offline · đã lưu trên máy" ở đầu nội dung (S02, S04, S05).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    this.title = 'Offline · đã lưu trên máy',
    this.detail = 'Sẽ tự đồng bộ khi có mạng.',
    super.key,
  });

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.of(context).tintGray,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Row(
            children: <Widget>[
              Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
