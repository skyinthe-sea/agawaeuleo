import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../buttons/primary_button.dart';

/// §11.17 에러 상태. coral 아이콘 + 무엇이 잘못됐는지 + "다시 시도" 버튼(필수).
/// 사과체 금지 — 원인·해결 중심의 인터페이스 목소리.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    super.key,
    this.title = '불러오지 못했어요',
    this.message = '연결을 확인하고 다시 시도해 주세요.',
    this.retryLabel = '다시 시도',
    this.icon = Icons.error_outline_rounded,
  });

  final VoidCallback onRetry;
  final String title;
  final String message;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colors.coral),
            const SizedBox(height: AppSpacing.x16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: texts.heading.copyWith(color: colors.ink900),
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: texts.body.copyWith(color: colors.ink500),
            ),
            const SizedBox(height: AppSpacing.x24),
            PrimaryButton(
              label: retryLabel,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
