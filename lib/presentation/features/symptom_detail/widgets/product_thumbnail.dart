import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_parallax.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/animated/shimmer_skeleton.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-6 제품 썸네일 — "폭신한 크림 쿠션"(DESIGN v3 "몽글 클레이").
///
/// 상품 사진을 그냥 얹지 않고 `paperBg` 크림 면 + 흰 스티커 테두리(`paperRaised` 2)
/// + e1 그림자의 둥근 쿠션 위에 앉혀, 흰 배경 상품 컷이 카드 면과 섞이지 않고
/// **말랑한 받침** 위에 놓인 것처럼 보이게 한다.
///
/// 모션(전부 reduce-motion 시 정지):
/// - 로딩 → 표시: 시머에서 사진으로 크로스페이드(§10.2).
/// - 스크롤: 프레임 안에서 사진만 아주 조금 미끄러지는 패럴랙스([ScrollParallax]).
///   미끄러질 여유분만큼 사진을 미리 확대해 두어 가장자리 빈틈을 막는다.
/// - [breathe](히어로 전용): 아주 느린 호흡 스케일.
///
/// URL이 없거나(픽스처·미등록) 로드에 실패하면 크림 쿠션 위 딸기 워시 버블
/// 플레이스홀더가 자리를 지킨다(이때는 패럴랙스를 걸지 않는다 — 가운데 아이콘이
/// 흔들려 보이므로).
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.imageUrl,
    required this.size,
    super.key,
    this.radius = AppRadius.brMd,
    this.breathe = false,
  });

  final String? imageUrl;
  final double size;
  final BorderRadius radius;

  /// 히어로 카드 전용 — 아주 느린 호흡(scale 1↔1.03) 반복.
  final bool breathe;

  /// 프레임 크기 대비 패럴랙스 이동 비율(상하 각각). 확대 배율도 여기서 파생된다.
  ///
  /// 확대한 만큼 상품 사진이 잘리므로 값을 키우지 말 것 — 쿠팡 상품 컷은 흰 여백이
  /// 좁은 경우가 많아 6%만 넘어가도 제품 끝이 잘려 보인다(실기기 확인).
  static const double _parallaxRatio = 0.035;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = imageUrl?.trim() ?? '';

    // 사진이 없을 때의 대역 — 사진 자리를 대신하는 장식이므로 `InkHaloIcon`
    // (아이콘-in-원 어피던스)이 아니라 링 없는 클레이 버블로 조용히 처리한다.
    final placeholder = PaperBackground(
      child: Center(
        child: ClayBubble(
          size: size * 0.46,
          wash: colors.accentWash,
          icon: Icons.shopping_bag_rounded,
          iconColor: colors.accent,
          iconSize: size * 0.24,
        ),
      ),
    );

    final Widget content;
    if (url.isEmpty) {
      content = placeholder;
    } else {
      // 원본이 크므로(쿠팡 CDN 512px+) 프레임 실제 픽셀에 맞춰 디코딩한다.
      final cacheWidth =
          (size *
                  (1 + _parallaxRatio * 2) *
                  MediaQuery.devicePixelRatioOf(context))
              .round();
      final image = Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: cacheWidth,
        // 첫 프레임 도착 시 시머 → 사진 크로스페이드(팝인 방지).
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.base),
            switchInCurve: AppMotion.enter,
            child: frame == null
                ? ShimmerSkeleton(
                    key: const ValueKey('loading'),
                    width: size,
                    height: size,
                    borderRadius: radius,
                    baseColor: colors.paperStack,
                  )
                : KeyedSubtree(key: const ValueKey('image'), child: child),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );

      content = ScrollParallax(
        maxOffset: size * _parallaxRatio,
        // 카드가 등장하는 동안 사진이 살짝 확대된 채로 들어와 제자리에 앉는다
        // (프레임이 클리핑하므로 확대분이 밖으로 새지 않는다).
        child: RevealMotion(
          end: 0.8,
          scaleFrom: 1.06,
          child: Transform.scale(
            scale: 1 + _parallaxRatio * 2,
            child: _maybeBreathe(context, image),
          ),
        ),
      );
    }

    // 흰 테두리는 전경으로 덧그린다 — 사진 가장자리를 말끔히 감싸고, 사진 자리는
    // 프레임 전체를 그대로 쓴다(패럴랙스 확대 계산 불변).
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: radius,
        boxShadow: context.shadows.e1,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.paperRaised, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _maybeBreathe(BuildContext context, Widget child) {
    if (!breathe || context.reduceMotion) return child;
    // 모션 토큰 파생값(shimmer 1200ms × 3 = 3.6s) — 눈에 띄지 않을 만큼 느린 호흡.
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleXY(
          begin: 1,
          end: 1.03,
          duration: AppMotion.shimmer * 3,
          curve: AppMotion.standard,
        );
  }
}
