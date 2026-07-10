import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.2 온보딩 일러스트 프레임. radius `r.xl` · 배경 `accent.wash`.
///
/// 실제 일러스트 에셋이 준비되기 전까지, 각 장의 내용을 절제된 라인 아이콘 하나로
/// 표현한다(§9.6 아이콘 원칙 — 과한 컬러 금지, 라인 스타일).
///
/// DESIGN v2 §7.6.6 — 프레임 내부에 [index](0~2)에 따라 배경 모티프를 차별화한다
/// (① 동심원 파문 ② 점묘 ③ 초승달 곡선). 전부 `fg.withValues(alpha: .12)`의 결정적
/// (난수 없는) `CustomPainter`로, `shouldRepaint`는 색 비교만 한다(§9 가드레일 성능).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    required this.icon,
    required this.index,
    super.key,
  });

  final IconData icon;

  /// 온보딩 페이지 인덱스(0-based) — 배경 모티프 선택에 쓰인다.
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motifColor = colors.accent.withValues(alpha: 0.12);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.accentWash,
              borderRadius: AppRadius.brXl,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _motifPainterFor(index, motifColor)),
                Center(child: Icon(icon, size: 88, color: colors.accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [index]에 대응하는 §7.6.6 배경 모티프 페인터. 정의 범위 밖 인덱스는 파문으로 폴백.
CustomPainter _motifPainterFor(int index, Color color) => switch (index) {
  1 => _DotsMotifPainter(color: color),
  2 => _CrescentMotifPainter(color: color),
  _ => _RippleMotifPainter(color: color),
};

/// ① 동심원 파문 — 잉크 링 2개.
class _RippleMotifPainter extends CustomPainter {
  const _RippleMotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.02;
    final center = Offset(size.width * 0.78, size.height * 0.22);
    canvas.drawCircle(center, size.shortestSide * 0.30, paint);
    canvas.drawCircle(center, size.shortestSide * 0.48, paint);
  }

  @override
  bool shouldRepaint(covariant _RippleMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// ② 점묘 — 결정적 좌표의 점 5개.
class _DotsMotifPainter extends CustomPainter {
  const _DotsMotifPainter({required this.color});

  final Color color;

  static const List<Offset> _points = <Offset>[
    Offset(0.18, 0.20),
    Offset(0.82, 0.16),
    Offset(0.75, 0.78),
    Offset(0.22, 0.82),
    Offset(0.50, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.shortestSide * 0.035;
    for (final point in _points) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotsMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// ③ 초승달 곡선 — 두 원의 차집합으로 그린 크레센트.
class _CrescentMotifPainter extends CustomPainter {
  const _CrescentMotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outerCenter = Offset(size.width * 0.72, size.height * 0.30);
    final outerRadius = size.shortestSide * 0.30;
    final innerCenter = Offset(size.width * 0.80, size.height * 0.24);
    final innerRadius = size.shortestSide * 0.26;

    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: outerCenter, radius: outerRadius));
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: innerRadius));
    final crescent = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    canvas.drawPath(crescent, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CrescentMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}
