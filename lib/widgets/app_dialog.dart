import 'package:material_ui/material_ui.dart';

import 'app_button.dart';

/// Kiểu của component `Dialog` Lab 2.
enum AppDialogKind { confirmation, destructive }

/// Component `Dialog`: nút phụ bên trái, nút chính bên phải.
///
/// Trả về `true` khi chọn nút chính, `false` khi chọn nút phụ, `null` khi
/// đóng bằng Back hoặc chạm ra ngoài (tương đương nút phụ).
Future<bool?> showAppDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Huỷ',
  AppDialogKind kind = AppDialogKind.confirmation,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AppDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      kind: kind,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onCancel,
    required this.onConfirm,
    this.kind = AppDialogKind.confirmation,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final AppDialogKind kind;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        AppButton(
          label: cancelLabel,
          onPressed: onCancel,
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: onConfirm,
          variant: kind == AppDialogKind.destructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.filled,
        ),
      ],
    );
  }
}
