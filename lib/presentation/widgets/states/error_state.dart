import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';
import '../brand/ink_halo_icon.dart';
import '../buttons/primary_button.dart';
import 'clay_scene_art.dart';

/// §11.17 에러 상태. coral 아이콘 + 무엇이 잘못됐는지 + "다시 시도" 버튼(필수).
/// 사과체 금지 — 원인·해결 중심의 인터페이스 목소리.
///
/// DESIGN v3 §5.5 — 그림 자리는 [illustrationAsset](클레이 장면 140 + 토마토 wash
/// 쿠션, 보통 `ClayScenes.oops`)이 있으면 그것을, 없으면 클레이 버블
/// [InkHaloIcon](coralWash/coral)을 쓴다. 제목은 주아체 `heading`, 버튼은 작은 젤리
/// 알약. [EmptyState]와 동형의 진입 모션(fadeIn + slideY).
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    super.key,
    this.title = '불러오지 못했어요',
    this.message = '연결을 확인하고 다시 시도해 주세요.',
    this.retryLabel = '다시 시도',
    this.icon = Icons.error_outline_rounded,
    this.illustrationAsset,
  });

  final VoidCallback onRetry;
  final String title;
  final String message;
  final String retryLabel;
  final IconData icon;

  /// 클레이 장면 에셋 경로(예: `ClayScenes.oops`). 지정 시 아이콘 버블 대신 그린다.
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (illustrationAsset case final asset?)
          ClaySceneArt(asset: asset, wash: colors.coralWash)
        else
          InkHaloIcon(
            size: 56,
            icon: icon,
            washColor: colors.coralWash,
            fgColor: colors.coral,
            iconSize: 32,
          ),
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
    );

    if (!reduce) {
      content = content
          .animate()
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: 0.08, end: 0, curve: AppMotion.enter);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: content,
      ),
    );
  }
}
