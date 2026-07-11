import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 상단 인사 영역(스크롤 시 스크롤아웃).
///
/// DESIGN v2 §7.1-1 에디토리얼 2단(날짜 `overline` + 명조 인사 `title`)에 발주자 요청으로
/// **세 번째 단 "오늘의 응원"([dailyMessage])**을 덧댄다: 인사 아래 한 줄 body(ink700).
/// 3일마다 회전하는 짧은 위로 문구로, 값이 없으면(로딩/미제공) 렌더하지 않아 기존 2단
/// 레이아웃으로 자연스럽게 폴백한다. 우측: 알림 벨 아이콘(24) + 안읽음 배지 dot(`coral`).
/// 배경은 페이지 배경과 동일해 스크롤아웃될 때 자연스럽게 사라진다.
class HomeGreetingBar extends StatelessWidget {
  const HomeGreetingBar({
    required this.greeting,
    required this.onBellTap,
    this.dailyMessage,
    this.hasUnread = true,
    super.key,
  });

  /// 표시할 인사 문구(아기 이름이 있으면 이름, 없으면 기본 인사).
  final String greeting;
  final VoidCallback onBellTap;

  /// 오늘의 응원 문구(3일마다 회전). null/공백이면 표시하지 않는다.
  final String? dailyMessage;

  /// 벨 배지 dot 표시 여부.
  final bool hasUnread;

  /// DESIGN v2 §7.1-1 요일 한글 배열(`DateTime.weekday` 1=월 ~ 7=일).
  /// intl 의존성 추가 금지 — 수동 포맷.
  static const List<String> _weekdayNames = <String>[
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ];

  /// '7월 10일 목요일' 형태로 오늘 날짜를 포맷한다(§7.1-1).
  static String _dateLabel(DateTime now) {
    final weekday = _weekdayNames[now.weekday - 1];
    return '${now.month}월 ${now.day}일 $weekday요일';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x12,
        AppSpacing.x8,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dateLabel(DateTime.now()),
                  style: texts.overline.copyWith(color: colors.ink500),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  greeting,
                  style: texts.title.copyWith(color: colors.ink900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dailyMessage != null &&
                    dailyMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    dailyMessage!,
                    style: texts.body.copyWith(
                      color: colors.ink700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          _BellButton(
            hasUnread: hasUnread,
            onTap: onBellTap,
            color: colors.ink700,
            dotColor: colors.coral,
            raised: colors.paperBg,
          ),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.hasUnread,
    required this.onTap,
    required this.color,
    required this.dotColor,
    required this.raised,
  });

  final bool hasUnread;
  final VoidCallback onTap;
  final Color color;
  final Color dotColor;

  /// dot 테두리 색(배경과 대비를 위한 얇은 링).
  final Color raised;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hasUnread ? '알림, 새 소식 있음' : '알림',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // §2-3 최소 터치타깃 48dp(아이콘 크기 24는 유지, 히트 영역만 확대).
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 24, color: color),
              if (hasUnread)
                // 히트 영역이 48로 커지며 중앙 아이콘 위치가 2px 이동해도
                // 배지 dot이 벨 우상단에 붙어 보이도록 좌표를 함께 조정.
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: raised, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
