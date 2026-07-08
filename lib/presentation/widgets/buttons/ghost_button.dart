import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';

/// §11.0 보조 버튼(Ghost). 높이 52 · r.sm · 투명 배경 · 보더 1dp line.strong · 텍스트 ink.700.
/// press 시 잉크 워시 + 미세 스케일, 로딩 시 라벨→스피너 크로스페이드.
class GhostButton extends StatefulWidget {
  const GhostButton({
    required this.label,
    super.key,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    AppHaptics.tap();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = context.reduceMotion;
    final Color foreground = _enabled ? colors.ink700 : colors.ink300;
    final Color border = _enabled ? colors.lineStrong : colors.line;
    final scale = (!reduce && _pressed) ? 0.97 : 1.0;

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      height: 52,
      width: widget.expand ? double.infinity : null,
      decoration: BoxDecoration(
        color: (_enabled && _pressed) ? colors.accentWash : Colors.transparent,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: border),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.brSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.accentWash,
          highlightColor: Colors.transparent,
          borderRadius: AppRadius.brSm,
          onTap: _enabled ? _handleTap : null,
          onHighlightChanged: _setPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: widget.loading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.ink700,
                        ),
                      ),
                    )
                  : _GhostLabel(
                      key: const ValueKey('label'),
                      label: widget.label,
                      icon: widget.icon,
                      color: foreground,
                    ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _handleTap : null,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: scale,
          duration: _pressed ? AppMotion.instant : AppMotion.base,
          curve: _pressed ? AppMotion.standard : AppMotion.spring,
          child: button,
        ),
      ),
    );
  }
}

class _GhostLabel extends StatelessWidget {
  const _GhostLabel({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: context.texts.label.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.iconTextGap),
        Flexible(child: text),
      ],
    );
  }
}
