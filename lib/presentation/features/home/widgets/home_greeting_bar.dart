import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 상단 인사 영역(스크롤 시 스크롤아웃).
///
/// DESIGN v2 §7.1-1 에디토리얼 2단(날짜 `overline` + 인사 `title`)에 발주자 요청으로
/// **세 번째 단 "오늘의 응원"([dailyMessage])**을 덧댄다: 인사 아래 한 줄 body(ink700).
/// 3일마다 회전하는 짧은 위로 문구로, 값이 없으면(로딩/미제공) 렌더하지 않아 기존 2단
/// 레이아웃으로 자연스럽게 폴백한다. 우측: 메뉴(햄버거) 아이콘(24) → 설정으로 이동.
/// 배경은 페이지 배경과 동일해 스크롤아웃될 때 자연스럽게 사라진다.
///
/// DESIGN v3 "몽글 클레이" — 인사는 주아체(`title`), 오늘의 응원은 인사에서 말풍선처럼
/// 이어지는 둥근 버블(paperRaised + e1, 앞에 작은 딸기 하트), 메뉴는 동그란 버블 버튼.
class HomeGreetingBar extends StatelessWidget {
  const HomeGreetingBar({
    required this.greeting,
    required this.onMenuTap,
    this.dailyMessage,
    super.key,
  });

  /// 표시할 인사 문구(아기 이름이 있으면 이름, 없으면 기본 인사).
  final String greeting;
  final VoidCallback onMenuTap;

  /// 오늘의 응원 문구(3일마다 회전). null/공백이면 표시하지 않는다.
  final String? dailyMessage;

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
        AppSpacing.x12,
        AppSpacing.x8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: AppSpacing.x8),
                  _CheerBubble(message: dailyMessage!),
                ],
              ],
            ),
          ),
          _MenuButton(onTap: onMenuTap, color: colors.ink700),
        ],
      ),
    );
  }
}

/// 오늘의 응원 말풍선 — 인사 쪽(왼쪽 위) 모서리만 덜 둥글게 해 말하듯 이어 붙인다.
class _CheerBubble extends StatelessWidget {
  const _CheerBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x12,
        AppSpacing.x4 + AppSpacing.x2,
        AppSpacing.x16,
        AppSpacing.x4 + AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xs / 2),
          topRight: Radius.circular(AppRadius.md),
          bottomLeft: Radius.circular(AppRadius.md),
          bottomRight: Radius.circular(AppRadius.md),
        ),
        boxShadow: context.shadows.e1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // 첫 줄 글자 높이에 하트를 맞춘다.
            padding: const EdgeInsets.only(top: AppSpacing.x4),
            child: Icon(Icons.favorite_rounded, size: 13, color: colors.seal),
          ),
          const SizedBox(width: AppSpacing.x4 + AppSpacing.x2),
          Flexible(
            child: Text(
              message,
              style: context.texts.body.copyWith(
                color: colors.ink700,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '메뉴',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // §2-3 최소 터치타깃 48dp — 보이는 건 40 동그란 버블, 히트 영역은 48.
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.paperRaised,
                shape: BoxShape.circle,
                boxShadow: context.shadows.e1,
              ),
              child: Icon(Icons.menu_rounded, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
