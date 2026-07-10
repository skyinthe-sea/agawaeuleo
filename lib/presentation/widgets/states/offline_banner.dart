import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §11.17 오프라인 배너. 상단 슬림 배너(amber 옅은 톤). 복구 시 위로 슬라이드업하며 사라진다.
/// [visible]로 표시 상태를 제어한다. reduce-motion 시 즉시 표시/숨김.
/// DESIGN v2 §5.4 — 배경을 `amber.withValues(alpha: 0.16)` 하드코딩 대신 신규
/// `amberWash` 토큰(§3.1)으로 교체.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.visible,
    super.key,
    this.message = '오프라인 상태예요 · 기록은 저장 후 자동 동기화됩니다',
    this.icon = Icons.cloud_off_rounded,
  });

  final bool visible;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = context.isDark ? colors.amber : colors.ink700;

    final banner = Container(
      key: const ValueKey('offline'),
      width: double.infinity,
      color: colors.amberWash,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.x8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: colors.amber),
          const SizedBox(width: AppSpacing.iconTextGap),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.texts.caption.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );

    return AnimatedSwitcher(
      duration: context.reduceMotion ? Duration.zero : AppMotion.base,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: const Alignment(-1, -1),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: visible ? banner : const SizedBox(width: double.infinity),
    );
  }
}
