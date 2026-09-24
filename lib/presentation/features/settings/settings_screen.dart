import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/notification_providers.dart';
import '../../../application/notifiers/theme_mode_notifier.dart';
import '../../../config/theme/theme.dart';
import '../../../core/notifications/notifications.dart';
import '../../../core/support/support_contact.dart';
import '../../router/routes.dart';
import '../../widgets/animated/shimmer_skeleton.dart';
import '../../widgets/navigation/app_app_bar.dart';
import '../../widgets/segments/sliding_segment.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'providers/settings_providers.dart';
import 'terms_doc.dart';
import 'widgets/app_switch.dart';
// 게스트 전용 모드: 계정 연결 배너 숨김(아래 사용처와 함께 주석 처리).
// import 'widgets/connect_account_banner.dart';
import 'widgets/notification_permission_hint.dart';
import 'widgets/settings_group.dart';

/// §11.16 설정 — 그룹형 리스트(화면 / 알림 / 계정 / 정보).
///
/// **범위**: 테마 전환·알림 로컬 저장·약관 뷰어·라이선스·문의는 여기서 동작까지
/// 완성한다. 계정 연결(Apple/Google/이메일 승격)·계정 삭제의 실제 서버 호출과
/// 로그인 이후 세션 갱신은 M5 몫이며, 확인 다이얼로그까지만 이 feature가 담당한다
/// ([AccountScreen] · `dialogs/account_action_dialogs.dart`).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isGuest = ref.watch(isGuestAccountProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final notifications =
        ref.watch(notificationSettingsProvider).value ??
        const NotificationSettings();
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: const AppAppBar(title: '설정'),
      body: PaperBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // 게스트 전용 모드: 계정 연결 유도 배너 숨김(계정 기능 복원 시 되돌릴 것).
            // §11.16 원문: 게스트일 때 화면 최상단에 ConnectAccountBanner 노출.
            // if (isGuest) ...[
            //   ConnectAccountBanner(
            //     onTap: () => context.pushNamed(Routes.login),
            //   ),
            //   const SizedBox(height: AppSpacing.sectionGap),
            // ],
            _buildScreenGroup(context, ref, themeMode),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildNotificationGroup(context, ref, notifications),
            if (!isGuest) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              _buildAccountGroup(context),
            ],
            const SizedBox(height: AppSpacing.sectionGap),
            _buildInfoGroup(context, appVersion),
          ],
        ),
      ),
    );
  }

  /// "화면" 그룹: 테마 세그먼트(라이트/다크/시스템) + 글자 크기 안내.
  Widget _buildScreenGroup(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    final colors = context.colors;
    return SettingsGroup(
      header: '화면',
      children: [
        SettingsTile(
          label: '테마',
          icon: Icons.contrast_rounded,
          iconWash: colors.accentWash,
          iconColor: colors.accent,
          trailing: SizedBox(
            width: 176,
            // DESIGN v2 §4.7/§7.7 — 사설 `SegmentedControl` 중복 구현을 공용
            // `SlidingSegment`로 교체.
            child: SlidingSegment<ThemeMode>(
              items: const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
              selected: themeMode,
              labelOf: (mode) => switch (mode) {
                ThemeMode.light => '라이트',
                ThemeMode.dark => '다크',
                ThemeMode.system => '시스템',
              },
              // §11.16: 탭 즉시 전체 테마 크로스페이드(300ms, main.dart MaterialApp에
              // themeAnimationDuration으로 배선됨) + 선택 저장.
              onChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(mode),
            ),
          ),
        ),
        SettingsTile(
          label: '글자 크기',
          icon: Icons.text_fields_rounded,
          iconWash: colors.lilacWash,
          iconColor: colors.lilac,
          subtitle: '기기 설정을 따라 자동으로 조절돼요',
        ),
      ],
    );
  }

  /// "알림" 그룹: 마스터 토글 + 카테고리 토글(수유 리마인더/공지) + 권한 안내.
  Widget _buildNotificationGroup(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    final colors = context.colors;
    final controller = ref.read(notificationSettingsProvider.notifier);
    // §11.16·§11.6(개정): OS 권한이 켜져 있지 않을 때만 안내를 노출한다.
    // granted → 숨김, 조회 중(loading)·unknown(판단 불가) → 오탐 방지 위해 숨김.
    final permissionStatus = ref
        .watch(notificationPermissionStatusProvider)
        .value;
    final showPermissionHint =
        settings.masterEnabled &&
        permissionStatus != null &&
        !permissionStatus.isGranted &&
        permissionStatus != NotificationPermissionStatus.unknown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsGroup(
          header: '알림',
          children: [
            SettingsTile(
              label: '전체 알림',
              icon: Icons.notifications_none_rounded,
              iconWash: colors.amberWash,
              iconColor: colors.amber,
              trailing: AppSwitch(value: settings.masterEnabled),
              useSelectionHaptic: true,
              onTap: () => controller.setMaster(!settings.masterEnabled),
            ),
            // 기록 기능 숨김(2026-09-11 발주자 요청): 수유 리마인더는 최근 수유 기록으로
            // 다음 알림을 잡는 기능이라 기록 탭과 함께 숨긴다(주석 해제로 복원).
            // SettingsTile(
            //   label: '수유 리마인더',
            //   icon: Icons.access_time_rounded,
            //   trailing: AppSwitch(
            //     value: settings.feedingReminderEnabled,
            //     enabled: settings.masterEnabled,
            //   ),
            //   enabled: settings.masterEnabled,
            //   useSelectionHaptic: true,
            //   onTap: () => controller.setFeedingReminder(
            //     !settings.feedingReminderEnabled,
            //   ),
            // ),
            SettingsTile(
              label: '공지사항',
              icon: Icons.campaign_outlined,
              iconWash: colors.sageWash,
              iconColor: colors.sage,
              trailing: AppSwitch(
                value: settings.noticeEnabled,
                enabled: settings.masterEnabled,
              ),
              enabled: settings.masterEnabled,
              useSelectionHaptic: true,
              onTap: () => controller.setNotice(!settings.noticeEnabled),
            ),
          ],
        ),
        if (showPermissionHint)
          NotificationPermissionHint(
            status: permissionStatus,
            onOpenPriming: () => context.pushNamed(Routes.permissionPriming),
          ),
      ],
    );
  }

  /// "계정" 그룹(연결된 사용자만) — 세부 관리는 [Routes.account]로 위임한다.
  /// 게스트 상태는 화면 최상단 배너가 대신하므로 이 그룹은 노출하지 않는다.
  Widget _buildAccountGroup(BuildContext context) {
    final colors = context.colors;
    return SettingsGroup(
      header: '계정',
      children: [
        SettingsTile(
          label: '계정 관리',
          icon: Icons.manage_accounts_outlined,
          iconWash: colors.accentWash,
          iconColor: colors.accent,
          showChevron: true,
          onTap: () => context.pushNamed(Routes.account),
        ),
      ],
    );
  }

  /// "정보" 그룹: 개인정보처리방침 / 이용약관 / 오픈소스 라이선스 / 앱 버전 / 문의.
  Widget _buildInfoGroup(BuildContext context, AsyncValue<String> appVersion) {
    final colors = context.colors;
    return SettingsGroup(
      header: '정보',
      children: [
        SettingsTile(
          label: TermsDoc.titleOf(TermsDoc.privacy),
          icon: Icons.privacy_tip_outlined,
          iconWash: colors.accentWash,
          iconColor: colors.accent,
          showChevron: true,
          onTap: () => context.pushNamed(
            Routes.terms,
            pathParameters: {RouteParams.doc: TermsDoc.privacy},
          ),
        ),
        SettingsTile(
          label: TermsDoc.titleOf(TermsDoc.terms),
          icon: Icons.description_outlined,
          iconWash: colors.lilacWash,
          iconColor: colors.lilac,
          showChevron: true,
          onTap: () => context.pushNamed(
            Routes.terms,
            pathParameters: {RouteParams.doc: TermsDoc.terms},
          ),
        ),
        // 오픈소스 라이선스 표기 숨김(발주자 요청). 필요 시 아래 타일을 복원할 것.
        // SettingsTile(
        //   label: '오픈소스 라이선스',
        //   icon: Icons.code_rounded,
        //   showChevron: true,
        //   onTap: () => showLicensePage(
        //     context: context,
        //     applicationName: '아가왜울어',
        //     applicationVersion: appVersion.value,
        //   ),
        // ),
        SettingsTile(
          label: '앱 버전',
          icon: Icons.info_outline_rounded,
          iconWash: colors.sageWash,
          iconColor: colors.sage,
          trailing: appVersion.when(
            data: (value) => Text(
              value,
              style: context.texts.body.copyWith(color: colors.ink500),
            ),
            loading: () => const ShimmerSkeleton(width: 48, height: 14),
            error: (_, _) => Text(
              '—',
              style: context.texts.body.copyWith(color: colors.ink500),
            ),
          ),
        ),
        SettingsTile(
          label: '문의',
          icon: Icons.mail_outline_rounded,
          iconWash: colors.amberWash,
          iconColor: colors.amber,
          showChevron: true,
          onTap: () => launchSupportEmail(context),
        ),
      ],
    );
  }
}
