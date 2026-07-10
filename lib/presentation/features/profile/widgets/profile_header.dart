import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';

/// §11.13 상단 프로필 헤더 — 아바타 원 64 + 이름/이메일(또는 게스트 안내).
///
/// 게스트일 때는 이름 자리에 "게스트"를 보여주고 그 아래 계정 연결을 유도하는
/// 한 줄(캡션, `accent`)을 붙인다. 연결된 계정은 이메일이 도메인에 없어(§domain
/// AuthRepository 참고) `subtitle`(user_id)을 대신 보여준다. 전체 헤더가
/// [onTap]("아바타 탭 → 프로필 편집")의 탭 영역이다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.isGuest,
    required this.onTap,
    super.key,
    this.subtitle,
  });

  final bool isGuest;

  /// 연결된 계정일 때 표시할 부제(user_id). 게스트면 무시된다.
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        splashFactory: InkWashSplash.splashFactory,
        splashColor: colors.accentWash,
        highlightColor: Colors.transparent,
        borderRadius: AppRadius.brMd,
        child: Padding(
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
                      Text(
                        '계정을 연결하면 기록이 안전하게 보관돼요',
                        style: texts.caption.copyWith(color: colors.accent),
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
              Icon(Icons.chevron_right_rounded, color: colors.ink300),
            ],
          ),
        ),
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
