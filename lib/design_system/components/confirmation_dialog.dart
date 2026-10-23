import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import 'app_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  static void _defaultCancel() {}

  const ConfirmationDialog({
    super.key,
    required this.title,
    String? message,
    String? description,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    VoidCallback? onCancel,
    this.isDestructive = false,
  }) : message = message ?? description ?? '',
       onCancel = onCancel ?? _defaultCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1.0),
      ),
      titlePadding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: 8.0,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 8.0,
      ),
      actionsPadding: const EdgeInsets.all(24.0),
      title: Text(title, style: AppTextStyles.titleMedium),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDestructive)
              DestructiveButton(
                text: confirmLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              )
            else
              AppButton(
                text: confirmLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            const SizedBox(height: 8.0),
            SecondaryButton(
              text: cancelLabel,
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper method to easily show the dialog
Future<void> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      );
    },
  );
}
