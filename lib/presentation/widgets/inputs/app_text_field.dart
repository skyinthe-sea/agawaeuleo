import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/shake.dart';

/// §11.0 입력창. 높이 52 · r.sm · 배경 paper.card · 보더 line(포커스 accent 1.5dp) ·
/// placeholder ink.300 · 패딩 16. 에러 시 coral 보더 + 흔들기 + 하단 caption + 라이트 햅틱.
/// obscure=true면 우측 눈 아이콘으로 표시/숨김 토글(§11.3).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.errorText,
    this.helperText,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;

  /// 제어형 에러 텍스트. null→non-null 전환 시 흔들기 + lightImpact.
  final String? errorText;
  final String? helperText;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;

  /// obscure=false일 때만 사용(비밀번호는 눈 토글이 우선).
  final Widget? suffixIcon;
  final int? maxLength;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;
  int _shakeTrigger = 0;

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gainedError =
        (oldWidget.errorText == null || oldWidget.errorText!.isEmpty) &&
        (widget.errorText != null && widget.errorText!.isNotEmpty);
    if (gainedError) {
      _shakeTrigger++;
      AppHaptics.tap();
    }
  }

  void _toggleObscured() {
    AppHaptics.toggle();
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget? suffix;
    if (widget.obscure) {
      suffix = IconButton(
        onPressed: widget.enabled ? _toggleObscured : null,
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: colors.ink500,
        ),
        tooltip: _obscured ? '비밀번호 표시' : '비밀번호 숨김',
      );
    } else {
      suffix = widget.suffixIcon;
    }

    return Shake(
      trigger: _shakeTrigger,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLength: widget.maxLength,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        style: context.texts.bodyL.copyWith(color: colors.ink900),
        cursorColor: colors.accent,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          errorText: (widget.errorText != null && widget.errorText!.isEmpty)
              ? null
              : widget.errorText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
