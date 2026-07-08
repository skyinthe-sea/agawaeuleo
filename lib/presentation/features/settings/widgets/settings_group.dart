import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';
import '../../../widgets/cards/app_card.dart';

/// §11.16 그룹형 리스트의 한 그룹. 캡션 헤더(선택) + 카드 안에 [children]을 쌓고
/// 항목 사이에 헤어라인(`line`)을 자동으로 끼운다.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key, this.header});

  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x4,
              bottom: AppSpacing.x8,
            ),
            child: Text(
              header!,
              style: context.texts.caption.copyWith(color: colors.ink500),
            ),
          ),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: colors.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// §11.13/§11.16 그룹형 리스트의 한 행. 높이 56(부제 있으면 64), 좌측 아이콘 24,
/// 우측 chevron `ink.300` 또는 커스텀 [trailing]. [onTap] 지정 시 잉크 워시 리플 +
/// 햅틱([useSelectionHaptic]이면 `selectionClick`, 아니면 `lightImpact`).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.label,
    super.key,
    this.icon,
    this.iconColor,
    this.labelColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.useSelectionHaptic = false,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? labelColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 우측에 chevron(`>`)을 보여줄지. [trailing]이 있으면 무시된다.
  final bool showChevron;

  /// true면 탭 햅틱으로 `selectionClick`(스위치/선택), 기본은 `lightImpact`(탐색).
  final bool useSelectionHaptic;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final active = enabled && onTap != null;

    void handleTap() {
      if (!active) return;
      if (useSelectionHaptic) {
        AppHaptics.toggle();
      } else {
        AppHaptics.tap();
      }
      onTap!.call();
    }

    final Color resolvedLabelColor = enabled
        ? (labelColor ?? colors.ink900)
        : colors.ink300;
    final Color resolvedIconColor = enabled
        ? (iconColor ?? colors.ink700)
        : colors.ink300;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: resolvedIconColor),
            const SizedBox(width: AppSpacing.x12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: texts.bodyL.copyWith(color: resolvedLabelColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: texts.caption.copyWith(color: colors.ink500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(Icons.chevron_right_rounded, size: 22, color: colors.ink300),
        ],
      ),
    );

    return SizedBox(
      height: subtitle != null ? 64 : 56,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: active ? handleTap : null,
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.accentWash,
          highlightColor: Colors.transparent,
          child: content,
        ),
      ),
    );
  }
}
