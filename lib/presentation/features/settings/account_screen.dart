import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import '../../widgets/navigation/app_app_bar.dart';
import 'dialogs/account_action_dialogs.dart';
import 'providers/settings_providers.dart';
import 'widgets/connect_account_banner.dart';
import 'widgets/settings_group.dart';

/// §11.16 "계정 관리" 상세 화면 (설정 › 계정 관리, [Routes.account]).
///
/// 게스트 상태에서 직접 진입해도 안전하도록(딥링크 등) 배너로 방어하고,
/// 연결된 상태에서만 로그아웃 · **계정 삭제**(강조 `coral`)를 노출한다.
/// 실제 세션 종료·서버 계정 파기 호출은 M5가 `dialogs/account_action_dialogs.dart`의
/// TODO 지점에서 완성한다 — 여기서는 확인 다이얼로그까지 동작한다.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final isGuest = ref.watch(isGuestAccountProvider);
    final userId = ref.watch(authRepositoryProvider).currentUserId;

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: const AppAppBar(title: '계정 관리'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          SettingsGroup(
            children: [
              SettingsTile(
                label: isGuest ? '게스트로 이용 중' : '계정 연결됨',
                subtitle: userId,
                icon: Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (isGuest)
            ConnectAccountBanner(onTap: () => context.pushNamed(Routes.login))
          else ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.x4,
                bottom: AppSpacing.x8,
              ),
              child: Text(
                '세션',
                style: texts.caption.copyWith(color: colors.ink500),
              ),
            ),
            SettingsGroup(
              children: [
                SettingsTile(
                  label: '로그아웃',
                  icon: Icons.logout_rounded,
                  onTap: () => showLogoutConfirmDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            SettingsGroup(
              children: [
                SettingsTile(
                  label: '계정 삭제',
                  icon: Icons.delete_outline_rounded,
                  iconColor: colors.coral,
                  labelColor: colors.coral,
                  onTap: () => showDeleteAccountConfirmFlow(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
