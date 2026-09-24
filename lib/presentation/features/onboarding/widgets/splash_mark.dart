import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../config/theme/theme.dart';
import '../../../widgets/symptom/symptom_illustration.dart';

/// 스플래시 브랜드 배지 — DESIGN v3 §6 "딸기 핑크 원형 배지 + 클레이 아가 얼굴".
///
/// 딸기 핑크(`seal`) 원 안에 클레이 아가 얼굴을 담아, [smile] 진행도에 따라 우는
/// 얼굴([ClayScenes.babyCry])에서 방긋 웃는 얼굴([ClayScenes.babySmile])로 바뀐다
/// ("아가 왜 울어?" → 달래졌다). 바뀌는 순간 얼굴이 한 번 말랑하게 눌렸다가(스쿼시)
/// 쫀득하게 늘어나며(스트레치) 제자리를 찾는다.
///
/// **에셋 계약** — 두 WebP는 같은 정사각 프레이밍(투명 배경, 얼굴 가운데, 귀까지 포함한
/// 얼굴 폭이 이미지 폭의 약 78%)이라 같은 자리에 겹쳐 크로스페이드한다. 눈물은 에셋에
/// 굽지 않고 여기서 벡터로 그린다([tear]) — 흘러내려 사라져야 하기 때문이다.
///
/// **네이티브 배지 계약** — 원 지름 대비 얼굴 이미지 박스 비율 [markRatio](0.78)는
/// 네이티브 런치 배지(seal 원 + babyCry 이미지, 벡터 눈물 없음)와 같다. 한쪽을 바꾸면
/// 다른 쪽도 함께 바꿀 것. 첫 프레임(smile 0 · tear 0)은 벡터 눈물이 아직 맺히기 전이라
/// 네이티브 배지와 픽셀 단위로 같다.
///
/// 색은 앱 아이콘과 같은 **브랜드 고정값**(라이트 팔레트 토큰)이다. 다크 모드에서도
/// 네이티브 런치 배지와 같은 색이어야 이음새가 보이지 않는다.
class SplashMark extends StatelessWidget {
  const SplashMark({
    required this.size,
    this.smile = 0,
    this.tear = 0,
    super.key,
  });

  /// 배지(원) 지름.
  final double size;

  /// 0 = 우는 얼굴 → 1 = 방긋 웃는 얼굴.
  final double smile;

  /// 0 = 아직 맺히기 전 → (눈가에 맺혔다가) 뺨을 타고 흘러내려 → 1 = 사라짐.
  final double tear;

  /// 원 지름 대비 얼굴 이미지 박스 비율(네이티브 배지와 동일).
  static const double markRatio = 0.78;

  /// 얼굴 이미지를 그리는 고정 설계 크기. 배지가 160 → 112dp로 줄어도 같은
  /// 해상도로 한 번만 디코드하고(연출 중 재디코드·깜박임 없음) 변환으로만 줄인다.
  static const double _faceCanvas = 160 * markRatio;

  /// 두 얼굴을 교체하는 창 — 스쿼시가 가장 눌린 직후에 짧게 바꿔 낀다.
  static const Interval _swap = Interval(0.38, 0.62, curve: Curves.easeInOut);

  /// 우는 얼굴은 웃는 얼굴이 거의 다 덮은 뒤에 걷는다. 투명 가장자리 두 장이 동시에
  /// 반투명이 되면 배지 핑크가 얼굴 위로 비친다.
  static const Interval _cryOut = Interval(0.6, 0.8);

  /// 우는 얼굴·웃는 얼굴 이미지 프로바이더(미리 읽기와 그리기가 같은 캐시 키를 쓴다).
  static const AssetImage _cry = AssetImage(ClayScenes.babyCry);
  static const AssetImage _smile = AssetImage(ClayScenes.babySmile);

  /// 두 얼굴을 이미지 캐시에 미리 올린다 — 스플래시가 첫 프레임 전에 호출해
  /// 네이티브 배지 → Flutter 첫 프레임 사이에 빈 배지가 비치지 않게 한다.
  /// 에셋이 없거나 실패해도 조용히 완료된다.
  static Future<void> precache(BuildContext context) => Future.wait([
    precacheImage(_cry, context, onError: (_, _) {}),
    precacheImage(_smile, context, onError: (_, _) {}),
  ]);

  /// 스쿼시(+) / 스트레치(−) 양 — 눌렸다가(최대 7%) 늘어나며(최대 5%) 제자리.
  static double _squash(double smile) {
    final t = const Interval(0.3, 0.85).transform(smile.clamp(0.0, 1.0));
    if (t <= 0 || t >= 1) return 0;
    if (t < 0.4) return 0.07 * math.sin(math.pi * t / 0.4);
    return -0.05 * math.sin(math.pi * (t - 0.4) / 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.light;
    final s = smile.clamp(0.0, 1.0);
    final smileIn = _swap.transform(s);
    final cryOut = _cryOut.transform(s);
    final squash = _squash(s);

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: brand.seal, shape: BoxShape.circle),
        child: Center(
          child: SizedBox.square(
            dimension: size * markRatio,
            child: FittedBox(
              child: SizedBox.square(
                dimension: _faceCanvas,
                child: Transform(
                  // 턱 언저리를 바닥 삼아 눌렸다 튄다(부피 보존: 가로 +, 세로 −).
                  alignment: const Alignment(0, 0.6),
                  transform: Matrix4.diagonal3Values(1 + squash, 1 - squash, 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(opacity: 1 - cryOut, child: const _Face(_cry)),
                      Opacity(opacity: smileIn, child: const _Face(_smile)),
                      CustomPaint(
                        painter: _TearPainter(
                          tear: tear,
                          fill: _tearColor(brand),
                          rim: Color.lerp(brand.sage, brand.lilac, 0.5)!,
                          glint: brand.paperRaised,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 눈물색 — 팔레트에 하늘색 토큰이 없어 민트(sage)와 라일락의 중간(푸른 기)을
  /// 크림 쪽으로 밝힌 이슬빛 파랑. 토큰에서만 파생한다.
  static Color _tearColor(AppColors c) =>
      Color.lerp(Color.lerp(c.sage, c.lilac, 0.5), c.paperRaised, 0.38)!;
}

/// 얼굴 한 장 — 장식이므로 시맨틱스 제외. 에셋이 없으면 빈 자리(배지 원만 보인다).
class _Face extends StatelessWidget {
  const _Face(this.image);

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image(
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
      ),
    );
  }
}

/// 벡터 눈물 — 오른쪽 눈꼬리에서 맺혀(0~0.22) 뺨을 타고 흘러내리며 작아지고
/// 옅어진다(0.22~1). 좌표는 얼굴 이미지 박스 0..1 정규화.
class _TearPainter extends CustomPainter {
  const _TearPainter({
    required this.tear,
    required this.fill,
    required this.rim,
    required this.glint,
  });

  final double tear;
  final Color fill;
  final Color rim;
  final Color glint;

  /// 눈물이 맺히는 자리(오른쪽 눈 바깥 아래 뺨 위)와 흘러내리는 거리.
  static const Offset _start = Offset(0.70, 0.57);
  static const double _fall = 0.13;

  /// 방울 반지름(이미지 폭 대비)과 꼭지 길이(반지름 배수).
  static const double _radius = 0.036;
  static const double _tip = 1.95;

  @override
  void paint(Canvas canvas, Size size) {
    if (tear <= 0 || tear >= 1) return;
    final swell = Curves.easeOutBack.transform(
      const Interval(0, 0.22).transform(tear),
    );
    final fall = Curves.easeInCubic.transform(
      const Interval(0.22, 1).transform(tear),
    );
    final alpha =
        1 - Curves.easeIn.transform(const Interval(0.5, 1).transform(tear));
    if (swell <= 0 || alpha <= 0) return;

    final w = size.width;
    final r = _radius * w * swell * (1 - 0.45 * fall);
    final c = Offset(_start.dx * w, (_start.dy + _fall * fall) * size.height);
    final tipY = c.dy - r * _tip;

    final drop = Path()
      ..moveTo(c.dx, tipY)
      ..cubicTo(
        c.dx + r * 0.35,
        c.dy - r * _tip * 0.55,
        c.dx + r,
        c.dy - r * 0.55,
        c.dx + r,
        c.dy,
      )
      ..arcToPoint(Offset(c.dx - r, c.dy), radius: Radius.circular(r))
      ..cubicTo(
        c.dx - r,
        c.dy - r * 0.55,
        c.dx - r * 0.35,
        c.dy - r * _tip * 0.55,
        c.dx,
        tipY,
      )
      ..close();

    canvas
      ..drawPath(drop, Paint()..color = fill.withValues(alpha: alpha))
      ..drawPath(
        drop,
        Paint()
          ..color = rim.withValues(alpha: 0.35 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14,
      )
      // 유리알 반짝임 — 왼쪽 위 작은 타원.
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-r * 0.36, -r * 0.3),
          width: r * 0.52,
          height: r * 0.7,
        ),
        Paint()..color = glint.withValues(alpha: 0.85 * alpha),
      );
  }

  @override
  bool shouldRepaint(_TearPainter old) =>
      old.tear != tear ||
      old.fill != fill ||
      old.rim != rim ||
      old.glint != glint;
}
