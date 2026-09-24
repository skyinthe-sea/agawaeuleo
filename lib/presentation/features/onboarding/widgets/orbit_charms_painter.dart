import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

/// 궤도 위 장식 모양(DESIGN v3 §1-3 "아기자기" — 작은 하트·별·구슬).
enum OrbitCharm { heart, star, bead }

/// 무대 궤도 — DESIGN v3 "몽글 클레이" 판.
///
/// `PaperBlobPainter`의 대시 궤도·원 행성 대신 **둥근 점선 궤도 + 작은 하트·별·구슬**을
/// 그린다. 블롭은 그대로 `PaperBlobPainter`가 그리고(`orbitProgress: 0`,
/// `planetScale: 0`으로 궤도·행성만 끔), 이 페인터를 `foregroundPainter`로 얹는다.
///
/// 궤도 반경·장식 위치 식은 `PaperBlobPainter`와 **같다**(같은 [center]·[radius]·
/// [orbitScale]·[page]·[spin]을 넘기면 옛 행성 자리에 그대로 앉는다) — 떠 있는 카드와
/// 겹치지 않게 골라 둔 시작각을 재사용하기 위해서다.
class OrbitCharmsPainter extends CustomPainter {
  const OrbitCharmsPainter({
    required this.page,
    required this.lastPage,
    required this.dotColor,
    required this.rim,
    required this.charms,
    required this.colors,
    this.center = const Offset(170, 190),
    this.radius = 136,
    this.orbitScale = 1.1,
    this.bases = const <double>[0.15, 3.35, 5.6],
    this.speeds = const <double>[0.9, 0.9, 0.4],
    this.sizes = const <double>[6.5, 5.5, 4],
    this.orbitProgress = 1,
    this.charmScale = 1,
    this.spin = 0,
    this.sway = 0,
  });

  /// 연속 페이지 값(블롭과 같은 값).
  final double page;

  /// 페이지 클램프 상한(장면 수 - 1). 블롭의 `washes.length - 1`과 같게.
  final int lastPage;

  /// 점선 궤도 점 색.
  final Color dotColor;

  /// 장식 테두리(배경색으로 궤도 점을 끊어 떠 보이게).
  final Color rim;

  final List<OrbitCharm> charms;
  final List<Color> colors;

  final Offset center;
  final double radius;
  final double orbitScale;

  /// 장식별 시작각(rad)·페이지당 회전(rad)·크기(반폭).
  final List<double> bases;
  final List<double> speeds;
  final List<double> sizes;

  /// 점선 궤도를 몇 %까지 그렸는지(0~1).
  final double orbitProgress;

  /// 장식 크기 배율(0이면 숨김).
  final double charmScale;

  /// 페이지와 무관한 추가 회전(rad).
  final double spin;

  /// 0→1 반복 위상 — 장식이 살짝 까딱인다(0이면 정지).
  final double sway;

  /// 궤도 점 간격(설계 좌표 단위)·반지름.
  static const double _dotGap = 8.5;
  static const double _dotRadius = 1.4;

  /// 장식 테두리 두께.
  static const double _rimWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final clamped = page.clamp(0.0, lastPage.toDouble());
    final orbitRadius = radius * orbitScale;

    // ── 둥근 점선 궤도(한 번의 drawPoints — 점 100여 개도 가볍다).
    final progress = orbitProgress.clamp(0.0, 1.0);
    if (progress > 0) {
      final count = (2 * math.pi * orbitRadius / _dotGap).round();
      final step = 2 * math.pi / count;
      final offset = clamped * 0.3 + spin * 0.5;
      final drawn = (count * progress).ceil();
      canvas.drawPoints(
        PointMode.points,
        <Offset>[
          for (var d = 0; d < drawn; d++)
            center +
                Offset(
                      math.cos(offset + d * step),
                      math.sin(offset + d * step),
                    ) *
                    orbitRadius,
        ],
        Paint()
          ..color = dotColor
          ..strokeWidth = _dotRadius * 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 장식 — 스와이프에 따라 궤도를 돈다.
    if (charmScale <= 0) return;
    final count = <int>[
      charms.length,
      colors.length,
      bases.length,
      speeds.length,
    ].reduce(math.min);
    for (var k = 0; k < count; k++) {
      final angle = bases[k] + clamped * speeds[k] + spin;
      final c = center + Offset(math.cos(angle), math.sin(angle)) * orbitRadius;
      final r = (k < sizes.length ? sizes[k] : 4.0) * charmScale;
      final wobble = 0.16 * math.sin((sway + k / 3) * 2 * math.pi);
      final path = _shape(charms[k], r);

      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(wobble)
        // 테두리 → 채움 → 같은 색 둥근 획(모서리를 점토처럼 굴린다).
        ..drawPath(
          path,
          Paint()
            ..color = rim
            ..style = PaintingStyle.stroke
            ..strokeWidth = _rimWidth * 2 * charmScale.clamp(0.0, 1.0)
            ..strokeJoin = StrokeJoin.round,
        )
        ..drawPath(path, Paint()..color = colors[k])
        ..drawPath(
          path,
          Paint()
            ..color = colors[k]
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.28
            ..strokeJoin = StrokeJoin.round,
        )
        ..restore();
    }
  }

  /// 원점 중심, 반폭 [r]의 장식 윤곽.
  static Path _shape(OrbitCharm kind, double r) {
    switch (kind) {
      case OrbitCharm.heart:
        return Path()
          ..moveTo(0, r * 0.95)
          ..cubicTo(-r * 1.35, r * 0.1, -r * 1.05, -r * 1.15, 0, -r * 0.42)
          ..cubicTo(r * 1.05, -r * 1.15, r * 1.35, r * 0.1, 0, r * 0.95)
          ..close();
      case OrbitCharm.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? r : r * 0.5;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = Offset(math.cos(a), math.sin(a)) * rr;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        return path..close();
      case OrbitCharm.bead:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    }
  }

  @override
  bool shouldRepaint(OrbitCharmsPainter old) =>
      old.page != page ||
      old.lastPage != lastPage ||
      old.dotColor != dotColor ||
      old.rim != rim ||
      old.center != center ||
      old.radius != radius ||
      old.orbitScale != orbitScale ||
      old.orbitProgress != orbitProgress ||
      old.charmScale != charmScale ||
      old.spin != spin ||
      old.sway != sway ||
      !_same(old.colors, colors) ||
      !_same(old.charms, charms) ||
      !_same(old.bases, bases) ||
      !_same(old.speeds, speeds) ||
      !_same(old.sizes, sizes);

  static bool _same<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
