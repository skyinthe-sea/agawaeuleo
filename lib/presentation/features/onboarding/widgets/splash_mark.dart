import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../../../config/theme/theme.dart';

/// 스플래시 브랜드 도장 — 앱 아이콘의 **우는 아기 마크**를 동그란 인주 도장에 담아,
/// [smile] 진행도에 따라 방긋 웃는 얼굴로 바뀐다("아가 왜 울어?" → 달래졌다).
///
/// 지오메트리는 `tool/app_icon/generate_app_icon.py`의 마크 상수와 **같은 값**이다
/// (마크 박스 0..1 정규화). 네이티브 런치 화면 배지(같은 스크립트 `--splash`)와
/// 첫 프레임이 픽셀 단위로 겹치도록 원 지름 대비 마크 비율도 0.78로 맞췄다 — 한쪽을
/// 바꾸면 다른 쪽도 함께 바꿀 것.
///
/// 색은 앱 아이콘과 같은 **브랜드 고정값**(라이트 팔레트 `seal`·`paperBg` 토큰)이다.
/// 다크 모드에서도 네이티브 런치 아이콘과 같은 색이어야 이음새가 보이지 않는다.
class SplashMark extends StatelessWidget {
  const SplashMark({
    required this.size,
    this.smile = 0,
    this.tear = 0,
    super.key,
  });

  /// 도장(원) 지름.
  final double size;

  /// 0 = 우는 입(세로로 열린 타원) → 1 = 방긋 웃는 입(곡선) + 볼터치.
  final double smile;

  /// 0 = 뺨 위 눈물 → 1 = 흘러내려 사라짐.
  final double tear;

  /// 원 지름 대비 마크 박스 비율(네이티브 배지와 동일).
  static const double markRatio = 0.78;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SplashMarkPainter(
        smile: smile,
        tear: tear,
        seal: AppColors.light.seal,
        cream: AppColors.light.paperBg,
      ),
    );
  }
}

class _SplashMarkPainter extends CustomPainter {
  const _SplashMarkPainter({
    required this.smile,
    required this.tear,
    required this.seal,
    required this.cream,
  });

  final double smile;
  final double tear;
  final Color seal;
  final Color cream;

  // ── 앱 아이콘 마크 상수(generate_app_icon.py와 동일) ──────────────────────
  static const Offset _faceC = Offset(0.50, 0.565);
  static const double _faceR = 0.36;
  static const Offset _curlC = Offset(0.578, 0.178);
  static const double _curlR = 0.078;
  static const double _curlW = 0.042;
  static const double _curlStartDeg = 145;
  static const double _curlEndDeg = 330;
  static const double _eyeY = 0.500;
  static const double _eyeDx = 0.135;
  static const double _eyeR = 0.078;
  static const double _eyeW = 0.038;
  static const Offset _mouthC = Offset(0.50, 0.690);
  static const double _mouthRx = 0.088;
  static const double _mouthRy = 0.082;
  static const Offset _tearC = Offset(0.695, 0.655);
  static const double _tearR = 0.048;
  static const double _tearTipY = 0.568;

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, d / 2, Paint()..color = seal);

    final m = d * SplashMark.markRatio;
    final origin = center - Offset(m / 2, m / 2);
    Offset p(double x, double y) => origin + Offset(x * m, y * m);

    final creamFill = Paint()..color = cream;
    final sealFill = Paint()..color = seal;

    // 얼굴 + 배냇머리(PIL 아크는 두께가 안쪽으로 자라므로 중심선 반경 r - w/2).
    canvas.drawCircle(p(_faceC.dx, _faceC.dy), _faceR * m, creamFill);
    final curlMid = (_curlR - _curlW / 2) * m;
    canvas.drawArc(
      Rect.fromCircle(center: p(_curlC.dx, _curlC.dy), radius: curlMid),
      _rad(_curlStartDeg),
      _rad(_curlEndDeg - _curlStartDeg),
      false,
      Paint()
        ..color = cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = _curlW * m
        ..strokeCap = StrokeCap.round,
    );

    // 감은 눈(∩) — 우는 얼굴에서도 웃는 얼굴에서도 그대로 둔다(^^).
    final eyePaint = Paint()
      ..color = seal
      ..style = PaintingStyle.stroke
      ..strokeWidth = _eyeW * m
      ..strokeCap = StrokeCap.round;
    final eyeMid = (_eyeR - _eyeW / 2) * m;
    for (final sx in const [-1, 1]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: p(_faceC.dx + sx * _eyeDx, _eyeY),
          radius: eyeMid,
        ),
        math.pi,
        math.pi,
        false,
        eyePaint,
      );
    }

    // 볼터치 — 웃음이 반쯤 지나면 번진다.
    final blush = ((smile - 0.45) / 0.55).clamp(0.0, 1.0);
    if (blush > 0) {
      final blushPaint = Paint()..color = seal.withValues(alpha: 0.24 * blush);
      for (final sx in const [-1, 1]) {
        canvas.drawCircle(
          p(0.5 + sx * 0.228, 0.618),
          0.05 * m * (0.6 + 0.4 * blush),
          blushPaint,
        );
      }
    }

    // 입 — 앞 절반: 열린 타원이 납작하게 닫힌다 / 뒤 절반: 곧은 선이 휘어 웃는다.
    final close = (smile / 0.5).clamp(0.0, 1.0);
    final curve = ((smile - 0.5) / 0.5).clamp(0.0, 1.0);
    if (smile < 0.5) {
      final eased = Curves.easeInCubic.transform(close);
      final rx = lerpDouble(_mouthRx, 0.078, eased)! * m;
      final ry = lerpDouble(_mouthRy, _eyeW / 2, eased)! * m;
      final c = p(_mouthC.dx, lerpDouble(_mouthC.dy, 0.70, eased)!);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
        sealFill,
      );
    } else {
      final eased = Curves.easeOutBack.transform(curve);
      final halfWidth = lerpDouble(0.078 - _eyeW / 2, 0.098, eased)!;
      final depth = lerpDouble(0, 0.062, eased)!;
      final y0 = lerpDouble(0.70, 0.672, eased)!;
      final path = Path()
        ..moveTo(p(0.5 - halfWidth, y0).dx, p(0.5 - halfWidth, y0).dy)
        ..quadraticBezierTo(
          p(0.5, y0 + depth * 2).dx,
          p(0.5, y0 + depth * 2).dy,
          p(0.5 + halfWidth, y0).dx,
          p(0.5 + halfWidth, y0).dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = seal
          ..style = PaintingStyle.stroke
          ..strokeWidth = _eyeW * m
          ..strokeCap = StrokeCap.round,
      );
    }

    // 눈물 — 뺨을 따라 흘러내리며 작아지고 사라진다.
    if (tear < 1) {
      final fall = Curves.easeInCubic.transform(tear);
      final scale = 1 - 0.55 * fall;
      final dy = 0.15 * fall;
      final alpha =
          1 - Curves.easeIn.transform(((tear - 0.35) / 0.65).clamp(0, 1));
      final tc = p(_tearC.dx, _tearC.dy + dy);
      final r = _tearR * m * scale;
      final tipY = tc.dy - (_tearC.dy - _tearTipY) * m * scale;
      // 원과 삼각형을 합집합으로 — 서브패스를 겹쳐 그리면 감김 방향이 달라 틈이 생긴다.
      final drop = Path.combine(
        PathOperation.union,
        Path()..addOval(Rect.fromCircle(center: tc, radius: r)),
        Path()
          ..moveTo(tc.dx, tipY)
          ..lineTo(tc.dx - r, tc.dy)
          ..lineTo(tc.dx + r, tc.dy)
          ..close(),
      );
      canvas.drawPath(drop, Paint()..color = seal.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_SplashMarkPainter old) =>
      old.smile != smile ||
      old.tear != tear ||
      old.seal != seal ||
      old.cream != cream;
}
