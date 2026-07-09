import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/theme.dart';
import '../../widgets/buttons/ghost_button.dart';
import '../../widgets/navigation/app_app_bar.dart';
import '../../widgets/skeletons/skeleton_blocks.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import 'baby_edit_screen.dart';
import 'providers/profile_providers.dart';
import 'widgets/baby_card.dart';

/// §11.14 아기 프로필(목록 + 편집 진입).
///
/// 아기 카드 리스트(이름·생년월일·개월수 자동계산) + 하단 "아기 추가" ghost 버튼.
/// 카드 탭/추가 버튼은 [BabyEditScreen]을 push한다(§4.1 라우트 트리에 없는
/// 화면 — feature 소유 범위 내 imperative navigation).
class BabyProfileScreen extends ConsumerWidget {
  const BabyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final babiesAsync = ref.watch(babiesProvider);

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: const AppAppBar(title: '아기 프로필'),
      body: babiesAsync.when(
        loading: () => const SafeArea(top: false, child: SkeletonList()),
        error: (error, _) =>
            ErrorState(onRetry: () => ref.invalidate(babiesProvider)),
        data: (babies) {
          if (babies.isEmpty) {
            return EmptyState(
              title: '아직 등록된 아기가 없어요',
              message: '아래 버튼으로 첫 아기 프로필을 등록해 보세요',
              icon: Icons.child_care_outlined,
              actionLabel: '아기 추가',
              onAction: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const BabyEditScreen()),
              ),
            );
          }
          return SafeArea(
            top: false,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: babies.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.listItemGap),
              itemBuilder: (context, index) {
                if (index == babies.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x8),
                    child: GhostButton(
                      label: '아기 추가',
                      icon: Icons.add_rounded,
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const BabyEditScreen(),
                        ),
                      ),
                    ),
                  );
                }
                final baby = babies[index];
                return BabyCard(
                  key: ValueKey(baby.id),
                  baby: baby,
                  index: index,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => BabyEditScreen(baby: baby),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
