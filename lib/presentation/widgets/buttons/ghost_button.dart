import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';

/// §11.0 보조 버튼(Ghost) — DESIGN v3 §5.2 "말랑 알약".
///
/// 높이 54 · 알약(`brFull`) · `paperRaised` 면 + `lineStrong` 1.5 윤곽 · 글자
/// `label`/`ink700`. 누르면 면이 `accentWash`(딸기 워시)로 물들고 scale .97로
/// 말랑하게 눌린다. 비활성은 `line` 윤곽 + `ink300` 글자. 로딩 시 라벨→스피너
/// 크로스페이드. [expand]가 false면 글자 폭에 맞춘 작은 알약이 된다.
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
      height: 54,
      width: widget.expand ? double.infinity : null,
      decoration: BoxDecoration(
        color: (_enabled && _pressed) ? colors.accentWash : colors.paperRaised,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.brFull,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.accentWash,
          highlightColor: Colors.transparent,
          borderRadius: AppRadius.brFull,
          onTap: _enabled ? _handleTap : null,
          onHighlightChanged: _setPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
            child: Center(
              widthFactor: widget.expand ? null : 1,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: widget.loading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          strokeCap: StrokeCap.round,
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
