import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import 'symptom_illustration_data.dart';

/// 증상 카드 일러스트 — [SymptomIcons](`symptom_icon.dart`)·
/// [SymptomTone](`symptom_tone.dart`)과 나란한 프레젠테이션 유틸.
///
/// "먹선 + 종이 면 + 하프톤 도트 + 스파클" 스타일(DESIGN v2 페이퍼잉크 문법의
/// 일러스트 확장). 16종 전부의 벡터 데이터는 `symptom_illustration_data.dart`
/// (tool/illustrations/generate_illustrations.py 가 생성)에 있고, 이 파일의
/// [_IllustrationPainter]가 공용 렌더 엔진으로 해석한다 — 선 두께·도트 격자·
/// 색 규칙이 엔진 한 곳에 있어 그림체가 강제로 통일된다.
class SymptomIllustrations {
  const SymptomIllustrations._();

  /// [key]에 대응하는 일러스트가 등록되어 있는지.
  static bool has(String? key) =>
      key != null && symptomIllustrationShapes.containsKey(key);
}

/// 일러스트 셰이프 하나(면·도트·선의 묶음). 목록 순서 = 레이어 순서.
///
/// [cmds]는 평탄화된 패스 명령 스트림 —
/// `[0,x,y]` moveTo · `[1,x,y]` lineTo · `[2,x1,y1,x2,y2,x,y]` cubicTo ·
/// `[9]` close. (const 리터럴로 두기 위한 인코딩 — `Path`는 const 불가.)
class IllustrationShape {
  const IllustrationShape(
    this.cmds, {
    this.fill = IllustrationFill.none,
    this.dots = false,
    this.strokeWidth = 0,
    this.sharp = false,
    this.dotBounds,
  });

  final List<double> cmds;

  /// 면 채움 색 종류.
  final IllustrationFill fill;

  /// 패스 내부에 하프톤 도트 격자를 채울지.
  final bool dots;

  /// 0이면 외곽선 없음. 주 실루엣 3.0 · 보조 2.0~2.2 · 미세 1.2~1.8.
  final double strokeWidth;

  /// 사각 스파클용 — 각진 모서리(miter/butt). 기본은 둥근 손그림 선.
  final bool sharp;

  /// 하프톤을 패스 일부 밴드에만 깔 때의 `[l, t, r, b]`(뷰박스 좌표).
  final List<double>? dotBounds;
}

/// [IllustrationShape.fill]이 소비하는 색 슬롯. 실제 색은 페인터가
/// 토큰(`ink900`/`paperRaised`/`accent`)에서 해석한다.
enum IllustrationFill { none, paper, ink, dot }

/// 등록된 증상 일러스트를 그리는 정사각 벡터 캔버스.
///
/// 색은 전부 토큰에서 해석한다(하드코딩 금지 규칙 §9.1) — 먹선 `ink900`,
/// 종이 면 `paperRaised`, 하프톤 도트·물방울 `accent`. 세 토큰 모두
/// 라이트/다크 값이 정의되어 있어 모드 분기 없이 대비가 유지된다.
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
    final shapes = symptomIllustrationShapes[illustrationKey];
    if (shapes == null) return SizedBox.square(dimension: size);
    final colors = context.colors;
    return ExcludeSemantics(
      // 카드 프레스 스케일/리플 애니메이션과 페인트를 분리한다.
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _IllustrationPainter(
            shapes: shapes,
            ink: colors.ink900,
            paper: colors.paperRaised,
            dot: colors.accent,
          ),
        ),
      ),
    );
  }
}

/// 공용 렌더 엔진 — 셰이프 목록을 순서대로 (면 → 하프톤 → 외곽선) 페인트.
class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter({
    required this.shapes,
    required this.ink,
    required this.paper,
    required this.dot,
  });

  final List<IllustrationShape> shapes;

  /// 외곽 먹선(라이트: 진먹, 다크: 미색 — `ink900`).
  final Color ink;

  /// 면 채움(`paperRaised` — 카드 표면보다 반 톤 밝은 종이).
  final Color paper;

  /// 하프톤 도트·물방울(`accent`).
  final Color dot;

  /// 원본 좌표계(뷰박스) 한 변.
  static const double _viewBox = 120;

  /// 하프톤 도트 격자 — 반지름/간격(뷰박스 단위). 홀수 행 반 칸 오프셋.
  static const double _dotRadius = 1.35;
  static const double _dotStep = 4.8;

  /// 명령 스트림 → [Path] 캐시. 데이터가 const 리터럴이라 목록 identity 로
  /// 키를 잡으면 일러스트당 1회만 빌드된다.
  static final Expando<Path> _pathCache = Expando<Path>();

  static Path _pathOf(IllustrationShape shape) =>
      _pathCache[shape.cmds] ??= _buildPath(shape.cmds);

  static Path _buildPath(List<double> c) {
    final path = Path();
    var i = 0;
    while (i < c.length) {
      switch (c[i].toInt()) {
        case 0:
          path.moveTo(c[i + 1], c[i + 2]);
          i += 3;
        case 1:
          path.lineTo(c[i + 1], c[i + 2]);
          i += 3;
        case 2:
          path.cubicTo(
            c[i + 1],
            c[i + 2],
            c[i + 3],
            c[i + 4],
            c[i + 5],
            c[i + 6],
          );
          i += 7;
        default: // 9 — close
          path.close();
          i += 1;
      }
    }
    return path;
  }

  Color _fillColor(IllustrationFill fill) => switch (fill) {
    IllustrationFill.paper => paper,
    IllustrationFill.ink => ink,
    IllustrationFill.dot => dot,
    IllustrationFill.none => paper, // 도달 불가(호출부 가드)
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.shortestSide / _viewBox);

    for (final shape in shapes) {
      final path = _pathOf(shape);
      if (shape.fill != IllustrationFill.none) {
        canvas.drawPath(path, Paint()..color = _fillColor(shape.fill));
      }
      if (shape.dots) _paintHalftone(canvas, shape, path);
      if (shape.strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = shape.strokeWidth
            ..strokeCap = shape.sharp ? StrokeCap.butt : StrokeCap.round
            ..strokeJoin = shape.sharp ? StrokeJoin.miter : StrokeJoin.round,
        );
      }
    }

    canvas.restore();
  }

  /// [path] 내부(또는 [IllustrationShape.dotBounds] 밴드)에 오프셋 격자
  /// 하프톤 도트를 채운다.
  void _paintHalftone(Canvas canvas, IllustrationShape shape, Path path) {
    canvas
      ..save()
      ..clipPath(path);
    final paint = Paint()..color = dot;
    final b = shape.dotBounds;
    final bounds =
        (b != null ? Rect.fromLTRB(b[0], b[1], b[2], b[3]) : path.getBounds())
            .inflate(_dotRadius);
    var row = 0;
    for (var y = bounds.top; y <= bounds.bottom; y += _dotStep, row++) {
      final x0 = bounds.left + (row.isOdd ? _dotStep / 2 : 0);
      for (var x = x0; x <= bounds.right; x += _dotStep) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.shapes != shapes ||
      oldDelegate.ink != ink ||
      oldDelegate.paper != paper ||
      oldDelegate.dot != dot;
}
