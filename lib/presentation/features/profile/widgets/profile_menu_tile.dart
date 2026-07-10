import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';
import '../../../widgets/brand/ink_halo_icon.dart';

/// §11.13 내 정보 메뉴 리스트의 한 행.
///
/// DESIGN v2 §7.7 프로필 헤더 히어로화 — 24dp 단색 아이콘을 36dp [InkHaloIcon]
/// 워시 원(항목별 wash/fg 분화: 아기=accentWash, 즐겨찾기=amberWash,
/// 설정=중립 paperCard+line, 문의=sageWash)으로 승격하고, 목록 진입 시
/// stagger(순번 × 40ms 지연) fadeIn+slideY를 재생한다([BabyCard]와 동일 문법).
/// 밀집 리스트이므로 [InkHaloIcon]의 바깥 링은 생략([ring]=false).
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.washColor,
    required this.iconColor,
    super.key,
    this.borderColor,
    this.labelColor,
    this.index = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 아이콘 워시 원 배경.
  final Color washColor;

  /// 아이콘 전경색(워시와 짝을 이룸).
  final Color iconColor;

  /// 지정 시 워시 원에 헤어라인 보더를 두른다(설정 행의 "중립 paperCard+line").
  final Color? borderColor;

  final Color? labelColor;

  /// 목록 내 순번(stagger 지연 계산용).
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    final haloIcon = InkHaloIcon(
      size: 36,
      icon: icon,
      washColor: washColor,
      fgColor: iconColor,
      ring: false,
    );

    final iconVisual = borderColor == null
        ? haloIcon
        : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!),
            ),
            child: haloIcon,
          );

    Widget tile = SizedBox(
      height: 56,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            AppHaptics.tap();
            onTap();
          },
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.accentWash,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: Row(
              children: [
                iconVisual,
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Text(
                    label,
                    style: texts.bodyL.copyWith(
                      color: labelColor ?? colors.ink900,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.ink300,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduce) {
      tile = tile
          .animate(delay: Duration(milliseconds: 40 * index))
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: 0.08, end: 0, curve: AppMotion.enter);
    }
    return tile;
  }
}
