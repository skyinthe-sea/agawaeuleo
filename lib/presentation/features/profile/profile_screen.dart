import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../../core/support/support_contact.dart';
import '../../router/routes.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/dividers/brush_divider.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'providers/profile_providers.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_tile.dart';

/// §11.13 내 정보(탭3 루트).
///
/// 상단 프로필 헤더(엄마·아가 클레이 쿠션 · 이름 · 이메일/게스트 안내) + 메뉴
/// 리스트(아기 프로필 · 즐겨찾기 · 설정 · 문의). 각 행 높이 56, 우측 chevron(소프트
/// 원), 탭 시 잉크 워시 리플.
///
/// DESIGN v3 §5.1/§6 — 헤더 블록 아래 [BrushDivider.section]로 "격 전환"을 표시하고
/// (§6.4, 32dp 간격), 메뉴는 벤토 라운드 카드(raised) 안에 항목별 파스텔 wash
/// 버블 + 진입 stagger로 담는다.
///
/// 통합 메모: 도메인 [AuthRepository]에 표시용 이메일/닉네임 필드가 없어
/// "아바타 탭 → 프로필 편집" 대상 화면이 라우트 트리(§4.1)에 없다. 게스트는
/// 로그인/계정 연결 화면으로, 연결된 계정은 설정(계정 관리)으로 보낸다 —
/// 전용 "프로필 편집" 화면·라우트가 추가되면 이 지점을 교체할 것.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: PaperBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // 게스트 전용 모드: 계정 연결/편집 진입점을 숨긴다 —
              // onTap 없이 정보 표시용 헤더로만 노출(chevron·탭 없음).
              ProfileHeader(isGuest: isGuest),
              const SizedBox(height: AppSpacing.x12),
              const BrushDivider.section(),
              const SizedBox(height: AppSpacing.x32),
              AppCard(
                padding: EdgeInsets.zero,
                // DESIGN v3 §5.1/§6 — 벤토 느낌의 큰 라운드 카드(raised, brLg).
                emphasis: AppCardEmphasis.raised,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 기록 기능 숨김(2026-09-11 발주자 요청): 아기 프로필은 기록을
                    // 아기별로 나누기 위한 메뉴라 기록 탭과 함께 숨긴다. 라우트
                    // (`Routes.babyProfile`)와 화면은 그대로라 주석만 해제하면 된다.
                    // ProfileMenuTile(
                    //   icon: Icons.child_care_outlined,
                    //   label: '아기 프로필',
                    //   washColor: colors.accentWash,
                    //   iconColor: colors.accent,
                    //   index: 0,
                    //   onTap: () => context.pushNamed(Routes.babyProfile),
                    // ),
                    // Divider(height: 1, thickness: 1, color: colors.line),
                    ProfileMenuTile(
                      icon: Icons.star_outline_rounded,
                      label: '즐겨찾기',
                      washColor: colors.amberWash,
                      iconColor: colors.amber,
                      index: 0,
                      onTap: () => context.pushNamed(Routes.favorites),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.line),
                    ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      label: '설정',
                      // DESIGN v3 §3.1/§6 — 엄마 돌봄 톤(lilac)으로 벤토 행 색을 다양화.
                      washColor: colors.lilacWash,
                      iconColor: colors.lilac,
                      index: 1,
                      onTap: () => context.pushNamed(Routes.settings),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.line),
                    ProfileMenuTile(
                      icon: Icons.mail_outline_rounded,
                      label: '문의',
                      washColor: colors.sageWash,
                      iconColor: colors.sage,
                      index: 2,
                      onTap: () => launchSupportEmail(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
