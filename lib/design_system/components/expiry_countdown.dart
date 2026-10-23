import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';

enum ExpiryCountdownSize { small, large }

class ExpiryCountdown extends StatefulWidget {
  final DateTime? targetTime;
  final DateTime? expiryAt;
  final ExpiryCountdownSize size;
  final VoidCallback? onExpired;

  const ExpiryCountdown({
    super.key,
    this.targetTime,
    this.expiryAt,
    this.size = ExpiryCountdownSize.small,
    this.onExpired,
  });

  DateTime get effectiveTargetTime => targetTime ?? expiryAt ?? DateTime.now();

  @override
  State<ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<ExpiryCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late Duration _remaining;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(ExpiryCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effectiveTargetTime != widget.effectiveTargetTime) {
      _calculateRemaining();
      _startTimer();
    }
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    _remaining = widget.effectiveTargetTime.difference(now);
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }

    if (_remaining.inMinutes < 5 && _remaining > Duration.zero) {
      if (!_pulseController!.isAnimating) {
        _pulseController!.repeat(reverse: true);
      }
    } else {
      if (_pulseController!.isAnimating) {
        _pulseController!.stop();
        _pulseController!.value = 1.0;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining == Duration.zero) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _calculateRemaining();
      });
      if (_remaining == Duration.zero) {
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onExpired?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return 'Expired';
    }
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          'Expired',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final minutes = _remaining.inMinutes;
    Color textColor;
    if (minutes >= 15) {
      textColor = AppColors.textSecondary;
    } else if (minutes >= 5) {
      textColor = AppColors.warning;
    } else {
      textColor = AppColors.error;
    }

    final formattedStr = _formatDuration(_remaining);

    if (widget.size == ExpiryCountdownSize.large) {
      return FadeTransition(
        opacity: minutes < 5
            ? _pulseAnimation!
            : const AlwaysStoppedAnimation(1.0),
        child: Text(
          formattedStr,
          style: AppTextStyles.timerLarge.copyWith(color: textColor),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: minutes < 5
            ? AppColors.errorContainer
            : (minutes < 15
                  ? AppColors.bgReserved
                  : AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: FadeTransition(
        opacity: minutes < 5
            ? _pulseAnimation!
            : const AlwaysStoppedAnimation(1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: 14.0, color: textColor),
            const SizedBox(width: 4.0),
            Text(
              formattedStr,
              style: AppTextStyles.timerSmall.copyWith(
                fontSize: 12.0,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
