import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../brand/ink_halo_icon.dart';
import '../buttons/ghost_button.dart';
import '../buttons/primary_button.dart';

/// 다이얼로그 공용 셸(DESIGN v2 §4.6 표면 격 통일 → v3 §5.1 "몽글 클레이").
///
/// `paperRaised` + r.xl(34) + 장밋빛 음영 e3, 좌상단 클레이 버블 [InkHaloIcon](48) +
/// 주아체 `title`(22) + `bodyL`(ink700) 본문 + 알약 액션 행(보조=[GhostButton],
/// 주=[PrimaryButton]). [destructive]가 true면 버블이 `coralWash`/`coral`, 주 버튼
/// 면이 `coral`(`PrimaryButton.tone`, 글자 `paperRaised`)로 바뀐다 — 토마토색은 응급·
/// 파괴 동작 전용 의미 색이다.
///
/// 로그아웃/계정삭제(2단계)/아기 프로필 삭제 다이얼로그의 200ms 지연 스피너·
/// "삭제" 재입력 로직 등 기존 흐름 로직은 그대로 두고 셸(표면)만 이 위젯으로
/// 교체한다 — [content]에 재입력 필드 같은 임의 위젯을 추가로 얹을 수 있다.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.destructive = false,
    this.primaryLabel,
    this.onPrimary,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.content,
  });

  final String title;
  final String message;
  final IconData icon;

  /// true면 버블(coralWash/coral) + 주 버튼(coral 면) 배색으로 전환.
  final bool destructive;

  final String? primaryLabel;
  final VoidCallback? onPrimary;

  /// 주 버튼 로딩 상태(라벨→스피너 크로스페이드).
  final bool primaryLoading;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// 본문 아래 추가 위젯(재입력 필드 등).
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final haloWash = destructive ? colors.coralWash : colors.accentWash;
    final haloFg = destructive ? colors.coral : colors.accent;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.x24,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paperRaised,
          borderRadius: AppRadius.brXl,
          boxShadow: context.shadows.e3,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkHaloIcon(
                size: 48,
                icon: icon,
                washColor: haloWash,
                fgColor: haloFg,
                ring: false,
              ),
              const SizedBox(height: AppSpacing.x16),
              Text(title, style: texts.title.copyWith(color: colors.ink900)),
              const SizedBox(height: AppSpacing.x8),
              Text(message, style: texts.bodyL.copyWith(color: colors.ink700)),
              if (content != null) ...[
                const SizedBox(height: AppSpacing.x16),
                content!,
              ],
              const SizedBox(height: AppSpacing.x24),
              Row(
                children: [
                  if (secondaryLabel != null)
                    Expanded(
                      child: GhostButton(
                        label: secondaryLabel!,
                        onPressed: onSecondary,
                      ),
                    ),
                  if (secondaryLabel != null && primaryLabel != null)
                    const SizedBox(width: AppSpacing.x12),
                  if (primaryLabel != null)
                    Expanded(
                      child: PrimaryButton(
                        label: primaryLabel!,
                        onPressed: onPrimary,
                        loading: primaryLoading,
                        tone: destructive ? colors.coral : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [AppDialogShell]을 `showDialog`로 여는 공용 헬퍼. 배리어색은 `showAppBottomSheet`
/// 와 동일하게 `ink900` 32%로 통일한다.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline_rounded,
  bool destructive = false,
  String? primaryLabel,
  VoidCallback? onPrimary,
  bool primaryLoading = false,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  Widget? content,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: context.colors.ink900.withValues(alpha: 0.32),
    builder: (dialogContext) => AppDialogShell(
      title: title,
      message: message,
      icon: icon,
      destructive: destructive,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      primaryLoading: primaryLoading,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
      content: content,
    ),
  );
}
