import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';

/// §11.13 내 정보 메뉴 리스트의 한 행.
///
/// 높이 56, 좌측 아이콘 24, 우측 chevron `ink.300`. 탭 시 잉크 워시 리플 +
/// lightImpact 햅틱.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return SizedBox(
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
                Icon(icon, size: 24, color: iconColor ?? colors.ink700),
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
  }
}
