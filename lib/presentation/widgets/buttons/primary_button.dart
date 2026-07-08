import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';

/// §11.0 기본 버튼(Primary). 높이 52 · r.sm · 배경 accent · label/paper.raised · e2.
/// press 시 accent.deep + scale .97, 비활성 ink.300. 로딩 시 라벨→스피너 크로스페이드.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
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

  /// true면 가로로 꽉 채운다(기본).
  final bool expand;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
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
    final shadows = context.shadows;
    final reduce = context.reduceMotion;

    final Color background = !_enabled
        ? colors.ink300
        : (_pressed ? colors.accentDeep : colors.accent);
    final scale = (!reduce && _pressed) ? 0.97 : 1.0;

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      height: 52,
      width: widget.expand ? double.infinity : null,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brSm,
        boxShadow: _enabled ? shadows.e2 : const <BoxShadow>[],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.brSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.paperRaised.withValues(alpha: 0.18),
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
                          colors.paperRaised,
                        ),
                      ),
                    )
                  : _Label(
                      key: const ValueKey('label'),
                      label: widget.label,
                      icon: widget.icon,
                      color: colors.paperRaised,
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

class _Label extends StatelessWidget {
  const _Label({
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
