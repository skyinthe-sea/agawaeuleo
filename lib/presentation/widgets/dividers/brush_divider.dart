import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 섹션 격 전환 디바이더 — DESIGN v3 §5.4 **몽글 점선**(v2 §4.2 붓결 디바이더의 후신).
///
/// 지름 4dp의 둥근 점을 약 10dp 간격으로 늘어놓되, 가운데로 갈수록 살짝 커지는
/// (최대 지름 5dp) 동글동글한 리듬을 준다. 좌표·크기를 고정 공식으로만 계산하는
/// **결정적**(난수 없는) `CustomPainter`라 골든 테스트가 안정적이다.
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

  /// 가장 큰 점(지름 5) + 여유를 포함한 캔버스 높이.
  static const double _height = 6;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: _height,
        child: CustomPaint(
          painter: _DottedDividerPainter(color: context.colors.lineStrong),
        ),
      ),
    );
  }
}

class _DottedDividerPainter extends CustomPainter {
  const _DottedDividerPainter({required this.color});

  final Color color;

  /// 기본 점 지름(DESIGN v3 §5.4).
  static const double _dot = 4;

  /// 가운데 점이 커지는 최대 가산(지름 기준).
  static const double _swell = 1;

  /// 목표 점 간격(중심 간).
  static const double _step = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDot = _dot + _swell;
    final usable = size.width - maxDot;
    if (usable <= 0) {
      canvas.drawCircle(
        size.center(Offset.zero),
        math.min(size.width, size.height) / 2,
        Paint()..color = color,
      );
      return;
    }

    // 폭을 정확히 채우도록 점 개수를 정하고 간격을 고르게 나눈다(결정적).
    final count = (usable / _step).round() + 1;
    final gap = count > 1 ? usable / (count - 1) : 0.0;
    final midY = size.height / 2;
    final paint = Paint()..color = color;

    for (var i = 0; i < count; i++) {
      final t = count > 1 ? i / (count - 1) : 0.5;
      // 가운데로 갈수록 살짝 커지는 리듬(사인 1회).
      final d = _dot + _swell * math.sin(t * math.pi);
      canvas.drawCircle(Offset(maxDot / 2 + gap * i, midY), d / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
