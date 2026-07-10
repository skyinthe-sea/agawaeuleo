import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v2 §4.5 종이 그레인 표면. 배경색은 기존 Scaffold가 그대로 칠하고
/// 그 위에 §3.4 렌더 계약의 그레인 오버레이만 얹는다.
///
/// `MediaQuery.highContrast == true`면 그레인을 표시하지 않고 [child]만
/// 반환한다(§9 가드레일 — 접근성). 타일 1장을 GPU repeat로만 그리므로
/// 페인터 재실행이 없다.
///
/// 적용처: 3탭 셸 스크린 body, 스플래시, 온보딩, 증상 상세, 설정 등. `AppSheetShell`
/// 에서는 [opacityScale] 0.6으로 옅게 적용한다.
class PaperBackground extends StatelessWidget {
  const PaperBackground({
    required this.child,
    super.key,
    this.opacityScale = 1,
  });

  final Widget child;

  /// 그레인 불투명도 배율(기본 1.0 — `AppTexture.opacityOf` 그대로).
  final double opacityScale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).highContrast) return child;

    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final opacity = AppTexture.opacityOf(brightness) * opacityScale;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(AppTexture.grainAsset),
                  repeat: ImageRepeat.repeat,
                  opacity: opacity,
                  colorFilter: ColorFilter.mode(colors.ink900, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
