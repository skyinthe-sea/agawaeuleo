import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.2 페이지 인디케이터 — 활성 점이 알약으로 늘어난다.
///
/// 폭·색을 안착한 인덱스가 아니라 [controller]의 **연속 페이지 값**에 묶어,
/// 스와이프하는 동안 알약이 손가락을 따라 옆 점으로 흘러간다(탭 "다음"의
/// animateToPage도 같은 경로라 별도 트윈이 필요 없다).
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.controller,
    required this.count,
    required this.index,
    super.key,
  });

  final PageController controller;
  final int count;

  /// 컨트롤러가 붙기 전(첫 프레임) 기준 인덱스이자 시맨틱 값.
  final int index;

  static const double _dotSize = 6;
  static const double _activeWidth = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$count단계 중 ${index + 1}단계',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final page =
                controller.hasClients && controller.positions.length == 1
                ? controller.page ?? index.toDouble()
                : index.toDouble();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(count, (i) {
                final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.x4),
                  child: Container(
                    width: _dotSize + (_activeWidth - _dotSize) * t,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: Color.lerp(colors.lineStrong, colors.ink900, t),
                      borderRadius: AppRadius.brFull,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
