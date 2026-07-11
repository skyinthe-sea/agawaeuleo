import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 증상 카드 일러스트 레지스트리 — [SymptomIcons](`symptom_icon.dart`)·
/// [SymptomTone](`symptom_tone.dart`)과 나란한 프레젠테이션 유틸.
///
/// "먹선 + 종이 면 + 하프톤 도트 + 스파클" 스타일(DESIGN v2 페이퍼잉크 문법의
/// 일러스트 확장)의 손그림 벡터를 `emoji_or_icon` 키로 매핑한다. 등록된 키만
/// 홈 카드가 일러스트 레이아웃으로 전환된다.
///
/// 현재 `tummy_pain`(배앓이) 1종 — 카드 일러스트 스타일 트라이얼. 16종 확산
/// 시 이 레지스트리에 페인터만 추가하면 된다.
class SymptomIllustrations {
  const SymptomIllustrations._();

  /// [key]에 대응하는 일러스트가 등록되어 있는지.
  static bool has(String? key) => key == 'tummy_pain';
}

/// 등록된 증상 일러스트를 그리는 정사각 벡터 캔버스.
///
/// 색은 전부 토큰에서 해석한다(하드코딩 금지 규칙 §9.1) — 먹선 `ink900`,
/// 종이 면 `paperRaised`, 하프톤 도트 `accent`. 세 토큰 모두 라이트/다크
/// 값이 정의되어 있어 모드 전환 시 별도 분기 없이 대비가 유지된다.
///
/// 장식 요소이므로 시맨틱스에서 제외한다(카드의 제목/설명 텍스트가 의미 전달).
class SymptomIllustration extends StatelessWidget {
  const SymptomIllustration({
    required this.illustrationKey,
    required this.size,
    super.key,
  });

  /// [SymptomIllustrations]에 등록된 `emoji_or_icon` 키.
  final String illustrationKey;

  /// 렌더 한 변 길이(dp). 페인터는 120 뷰박스를 이 크기로 스케일한다.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final painter = switch (illustrationKey) {
      'tummy_pain' => _ColicBabyPainter(
        ink: colors.ink900,
        paper: colors.paperRaised,
        dot: colors.accent,
      ),
      _ => null,
    };
    if (painter == null) return SizedBox.square(dimension: size);
    return ExcludeSemantics(
      // 카드 프레스 스케일/리플 애니메이션과 페인트를 분리한다.
      child: RepaintBoundary(
        child: CustomPaint(size: Size.square(size), painter: painter),
      ),
    );
  }
}

/// 배앓이(영아산통) — 배에 두 손을 올리고 우는 아기 정면 뷰.
///
/// 구성: 도트 우주복 몸통 + 흰 배 패치와 배꼽 소용돌이(아픈 배) + 꾹 감은
/// `><` 눈과 벌린 입, 양볼로 튀는 눈물 + 주변 십자/사각 스파클. 64dp 축소에서도
/// "우는 아기 + 배" 두 정보가 읽히도록 큰 면 3개(머리·몸통·배 패치)로 단순화했다.
class _ColicBabyPainter extends CustomPainter {
  const _ColicBabyPainter({
    required this.ink,
    required this.paper,
    required this.dot,
  });

  /// 외곽 먹선(라이트: 진먹, 다크: 미색 — `ink900`).
  final Color ink;

  /// 면 채움(`paperRaised` — 카드 표면보다 반 톤 밝은 종이).
  final Color paper;

  /// 하프톤 도트·눈물(`accent`).
  final Color dot;

  /// 원본 좌표계(뷰박스) 한 변.
  static const double _viewBox = 120;

  /// 하프톤 도트 격자 — 반지름/간격(뷰박스 단위). 홀수 행 반 칸 오프셋.
  static const double _dotRadius = 1.35;
  static const double _dotStep = 4.8;

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(double width) => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.shortestSide / _viewBox);

    _paintSparkles(canvas);
    _paintBody(canvas);
    _paintHead(canvas);

    canvas.restore();
  }

  /// 주변 장식 — 십자 2, 채움 사각 1, 빈 사각 1.
  void _paintSparkles(Canvas canvas) {
    void plus(Offset c, double r, double w) {
      final paint = _stroke(w);
      canvas
        ..drawLine(c.translate(-r, 0), c.translate(r, 0), paint)
        ..drawLine(c.translate(0, -r), c.translate(0, r), paint);
    }

    plus(const Offset(17, 22), 5, 2.4);
    plus(const Offset(103, 18), 4, 2.2);
    canvas
      ..drawRect(
        Rect.fromCenter(center: const Offset(13, 50), width: 3.4, height: 3.4),
        _fill(ink),
      )
      ..drawRect(
        Rect.fromCenter(center: const Offset(106, 46), width: 4, height: 4),
        // 모서리가 각지도록 기본 miter 조인 유지.
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
  }

  /// 발 → 몸통(도트 우주복) → 배 패치·배꼽 → 두 손. 위 레이어가 아래를 덮는다.
  void _paintBody(Canvas canvas) {
    void ball(Offset c, double r, double strokeWidth) {
      canvas
        ..drawCircle(c, r, _fill(paper))
        ..drawCircle(c, r, _stroke(strokeWidth));
    }

    // 발(몸통 뒤에서 아래로 빼꼼).
    ball(const Offset(46, 102.5), 6.8, 2);
    ball(const Offset(74, 102.5), 6.8, 2);

    final body = Path()
      ..moveTo(36, 79)
      ..cubicTo(36, 63, 46, 56, 60, 56)
      ..cubicTo(74, 56, 84, 63, 84, 79)
      ..cubicTo(84, 93, 74, 101, 60, 101)
      ..cubicTo(46, 101, 36, 93, 36, 79)
      ..close();

    canvas.drawPath(body, _fill(paper));
    _paintHalftone(canvas, clip: body);
    canvas.drawPath(body, _stroke(3));

    // 배 패치(흰 원) + 배꼽 소용돌이.
    ball(const Offset(60, 80), 12.5, 2);
    final swirl = Path()
      ..moveTo(60, 73.5)
      ..cubicTo(65.5, 73.5, 68, 78, 64.5, 82)
      ..cubicTo(61.5, 85.2, 56.5, 83.5, 57, 79.5)
      ..cubicTo(57.4, 76.8, 60.8, 76.8, 61.4, 79);
    canvas.drawPath(swirl, _stroke(1.8));

    // 배 위에 올린 두 손.
    ball(const Offset(45, 75), 5.2, 2);
    ball(const Offset(75, 75), 5.2, 2);
  }

  /// [clip] 내부에 오프셋 격자 하프톤 도트를 채운다(우주복 원단 질감).
  void _paintHalftone(Canvas canvas, {required Path clip}) {
    canvas
      ..save()
      ..clipPath(clip);
    final paint = _fill(dot);
    final bounds = clip.getBounds().inflate(_dotRadius);
    var row = 0;
    for (var y = bounds.top; y <= bounds.bottom; y += _dotStep, row++) {
      final x0 = bounds.left + (row.isOdd ? _dotStep / 2 : 0);
      for (var x = x0; x <= bounds.right; x += _dotStep) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
    canvas.restore();
  }

  /// 머리·머리카락·꾹 감은 눈·우는 입·눈물.
  void _paintHead(Canvas canvas) {
    canvas
      ..drawCircle(const Offset(60, 38), 20, _fill(paper))
      ..drawCircle(const Offset(60, 38), 20, _stroke(3));

    // 정수리 머리카락 한 가닥.
    final hair = Path()
      ..moveTo(58, 19)
      ..cubicTo(57, 14.5, 61.5, 12.5, 63.5, 16);
    canvas.drawPath(hair, _stroke(2));

    // 꾹 감은 `>` `<` 눈.
    final eyeL = Path()
      ..moveTo(46, 32)
      ..lineTo(51, 34.5)
      ..lineTo(46, 37);
    final eyeR = Path()
      ..moveTo(74, 32)
      ..lineTo(69, 34.5)
      ..lineTo(74, 37);
    canvas
      ..drawPath(eyeL, _stroke(2.2))
      ..drawPath(eyeR, _stroke(2.2))
      // 크게 벌리고 우는 입.
      ..drawOval(
        Rect.fromCenter(center: const Offset(60, 44), width: 9.2, height: 7.2),
        _fill(ink),
      );

    // 양볼 바깥으로 튀는 눈물 두 방울.
    final tearL = Path()
      ..moveTo(33, 27)
      ..cubicTo(31, 30.8, 31.8, 33.8, 34.6, 34)
      ..cubicTo(37.4, 34.2, 38, 31, 35.8, 27.4)
      ..cubicTo(35, 26.1, 33.7, 26.1, 33, 27)
      ..close();
    final tearR = Path()
      ..moveTo(84.2, 27.4)
      ..cubicTo(82, 31, 82.6, 34.2, 85.4, 34)
      ..cubicTo(88.2, 33.8, 89, 30.8, 87, 27)
      ..cubicTo(86.3, 26.1, 85, 26.1, 84.2, 27.4)
      ..close();
    for (final tear in [tearL, tearR]) {
      canvas
        ..drawPath(tear, _fill(dot))
        ..drawPath(tear, _stroke(1.4));
    }
  }

  @override
  bool shouldRepaint(_ColicBabyPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.dot != dot;
}
