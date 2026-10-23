import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailingWidget = trailing;
    if (trailingWidget == null && actionLabel != null && onActionTap != null) {
      trailingWidget = InkWell(
        onTap: onActionTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Text(
            actionLabel!,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.sectionLabel),
          ?trailingWidget,
        ],
      ),
    );
  }
}
