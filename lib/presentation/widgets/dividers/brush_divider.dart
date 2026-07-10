import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v2 §4.2 붓결 디바이더. 좌→우로 두께 2.5→0.8dp로 가늘어지는 수평
/// 스트로크 + 미세한 상하 곡률(사인 1회, 진폭 0.6dp)을 그리는 **결정적**
/// (난수 없는) `CustomPainter` — 골든 테스트 안정성을 위해 좌표를 고정 공식으로만
/// 계산한다.
///
/// 색은 `colors.lineStrong`. **리스트 행 구분에는 쓰지 않는다**(기존 1px
/// `Divider` 유지) — 정보→제품, 콘텐츠→법적 고지 같은 "섹션 격 전환"에만 쓴다.
/// 상하 여백은 소비처 책임.
class BrushDivider extends StatelessWidget {
  const BrushDivider({
    super.key,
    this.width = 64,
    this.alignment = Alignment.centerLeft,
  });

  /// 좌정렬 폭 64 프리셋(섹션 전환 기본).
  const BrushDivider.section({super.key})
    : width = 64,
      alignment = Alignment.centerLeft;

  /// 중앙정렬 폭 88 프리셋(빈 상태 메시지 위 등).
  const BrushDivider.center({super.key})
    : width = 88,
      alignment = Alignment.center;

  final double width;
  final Alignment alignment;

  /// 두께(최대 2.5) + 곡률 진폭(0.6) 양쪽 여유를 포함한 캔버스 높이.
  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: _height,
        child: CustomPaint(
          painter: _BrushDividerPainter(color: context.colors.lineStrong),
        ),
      ),
    );
  }
}

class _BrushDividerPainter extends CustomPainter {
  const _BrushDividerPainter({required this.color});

  final Color color;

  static const double _startThickness = 2.5;
  static const double _endThickness = 0.8;
  static const double _amplitude = 0.6;
  static const int _segments = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final top = <Offset>[];
    final bottom = <Offset>[];

    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      final x = t * size.width;
      final thickness = _startThickness + (_endThickness - _startThickness) * t;
      // 결정적 사인 곡률 1회(반원 형태의 완만한 굽이) — 난수 없음.
      final curve = math.sin(t * math.pi) * _amplitude;
      final y = midY + curve;
      top.add(Offset(x, y - thickness / 2));
      bottom.add(Offset(x, y + thickness / 2));
    }

    final path = Path()..addPolygon(<Offset>[...top, ...bottom.reversed], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BrushDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
