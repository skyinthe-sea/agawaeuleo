import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';

/// §11.13 상단 프로필 헤더 — 아바타 원 64 + 이름/부제.
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
        children: [
          _Avatar(isGuest: isGuest),
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
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: colors.ink300),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
        // DESIGN v2 §7.7 프로필 헤더 히어로화 — e2 + accent 25% 1.5px 링.
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: context.shadows.e2,
      ),
      child: Icon(
        isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
        size: 32,
        color: colors.accent,
      ),
    );
  }
}
