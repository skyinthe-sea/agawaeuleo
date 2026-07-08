import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';
import '../buttons/primary_button.dart';

/// §11.17 빈 상태. 수묵 라인 일러스트(120) + display/body 안내 + (있으면) 행동 버튼.
/// 진입 시 일러스트 1회 미세 흔들림 + 텍스트 fadeIn. 문구는 "무엇을 하면 되는지"를 담는다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.brush_outlined,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// 커스텀 일러스트(미지정 시 [icon] 원형 자리표시자).
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget art =
        illustration ??
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: colors.accentWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 56, color: colors.accent),
        );
    if (!reduce) {
      art = art.animate().shake(
        hz: 3,
        offset: const Offset(2, 0),
        rotation: 0,
        duration: const Duration(milliseconds: 300),
        curve: AppMotion.standard,
      );
    }

    Widget textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: texts.display.copyWith(color: colors.ink900),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.x8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: texts.body.copyWith(color: colors.ink500),
          ),
        ],
      ],
    );
    if (!reduce) {
      textColumn = textColumn
          .animate()
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: 0.08, end: 0, curve: AppMotion.enter);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            const SizedBox(height: AppSpacing.x24),
            textColumn,
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.x24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
