import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';
import '../brand/ink_halo_icon.dart';
import '../buttons/primary_button.dart';
import '../dividers/brush_divider.dart';
import 'clay_scene_art.dart';

/// §11.17 빈 상태 — DESIGN v3 §5.5 "몽글 클레이".
///
/// 그림 자리는 우선순위대로 [illustration](임의 위젯) → [illustrationAsset](클레이
/// 장면 140 + 딸기 wash 쿠션, 보통 `ClayScenes.emptySearch/emptyHeart`) → 클레이 버블
/// [InkHaloIcon](122, animate)이다. 제목은 주아체 `display`, 메시지 위에 몽글 점선
/// [BrushDivider.center](위아래 12dp). 진입 시 그림 1회 미세 흔들림 + 텍스트 fadeIn은
/// 그대로 유지. 문구는 "무엇을 하면 되는지"를 담는다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.auto_awesome_rounded,
    this.illustration,
    this.illustrationAsset,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// 커스텀 일러스트(최우선). 미지정 시 [illustrationAsset] → [InkHaloIcon] 순.
  final Widget? illustration;

  /// 클레이 장면 에셋 경로(예: `ClayScenes.emptySearch`). 지정 시 아이콘 버블 대신
  /// 딸기 wash 쿠션 위의 클레이 장면(140)을 그린다.
  final String? illustrationAsset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    final asset = illustrationAsset;
    Widget art =
        illustration ??
        (asset != null
            ? ClaySceneArt(asset: asset, wash: colors.accentWash)
            : InkHaloIcon(
                size: 122,
                icon: icon,
                washColor: colors.accentWash,
                fgColor: colors.accent,
                iconSize: 56,
                animate: true,
              ));
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
