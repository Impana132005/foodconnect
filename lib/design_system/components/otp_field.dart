import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';

class OTPField extends StatefulWidget {
  final int length;
  final bool enabled;
  final bool isError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  const OTPField({
    super.key,
    this.length = 6,
    this.enabled = true,
    this.isError = false,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OTPField> createState() => _OTPFieldState();
}

class _OTPFieldState extends State<OTPField>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _otpValues;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _otpValues = List.filled(widget.length, '');

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void didUpdateWidget(OTPField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController
          .forward(from: 0.0)
          .then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Handle pasting a full code
      final pasteValue = value.trim();
      for (var i = 0; i < widget.length && i < pasteValue.length; i++) {
        _controllers[i].text = pasteValue[i];
        _otpValues[i] = pasteValue[i];
      }
      _triggerCallback();
      FocusScope.of(context).unfocus();
      return;
    }

    _otpValues[index] = value;
    _triggerCallback();

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _triggerCallback() {
    final otp = _otpValues.join('');
    widget.onChanged(otp);
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final isFocused = _focusNodes[index].hasFocus;

              return SizedBox(
                width: 46.0,
                height: 54.0,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _controllers[index].text.isEmpty &&
                        index > 0) {
                      _focusNodes[index - 1].requestFocus();
                      _controllers[index - 1].clear();
                      _otpValues[index - 1] = '';
                      _triggerCallback();
                    }
                  },
                  child: TextFormField(
                    enabled: widget.enabled,
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: widget.isError
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      fillColor: isFocused
                          ? AppColors.primaryContainer.withValues(alpha: 0.3)
                          : AppColors.surfaceContainerHigh,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: widget.isError
                              ? AppColors.error
                              : AppColors.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: widget.isError
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onChanged(value, index),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

typedef OtpField = OTPField;
