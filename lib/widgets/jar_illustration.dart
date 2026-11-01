import 'package:material_ui/material_ui.dart';

import '../models/note_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'mascot.dart';

/// `Illustration/Hũ chiến thắng` vẽ bằng widget: thân hũ có các tờ nốt màu
/// theo loại, mascot Xong đứng cạnh (deviation D-14, chờ export SVG từ Figma).
class JarIllustration extends StatelessWidget {
  const JarIllustration({
    required this.notes,
    required this.semanticLabel,
    this.onTap,
    this.height = 240,
    super.key,
  });

  /// Loại của các tờ nốt trong hũ, mới nhất trước.
  final List<NoteType> notes;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double height;

  static const Size _slip = Size(40, 28);
  static const double _slipTilt = 0.12;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final jarRadius = BorderRadius.circular(AppRadius.nav);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  // Nắp hũ.
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      height: AppSpace.s20,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Expanded(
                    child: Material(
                      color: colors.tintLavender,
                      shape: RoundedRectangleBorder(
                        borderRadius: jarRadius,
                        side: BorderSide(
                          color: scheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.s16),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpace.s6,
                              runSpacing: AppSpace.s6,
                              verticalDirection: VerticalDirection.up,
                              children: <Widget>[
                                for (final (i, type) in notes.indexed)
                                  Transform.rotate(
                                    // Nghiêng nhẹ xen kẽ để giống tờ nốt thả vào hũ.
                                    angle: (i.isEven ? 1 : -1) * _slipTilt,
                                    child: Container(
                                      width: _slip.width,
                                      height: _slip.height,
                                      decoration: BoxDecoration(
                                        color: colors.noteTint(type),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.r4,
                                        ),
                                        border: Border.all(
                                          color: scheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            const Mascot(state: MascotState.xong, size: 72),
          ],
        ),
      ),
    );
  }
}
