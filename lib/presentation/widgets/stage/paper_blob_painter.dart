import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 무대 배경 — 종이를 오려 붙인 블롭(아랫장 겹침) + 점선 궤도와 행성.
///
/// 온보딩 스테이지에서 태어나 홈 케어 덱·상세 케어 노트가 함께 쓰는 시그니처다.
/// 장면(페이지)마다 워시 색이 하나씩 있고, 윤곽은 3가지 프리셋을 번갈아 쓴다.
/// [page]의 연속 값으로 두 장면 사이 윤곽·색을 보간하고 블롭을 조금 돌리므로,
/// 손가락을 따라 배경이 모핑된다. 그라데이션 없이 단색 면만 쓴다(DESIGN v2 §0).
///
/// 좌표는 호출부의 설계 캔버스 단위다(보통 `FittedBox` 안의 고정 크기 캔버스).
class PaperBlobPainter extends CustomPainter {
  const PaperBlobPainter({
    required this.page,
    required this.breath,
    required this.washes,
    required this.under,
    required this.orbit,
    required this.rim,
    required this.planets,
    this.center = const Offset(170, 190),
    this.radius = 136,
    this.orbitScale = 1.1,
    this.rotationPerPage = 0.55,
    this.underOffset = const Offset(8, 10),
    this.planetBases = const <double>[0.15, 3.35, 5.6],
    this.planetSpeeds = const <double>[0.9, 0.9, 0.4],
    this.planetRadii = const <double>[5.5, 4, 4.5],
    this.orbitProgress = 1,
    this.planetScale = 1,
    this.spin = 0,
  });

  /// 연속 페이지 값(0 = 첫 장면).
  final double page;

  /// 0→1 반복 호흡 위상. 블롭 윤곽이 1.4%만큼 숨쉰다.
  final double breath;

  /// 장면별 블롭 색. 길이 = 장면 수.
  final List<Color> washes;

  /// 블롭 아랫장(겹친 종이) 색 — 보통 `paperStack`.
  final Color under;
  final Color orbit;

  /// 행성 테두리(배경과 같은 색으로 궤도선을 끊어 떠 보이게).
  final Color rim;
  final List<Color> planets;

  final Offset center;
  final double radius;

  /// 궤도 반경 = [radius] × 이 값.
  final double orbitScale;
  final double rotationPerPage;
  final Offset underOffset;

  /// 행성별 시작각(rad)·페이지당 회전(rad)·반지름. 떠 있는 카드와 겹치지 않는
  /// 자리를 호출부가 고른다.
  final List<double> planetBases;
  final List<double> planetSpeeds;
  final List<double> planetRadii;

  /// 점선 궤도를 몇 %까지 그렸는지(0~1) — 스플래시처럼 궤도가 그려지며 등장할 때.
  final double orbitProgress;

  /// 행성 크기 배율(0이면 숨김) — 등장 때 톡 튀어나오게.
  final double planetScale;

  /// 페이지와 무관한 추가 회전(rad) — 페이지가 없는 무대(스플래시)의 느린 흐름.
  final double spin;

  static const List<List<double>> _outlines = <List<double>>[
    <double>[1.00, 0.93, 1.05, 0.95, 1.02, 0.92, 1.06, 0.96],
    <double>[0.94, 1.06, 0.92, 1.03, 0.97, 1.07, 0.93, 1.01],
    <double>[1.05, 0.96, 1.00, 1.07, 0.92, 1.01, 0.96, 1.05],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (washes.isEmpty) return;
    final last = washes.length - 1;
    final clamped = page.clamp(0.0, last.toDouble());
    final i0 = clamped.floor().clamp(0, last);
    final i1 = math.min(i0 + 1, last);
    final f = clamped - i0;

    // ── 블롭 윤곽: 장면 윤곽 보간 + 아주 느린 호흡 + 페이지에 따른 회전.
    final rotation = clamped * rotationPerPage + spin;
    final points = <Offset>[];
    for (var k = 0; k < 8; k++) {
      final r0 = _outlines[i0 % _outlines.length][k];
      final r1 = _outlines[i1 % _outlines.length][k];
      final wobble = 1 + 0.014 * math.sin((breath + k / 8) * 2 * math.pi);
      final r = radius * (r0 + (r1 - r0) * f) * wobble;
      final angle = rotation + k * math.pi / 4;
      points.add(center + Offset(math.cos(angle), math.sin(angle)) * r);
    }
    final blob = smoothClosed(points);

    canvas
      ..drawPath(blob.shift(underOffset), Paint()..color = under)
      ..drawPath(blob, Paint()..color = Color.lerp(washes[i0], washes[i1], f)!);

    // ── 점선 궤도.
    final orbitRadius = radius * orbitScale;
    final orbitRect = Rect.fromCircle(center: center, radius: orbitRadius);
    final orbitPaint = Paint()
      ..color = orbit
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashes = 56;
    const sweep = 2 * math.pi / dashes;
    final dashOffset = clamped * 0.3 + spin * 0.5;
    final drawn = (dashes * orbitProgress.clamp(0.0, 1.0)).ceil();
    for (var d = 0; d < drawn; d++) {
      canvas.drawArc(
        orbitRect,
        dashOffset + d * sweep,
        sweep * 0.45,
        false,
        orbitPaint,
      );
    }

    // ── 궤도 위 행성 — 스와이프에 따라 궤도를 돈다.
    final count = math.min(
      planets.length,
      math.min(planetBases.length, planetSpeeds.length),
    );
    if (planetScale <= 0) return;
    for (var k = 0; k < count; k++) {
      final angle = planetBases[k] + clamped * planetSpeeds[k] + spin;
      final c = center + Offset(math.cos(angle), math.sin(angle)) * orbitRadius;
      final r = (k < planetRadii.length ? planetRadii[k] : 4.0) * planetScale;
      canvas
        ..drawCircle(c, r + 2.5 * planetScale, Paint()..color = rim)
        ..drawCircle(c, r, Paint()..color = planets[k]);
    }
  }

  /// 닫힌 Catmull-Rom 스플라인 → 큐빅 베지어.
  static Path smoothClosed(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = p[(i - 1 + n) % n];
      final p1 = p[i];
      final p2 = p[(i + 1) % n];
      final p3 = p[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(PaperBlobPainter old) =>
      old.page != page ||
      old.breath != breath ||
      old.under != under ||
      old.orbit != orbit ||
      old.rim != rim ||
      old.center != center ||
      old.radius != radius ||
      old.orbitProgress != orbitProgress ||
      old.planetScale != planetScale ||
      old.spin != spin ||
      !_sameColors(old.washes, washes) ||
      !_sameColors(old.planets, planets);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
