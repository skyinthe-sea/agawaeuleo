import 'dart:async';

import 'package:flutter/material.dart';

import 'tracking_format.dart';

/// §11.11 진행 중 경과시간 티커. [start]부터 1초마다 "M:SS"/"H:MM:SS"로 갱신.
/// (정보 표기이므로 reduce-motion과 무관하게 매초 갱신한다.)
///
/// DESIGN v2 §7.5.2 경과 시간 히어로 — [valueStyle]을 지정하면 [prefix]는
/// [style]로, 경과 수치 부분만 [valueStyle](보통 `dataL`)로 승격해 강조한다.
/// 미지정 시(기본) 전체가 [style] 하나로 렌더돼 기존 호출부와 동일하다.
class ElapsedTicker extends StatefulWidget {
  const ElapsedTicker({
    required this.start,
    super.key,
    this.style,
    this.prefix = '',
    this.valueStyle,
  });

  final DateTime start;
  final TextStyle? style;
  final String prefix;

  /// 경과 수치(예: "1:23")에만 적용할 강조 스타일. null이면 [style] 그대로 통짜 렌더.
  final TextStyle? valueStyle;

  @override
  State<ElapsedTicker> createState() => _ElapsedTickerState();
}

class _ElapsedTickerState extends State<ElapsedTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.start);
    final value = formatElapsed(elapsed);
    if (widget.valueStyle == null) {
      return Text('${widget.prefix}$value', style: widget.style);
    }
    return Text.rich(
      TextSpan(
        children: [
          if (widget.prefix.isNotEmpty)
            TextSpan(text: widget.prefix, style: widget.style),
          TextSpan(text: value, style: widget.valueStyle),
        ],
      ),
    );
  }
}
