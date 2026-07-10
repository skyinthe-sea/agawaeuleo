import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../domain/entities/tracking_log.dart';

/// §11.10~11.12 기록 타입별 표기(라벨·아이콘·색). 색은 토큰만 사용.
class TrackingTypeStyle {
  const TrackingTypeStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.wash,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color wash;
}

/// 타입별 아이콘/색 — feed=accent, sleep=sage, diaper=amber(토큰).
TrackingTypeStyle trackingTypeStyle(BuildContext context, TrackingType type) {
  final c = context.colors;
  switch (type) {
    case TrackingType.feed:
      return TrackingTypeStyle(
        label: '수유',
        icon: Icons.local_drink_rounded,
        color: c.accent,
        wash: c.accentWash,
      );
    case TrackingType.sleep:
      return TrackingTypeStyle(
        label: '수면',
        icon: Icons.bedtime_rounded,
        color: c.sage,
        wash: c.sageWash,
      );
    case TrackingType.diaper:
      return TrackingTypeStyle(
        label: '기저귀',
        icon: Icons.child_care_rounded,
        color: c.amber,
        // DESIGN v2 §3.1/§7.5.5 — amber 하드코딩 withValues 대신 토큰 amberWash.
        wash: c.amberWash,
      );
  }
}

/// 타입 한글 라벨.
String trackingTypeLabel(TrackingType type) => switch (type) {
  TrackingType.feed => '수유',
  TrackingType.sleep => '수면',
  TrackingType.diaper => '기저귀',
};

/// 하위 종류 한글 라벨.
String subtypeLabel(TrackingSubtype subtype) => switch (subtype) {
  TrackingSubtype.breast => '모유',
  TrackingSubtype.formula => '분유',
  TrackingSubtype.solid => '이유식',
  TrackingSubtype.pee => '소',
  TrackingSubtype.poo => '대',
  TrackingSubtype.mixed => '혼합',
};

/// "14:05" 24시간 시:분.
String formatClock(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// "3시간 20분" / "45분" / "0분".
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0 && m > 0) return '$h시간 $m분';
  if (h > 0) return '$h시간';
  return '$m분';
}

/// 진행 중 경과("1:23" = 1분 23초, "1:02:03" = 1시간 2분 3초) — §11.11 티커.
String formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// 타임라인 한 줄 요약("모유 · 120ml", "3시간 20분", "혼합") — §11.10.
String trackingLogSummary(TrackingLog log) {
  switch (log.type) {
    case TrackingType.feed:
      final sub = log.subtype != null ? subtypeLabel(log.subtype!) : '수유';
      final amount = log.amount;
      if (amount != null && amount > 0) {
        return '$sub · ${amount.round()}ml';
      }
      final dur = log.duration;
      if (dur != null && dur.inMinutes > 0) {
        return '$sub · ${formatDuration(dur)}';
      }
      return sub;
    case TrackingType.sleep:
      final dur = log.duration;
      if (dur != null) return formatDuration(dur);
      return '수면';
    case TrackingType.diaper:
      return log.subtype != null ? subtypeLabel(log.subtype!) : '기저귀';
  }
}

/// 요약 밴드 수면 시간 라벨(밴드 폭 고려 압축) — §11.10.
String formatSleepBand(num minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  if (h > 0 && m > 0) return '$h시간 $m분';
  if (h > 0) return '$h시간';
  return '$m분';
}

/// "7월 8일 (화)" 같은 일자 라벨(intl 로케일 초기화 의존 회피 위해 수동).
String formatDayLabel(DateTime day) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final w = weekdays[(day.weekday - 1) % 7];
  return '${day.month}월 ${day.day}일 ($w)';
}
