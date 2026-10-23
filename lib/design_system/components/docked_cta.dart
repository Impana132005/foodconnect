import 'package:flutter/material.dart';
import '../app_colors.dart';

class DockedCTA extends StatelessWidget {
  final Widget child;

  const DockedCTA({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: bottomPadding > 0 ? bottomPadding : 16.0,
      ),
      child: child,
    );
  }
}

typedef DockedCta = DockedCTA;
