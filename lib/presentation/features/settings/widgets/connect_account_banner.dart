import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';

/// §11.16 게스트 상단 배너 — "계정 연결" · `accent.wash` 배경.
/// 탭하면 로그인/계정 연결 화면으로 이동만 한다(실제 연결 로직은 M5).
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
              Icon(Icons.cloud_upload_outlined, size: 28, color: colors.accent),
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
