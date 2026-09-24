import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §11.17 오프라인 배너 — DESIGN v3 "몽글 클레이" 버터 스티커 알약.
///
/// 상단 가운데에 떠 있는 작은 알약(`amberWash` 면 + 흰 스티커 테두리 `paperRaised`
/// 2dp + e1)으로, 아이콘은 `amber`, 글자는 `ink700`(다크는 대비를 위해 `amber`).
/// 복구 시 위로 접히며 사라진다. [visible]로 표시 상태를 제어한다. reduce-motion 시
/// 즉시 표시/숨김.
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

    final banner = Padding(
      key: const ValueKey('offline'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x8,
        AppSpacing.x16,
        AppSpacing.x4,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x8,
          ),
          decoration: BoxDecoration(
            color: colors.amberWash,
            borderRadius: AppRadius.brFull,
            border: Border.all(color: colors.paperRaised, width: 2),
            boxShadow: context.shadows.e1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.amber),
              const SizedBox(width: AppSpacing.iconTextGap),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.texts.caption.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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
