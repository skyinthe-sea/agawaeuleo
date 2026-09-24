import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../widgets/animated/ink_wash_splash.dart';
import '../../../widgets/brand/ink_halo_icon.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/headers/section_header.dart';

/// §11.16 그룹형 리스트의 한 그룹. 헤더(선택) + 카드 안에 [children]을 쌓고
/// 항목 사이에 헤어라인(`line`)을 자동으로 끼운다.
///
/// DESIGN v3 §5.1/§6 — 캡션 한 줄 헤더를 [SectionHeader](overline 없이)로,
/// 카드 위계를 큰 라운드 벤토 카드(`AppCard.raised`, brLg)로 승격했다.
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
              bottom: AppSpacing.x12,
            ),
            child: SectionHeader(title: header!),
          ),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          emphasis: AppCardEmphasis.raised,
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

/// §11.13/§11.16 그룹형 리스트의 한 행. 높이 56(부제 있으면 64), 좌측 아이콘은
/// 36dp 파스텔 버블([iconWash]/[iconColor]), 우측 chevron은 소프트 원 또는 커스텀
/// [trailing]. [onTap] 지정 시 잉크 워시 리플 + 햅틱([useSelectionHaptic]이면
/// `selectionClick`, 아니면 `lightImpact`).
///
/// DESIGN v3 §5.4/§6 — 24dp 단색 아이콘을 [InkHaloIcon] 클레이 버블로 승격했다.
/// [iconWash] 미지정 시 중립(`paperStack`) 버블로 폴백해 기존 호출부도 그대로
/// "말랑한" 버블을 얻는다(시각만 바뀜, 동작 불변).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.label,
    super.key,
    this.icon,
    this.iconColor,
    this.iconWash,
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

  /// 아이콘 버블 배경(미지정 시 `colors.paperStack` 중립 버블).
  final Color? iconWash;
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
            InkHaloIcon(
              size: 36,
              icon: icon,
              washColor: enabled
                  ? (iconWash ?? colors.paperStack)
                  : colors.paperStack,
              fgColor: resolvedIconColor,
              ring: false,
            ),
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
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.paperStack,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: colors.ink500,
              ),
            ),
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
