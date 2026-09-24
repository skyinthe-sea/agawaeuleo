import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';
import '../../../widgets/brand/ink_halo_icon.dart';

/// §11.16 게스트 상단 배너 — "계정 연결" · `accent.wash` 배경.
/// 탭하면 로그인/계정 연결 화면으로 이동만 한다(실제 연결 로직은 M5).
///
/// DESIGN v3 §5.4 — 단색 아이콘을 클레이 버블([InkHaloIcon])로 승격했다.
class ConnectAccountBanner extends StatelessWidget {
  const ConnectAccountBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Material(
      color: colors.accentWash,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        splashFactory: InkWashSplash.splashFactory,
        splashColor: colors.accentDeep.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              InkHaloIcon(
                size: 40,
                icon: Icons.cloud_upload_outlined,
                washColor: colors.paperRaised,
                fgColor: colors.accent,
                ring: false,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '계정 연결',
                      style: texts.heading.copyWith(color: colors.accentDeep),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      '기록을 안전하게 백업하세요',
                      style: texts.body.copyWith(color: colors.ink700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
