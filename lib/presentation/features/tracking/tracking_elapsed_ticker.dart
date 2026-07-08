import 'dart:async';

import 'package:flutter/material.dart';

import 'tracking_format.dart';

/// §11.11 진행 중 경과시간 티커. [start]부터 1초마다 "M:SS"/"H:MM:SS"로 갱신.
/// (정보 표기이므로 reduce-motion과 무관하게 매초 갱신한다.)
class ElapsedTicker extends StatefulWidget {
  const ElapsedTicker({
    required this.start,
    super.key,
    this.style,
    this.prefix = '',
  });

  final DateTime start;
  final TextStyle? style;
  final String prefix;

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
    return Text(
      '${widget.prefix}${formatElapsed(elapsed)}',
      style: widget.style,
    );
  }
}
