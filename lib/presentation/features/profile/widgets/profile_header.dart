import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';
import '../../../widgets/symptom/symptom_illustration.dart';

/// §11.13 상단 프로필 헤더 — 엄마·아가 클레이 장면 쿠션(§124) + 이름/부제.
///
/// DESIGN v3 §6 — 아바타 원을 [ClayScenes.momAndBaby] 클레이 장면을 얹은 파스텔
/// 쿠션(딸기×라일락 워시)으로 승격했다.
///
/// 게스트일 때는 이름 자리에 "게스트"를 보여주고 그 아래 로컬 저장 안내 한 줄
/// (캡션, `ink500`)을 붙인다(게스트 전용 모드 — 계정 연결 유도 문구는 비활성).
/// 연결된 계정은 이메일이 도메인에 없어(§domain AuthRepository 참고)
/// `subtitle`(user_id)을 대신 보여준다. [onTap]이 주어지면 전체 헤더가 탭 영역이
/// 되고(우측 chevron 노출), null이면 정보 표시용 비인터랙티브 헤더가 된다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.isGuest,
    super.key,
    this.subtitle,
    this.onTap,
  });

  final bool isGuest;

  /// 연결된 계정일 때 표시할 부제(user_id). 게스트면 무시된다.
  final String? subtitle;

  /// null이면 헤더는 정보 표시용(비인터랙티브)이 된다 — 게스트 전용 모드에서
  /// 계정 연결/편집 진입점을 숨기기 위함(chevron·리플·탭 없음).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroCushion(isGuest: isGuest),
          const SizedBox(width: AppSpacing.x16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGuest ? '게스트' : '연결된 계정',
                  style: texts.title.copyWith(color: colors.ink900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.x4),
                if (isGuest)
                  // 게스트 전용 모드: 계정 연결 유도 문구 대신 로컬 저장 안내만 노출.
                  // (원문 "계정을 연결하면 기록이 안전하게 보관돼요" — 계정 기능 복원 시 되돌릴 것)
                  // 기록 기능 숨김(2026-09-11): 기록 대신 남아 있는 로컬 데이터(즐겨찾기)로
                  // 안내한다. 기록 복원 시 원문 '기록은 이 기기에 안전하게 저장돼요'로 되돌릴 것.
                  Text(
                    '즐겨찾기는 이 기기에 안전하게 저장돼요',
                    style: texts.caption.copyWith(color: colors.ink500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    subtitle ?? '',
                    style: texts.caption.copyWith(color: colors.ink500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.x8),
            _ChevronBubble(),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap!();
        },
        splashFactory: InkWashSplash.splashFactory,
        splashColor: colors.accentWash,
        highlightColor: Colors.transparent,
        borderRadius: AppRadius.brMd,
        child: content,
      ),
    );
  }
}

/// DESIGN v3 §6 — 엄마·아가 클레이 장면을 얹은 파스텔 쿠션. `isGuest`는 현재
/// 시각에 영향을 주지 않지만(장면은 항상 동일), 향후 계정 상태별 장면 분기가
/// 필요해지면 이 지점에서 [ClayScenes]를 바꿔 끼우면 된다.
class _HeroCushion extends StatelessWidget {
  const _HeroCushion({required this.isGuest});

  final bool isGuest;

  static const double _cushionSize = 124;
  static const double _illustrationSize = 100;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 딸기(accent) × 라일락(lilac) 절반 혼합 워시 — "엄마+아가" 장면을 위한
    // 전용 파스텔(§3.2 lerp 규칙, 두 토큰의 파생이라 하드코딩 아님).
    final wash = Color.lerp(colors.accentWash, colors.lilacWash, 0.5)!;
    return Container(
      width: _cushionSize,
      height: _cushionSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: wash,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: context.shadows.e2,
      ),
      child: const ClayIllustration(
        asset: ClayScenes.momAndBaby,
        size: _illustrationSize,
      ),
    );
  }
}

/// DESIGN v3 §5.4 — 소프트 원 안의 chevron(밀집 정보와 구분되는 "말랑한" 탭 힌트).
class _ChevronBubble extends StatelessWidget {
  const _ChevronBubble();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.paperStack,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.chevron_right_rounded, size: 17, color: colors.ink500),
    );
  }
}
