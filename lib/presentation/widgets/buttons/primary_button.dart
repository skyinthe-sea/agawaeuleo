import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';
import '../surfaces/clay_sheen.dart';

/// §11.0 기본 버튼(Primary) — DESIGN v3 §5.2 "젤리 알약".
///
/// 높이 54 · 알약(`brFull`) · `accent` 면 + 클레이 광택([ClaySheen.gradient]) +
/// 자기 색 톤 그림자([ClaySheen.toneShadow]) · 글자 `label`/`paperRaised`.
/// 누르면 면이 `accentDeep` 쪽으로 가라앉고 그림자가 바짝 줄며 scale .97로 말랑하게
/// 눌린다. 비활성은 `ink300` 무광(그림자 없음). 로딩 시 라벨→스피너 크로스페이드.
///
/// [expand]가 false면 글자 폭에 맞춘 작은 알약이 된다(빈 상태·에러의 "다시 시도" 등).
/// [tone]으로 면 색을 바꿀 수 있다(응급·파괴 동작의 `coral` 등 의미 색 전용).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.tone,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// true면 가로로 꽉 채운다(기본).
  final bool expand;

  /// 알약 면 색(미지정 시 `accent`, 눌림 `accentDeep`). 지정 색의 눌림은 그 색을
  /// `ink900` 쪽으로 18% 옮긴 값이다(다크에서는 `ink900`이 밝아 자동으로 뒤집힌다).
  final Color? tone;

  /// 알약 높이(DESIGN v3 §5.2).
  static const double height = 54;

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
    final reduce = context.reduceMotion;

    // 기본 면은 딸기 핑크 accentFill — 글자를 큰 주아체로 올려 WCAG 큰 텍스트 대비를 맞춘다.
    final Color tone = widget.tone ?? colors.accentFill;
    final Color pressedTone = widget.tone == null
        ? colors.accent
        : Color.lerp(tone, colors.ink900, 0.18)!;
    final Color face = !_enabled
        ? colors.ink300
        : (_pressed ? pressedTone : tone);
    final scale = (!reduce && _pressed) ? 0.97 : 1.0;

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      height: PrimaryButton.height,
      width: widget.expand ? double.infinity : null,
      decoration: BoxDecoration(
        color: _enabled ? null : face,
        gradient: _enabled ? ClaySheen.gradient(context, face) : null,
        borderRadius: AppRadius.brFull,
        boxShadow: _enabled
            ? ClaySheen.toneShadow(context, tone, pressed: _pressed)
            : const <BoxShadow>[],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.brFull,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.paperRaised.withValues(alpha: 0.18),
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
      // 주아체 19(`heading`) — 채운 알약 위 글자는 큰 텍스트로(§3.1 accentFill 규칙).
      style: context.texts.heading.copyWith(color: color, height: 1.2),
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
