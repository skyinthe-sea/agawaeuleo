import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_parallax.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/animated/shimmer_skeleton.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-6 제품 썸네일 — "옴폭한 종이 우물".
///
/// 상품 사진을 그냥 얹지 않고 `paperBg`(카드면보다 어두운 종이) + `line` 헤어라인
/// 프레임 안에 앉혀, 흰 배경 상품 컷이 카드 위에 떠 있지 않고 **면에 파인 자리**에
/// 놓인 것처럼 보이게 한다(DESIGN v2 §2 "묵직한 페이퍼잉크").
///
/// 모션(전부 reduce-motion 시 정지):
/// - 로딩 → 표시: 시머에서 사진으로 크로스페이드(§10.2).
/// - 스크롤: 프레임 안에서 사진만 아주 조금 미끄러지는 패럴랙스([ScrollParallax]).
///   미끄러질 여유분만큼 사진을 미리 확대해 두어 가장자리 빈틈을 막는다.
/// - [breathe](히어로 전용): 아주 느린 호흡 스케일.
///
/// URL이 없거나(픽스처·미등록) 로드에 실패하면 그레인 종이 위 워시 원
/// 플레이스홀더가 자리를 지킨다(이때는 패럴랙스를 걸지 않는다 — 가운데 아이콘이
/// 흔들려 보이므로).
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.imageUrl,
    required this.size,
    super.key,
    this.radius = AppRadius.brSm,
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
    // (아이콘-in-원 어피던스)이 아니라 링 없는 워시 원으로 조용히 처리한다.
    final placeholder = PaperBackground(
      child: Center(
        child: Container(
          width: size * 0.44,
          height: size * 0.44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accentWash,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: size * 0.24,
            color: colors.accent,
          ),
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
                    baseColor: colors.line,
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
          end: 0.9,
          scaleFrom: 1.1,
          child: Transform.scale(
            scale: 1 + _parallaxRatio * 2,
            child: _maybeBreathe(context, image),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: radius,
        border: Border.all(color: colors.line),
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
