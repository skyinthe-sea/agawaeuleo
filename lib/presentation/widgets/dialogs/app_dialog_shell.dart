import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';
import '../brand/ink_halo_icon.dart';
import '../buttons/ghost_button.dart';
import '../buttons/primary_button.dart';

/// DESIGN v2 §4.6 표면 격 통일 — 다이얼로그 공용 셸.
///
/// `paperRaised` + r.lg + e3, 좌상단 [InkHaloIcon](44) + 명조 `title`(22) +
/// `bodyL`(ink700) 본문 + 액션 행(보조=[GhostButton], 주=[PrimaryButton]).
/// [destructive]가 true면 halo가 `coralWash`/`coral`, 주 버튼 배경이 `coral`
/// (텍스트 `paperRaised`)로 바뀐다.
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

  /// true면 halo(coralWash/coral) + 주 버튼(coral 배경) 배색으로 전환.
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
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paperRaised,
          borderRadius: AppRadius.brLg,
          boxShadow: context.shadows.e3,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkHaloIcon(
                size: 44,
                icon: icon,
                washColor: haloWash,
                fgColor: haloFg,
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
                      child: destructive
                          ? _DestructivePrimaryButton(
                              label: primaryLabel!,
                              onPressed: onPrimary,
                              loading: primaryLoading,
                            )
                          : PrimaryButton(
                              label: primaryLabel!,
                              onPressed: onPrimary,
                              loading: primaryLoading,
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

/// `destructive: true`일 때의 주 버튼 — [PrimaryButton]과 동일한 형태·모션이되
/// 배경만 `coral`(텍스트 `paperRaised`)로 바뀐다. §5.6(버튼 값 변경 없음·신규
/// variant 도입 금지) 범위를 지키기 위해 공용 [PrimaryButton] 대신 다이얼로그
/// 셸에 국한된 사설 위젯으로 둔다.
class _DestructivePrimaryButton extends StatefulWidget {
  const _DestructivePrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<_DestructivePrimaryButton> createState() =>
      _DestructivePrimaryButtonState();
}

class _DestructivePrimaryButtonState extends State<_DestructivePrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    AppHaptics.tap();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = context.reduceMotion;
    final scale = (!reduce && _pressed) ? 0.97 : 1.0;

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      height: 52,
      decoration: BoxDecoration(
        color: _enabled ? colors.coral : colors.ink300,
        borderRadius: AppRadius.brSm,
        boxShadow: _enabled ? context.shadows.e2 : const <BoxShadow>[],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppRadius.brSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.paperRaised.withValues(alpha: 0.18),
          highlightColor: Colors.transparent,
          borderRadius: AppRadius.brSm,
          onTap: _enabled ? _handleTap : null,
          onHighlightChanged: _setPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: widget.loading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.paperRaised,
                        ),
                      ),
                    )
                  : Text(
                      widget.label,
                      key: const ValueKey('label'),
                      style: context.texts.label.copyWith(
                        color: colors.paperRaised,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _handleTap : null,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: scale,
          duration: _pressed ? AppMotion.instant : AppMotion.base,
          curve: _pressed ? AppMotion.standard : AppMotion.spring,
          child: button,
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
