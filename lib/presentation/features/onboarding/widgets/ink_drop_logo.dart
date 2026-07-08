import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.1 스플래시 로고("수묵 물방울+아기 실루엣").
///
/// 실제 일러스트 에셋이 아직 없어, 좌우 비대칭 베지어로 붓 느낌을 낸 잉크 방울(accent)
/// 위에 배경색 원 하나로 아기 얼굴을 암시하는 절제된 도형 표현으로 대체한다. 에셋이
/// 준비되면 이 위젯을 이미지로 교체하면 된다(외부에 노출된 API는 size뿐).
class InkDropLogo extends StatelessWidget {
  const InkDropLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InkDropPainter(
          dropColor: colors.accent,
          faceColor: colors.paperBg,
        ),
      ),
    );
  }
}

class _InkDropPainter extends CustomPainter {
  _InkDropPainter({required this.dropColor, required this.faceColor});

  final Color dropColor;
  final Color faceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final topY = h * 0.10;
    final bulbCenterY = h * 0.62;
    final bulbRadius = w * 0.34;

    // 잉크가 번진 물방울: 위는 뾰족하고 아래는 둥근 실루엣을, 좌우를 살짝 비대칭으로
    // 그려 손으로 그은 붓터치처럼 보이게 한다.
    final path = Path()
      ..moveTo(cx, topY)
      ..cubicTo(
        cx + w * 0.40,
        topY + h * 0.10,
        cx + bulbRadius,
        bulbCenterY - bulbRadius * 0.62,
        cx + bulbRadius,
        bulbCenterY,
      )
      ..arcToPoint(
        Offset(cx - bulbRadius, bulbCenterY),
        radius: Radius.circular(bulbRadius),
        clockwise: true,
      )
      ..cubicTo(
        cx - bulbRadius,
        bulbCenterY - bulbRadius * 0.66,
        cx - w * 0.37,
        topY + h * 0.085,
        cx,
        topY,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = dropColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // 아기 얼굴을 암시하는 배경색 knock-out 원 하나(절제된 표현).
    final faceCenter = Offset(cx + w * 0.02, bulbCenterY - bulbRadius * 0.18);
    canvas.drawCircle(
      faceCenter,
      w * 0.16,
      Paint()
        ..color = faceColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_InkDropPainter oldDelegate) =>
      oldDelegate.dropColor != dropColor || oldDelegate.faceColor != faceColor;
}
