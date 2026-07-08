import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import '../../widgets/cards/app_card.dart';
import 'providers/profile_providers.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_tile.dart';

/// §11.13 내 정보(탭3 루트).
///
/// 상단 프로필 헤더(아바타 64 · 이름 · 이메일/게스트 안내) + 메뉴 리스트
/// (아기 프로필 · 즐겨찾기 · 설정 · 문의). 각 행 높이 56, 우측 chevron, 탭 시
/// 잉크 워시 리플.
///
/// 통합 메모: 도메인 [AuthRepository]에 표시용 이메일/닉네임 필드가 없어
/// "아바타 탭 → 프로필 편집" 대상 화면이 라우트 트리(§4.1)에 없다. 게스트는
/// 로그인/계정 연결 화면으로, 연결된 계정은 설정(계정 관리)으로 보낸다 —
/// 전용 "프로필 편집" 화면·라우트가 추가되면 이 지점을 교체할 것.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String _contactEmail = 'support@agawaeuleo.app';

  Future<void> _openContact(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: <String, String>{'subject': '아가왜울어 문의'},
    );
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('메일 앱을 열 수 없어요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isGuest = ref.watch(isGuestProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ProfileHeader(
              isGuest: isGuest,
              subtitle: userId,
              onTap: () =>
                  context.pushNamed(isGuest ? Routes.login : Routes.settings),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileMenuTile(
                    icon: Icons.child_care_outlined,
                    label: '아기 프로필',
                    onTap: () => context.pushNamed(Routes.babyProfile),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  ProfileMenuTile(
                    icon: Icons.star_outline_rounded,
                    label: '즐겨찾기',
                    onTap: () => context.pushNamed(Routes.favorites),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  ProfileMenuTile(
                    icon: Icons.settings_outlined,
                    label: '설정',
                    onTap: () => context.pushNamed(Routes.settings),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  ProfileMenuTile(
                    icon: Icons.mail_outline_rounded,
                    label: '문의',
                    onTap: () => _openContact(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
