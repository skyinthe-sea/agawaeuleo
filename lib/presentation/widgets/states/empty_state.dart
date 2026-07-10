import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';
import '../brand/ink_halo_icon.dart';
import '../buttons/primary_button.dart';
import '../dividers/brush_divider.dart';

/// §11.17 빈 상태. DESIGN v2 §5.4 — 워시 원을 [InkHaloIcon](122, animate)로,
/// 메시지 위에 [BrushDivider.center](위아래 12dp)를 추가했다. 진입 시 일러스트
/// 1회 미세 흔들림 + 텍스트 fadeIn은 그대로 유지. 문구는 "무엇을 하면 되는지"를 담는다.
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

  /// 커스텀 일러스트(미지정 시 [InkHaloIcon] 원형 자리표시자).
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
        InkHaloIcon(
          size: 122,
          icon: icon,
          washColor: colors.accentWash,
          fgColor: colors.accent,
          iconSize: 56,
          animate: true,
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
          const SizedBox(height: AppSpacing.x12),
          const BrushDivider.center(),
          const SizedBox(height: AppSpacing.x12),
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

    final content = Padding(
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
    );

    // 좁은 세로 공간(예: 헤더가 있는 화면의 빈 Expanded 영역, 큰 글꼴 배율)에서
    // 콘텐츠가 가용 높이를 넘으면 RenderFlex 오버플로가 나므로, 들어갈 때는
    // 기존과 동일하게 중앙 정렬하되 넘칠 때만 스크롤로 전환한다(시각 회귀 없음).
    // 반대로 이미 스크롤 가능한 무한 높이 컨텍스트(예: 트래킹 타임라인처럼
    // 부모가 SingleChildScrollView인 경우)에서는 높이가 무한대이므로 그 값을
    // minHeight로 강제하면 "infinite height" 오류가 나 — 이 경우는 기존과
    // 동일하게 자연스러운 높이의 Center만 사용한다.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
