import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../domain/entities/entities.dart';
import '../../router/routes.dart';
import '../../widgets/navigation/app_app_bar.dart';
import '../../widgets/skeletons/skeleton_blocks.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import 'providers/favorites_providers.dart';
import 'widgets/favorite_product_tile.dart';
import 'widgets/favorite_segment_tabs.dart';
import 'widgets/favorite_symptom_card.dart';

/// §11.15 즐겨찾기.
///
/// 세그먼트(증상/제품). 증상은 홈과 동일한 그리드 카드, 제품은 증상 상세와
/// 동일한 리스트 카드로 보여준다. 각 항목의 별을 탭해 해제하면 로컬에서
/// collapse+fadeOut 애니메이션을 먼저 재생한 뒤 저장소에 반영하고, 스낵바의
/// "실행취소"로 애니메이션 도중(아직 미반영)에는 즉시 복원, 이미 반영된
/// 뒤에는 다시 즐겨찾기 추가로 되돌린다.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoriteTab _tab = FavoriteTab.symptom;

  /// 해제 요청을 받아 로컬 collapse 애니메이션이 진행 중인 대상 id.
  final Set<String> _collapsingIds = <String>{};

  Future<void> _requestUnfavorite({
    required FavoriteTargetType targetType,
    required String id,
    required String label,
  }) async {
    setState(() => _collapsingIds.add(id));
    AppHaptics.tap();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('즐겨찾기에서 지웠어요 · $label'),
        action: SnackBarAction(
          label: '실행취소',
          onPressed: () => _undo(targetType: targetType, id: id),
        ),
      ),
    );

    // §10.2 collapse+fadeOut(260ms) 재생 시간을 벌어준 뒤 실제로 반영한다.
    // 그 사이 "실행취소"가 눌리면 _collapsingIds에서 빠져 있어 아래에서 조용히 취소된다.
    await Future<void>.delayed(AppMotion.base);
    if (!mounted || !_collapsingIds.contains(id)) return;
    await ref
        .read(favoriteRepositoryProvider)
        .toggle(targetType: targetType, targetId: id);
    if (!mounted) return;
    setState(() => _collapsingIds.remove(id));
  }

  void _undo({required FavoriteTargetType targetType, required String id}) {
    if (!mounted) return;
    if (_collapsingIds.contains(id)) {
      // 아직 저장소에 반영되지 않음 — collapse만 취소하면 그대로 복원된다.
      setState(() => _collapsingIds.remove(id));
      return;
    }
    // 이미 해제가 반영됨 — 다시 즐겨찾기로 토글해 복원한다.
    unawaited(
      ref
          .read(favoriteRepositoryProvider)
          .toggle(targetType: targetType, targetId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: const AppAppBar(title: '즐겨찾기'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.x16,
                AppSpacing.screenPadding,
                AppSpacing.x8,
              ),
              child: FavoriteSegmentTabs(
                value: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.resolve(context, AppMotion.fast),
                child: _tab == FavoriteTab.symptom
                    ? _SymptomGrid(
                        key: const ValueKey(FavoriteTab.symptom),
                        collapsingIds: _collapsingIds,
                        onUnfavorite: (id, label) => _requestUnfavorite(
                          targetType: FavoriteTargetType.symptom,
                          id: id,
                          label: label,
                        ),
                      )
                    : _ProductList(
                        key: const ValueKey(FavoriteTab.product),
                        collapsingIds: _collapsingIds,
                        onUnfavorite: (id, label) => _requestUnfavorite(
                          targetType: FavoriteTargetType.product,
                          id: id,
                          label: label,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomGrid extends ConsumerWidget {
  const _SymptomGrid({
    required this.collapsingIds,
    required this.onUnfavorite,
    super.key,
  });

  final Set<String> collapsingIds;
  final void Function(String id, String label) onUnfavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteSymptomsProvider);
    return async.when(
      loading: () => GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.x12,
          crossAxisSpacing: AppSpacing.x12,
          mainAxisExtent: 120,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const SymptomCardSkeleton(),
      ),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(favoritesProvider)),
      data: (symptoms) {
        if (symptoms.isEmpty) {
          return EmptyState(
            title: '즐겨찾기한 증상이 없어요',
            message: '증상 상세에서 별을 눌러 저장해 보세요',
            icon: Icons.star_outline_rounded,
            actionLabel: '증상 둘러보기',
            onAction: () => context.goNamed(Routes.home),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.x12,
            crossAxisSpacing: AppSpacing.x12,
            mainAxisExtent: 120,
          ),
          itemCount: symptoms.length,
          itemBuilder: (context, index) {
            final symptom = symptoms[index];
            return FavoriteSymptomCard(
              key: ValueKey(symptom.id),
              symptom: symptom,
              collapsing: collapsingIds.contains(symptom.id),
              onTap: () => context.pushNamed(
                Routes.symptomDetail,
                pathParameters: {RouteParams.slug: symptom.slug},
              ),
              onUnfavorite: () => onUnfavorite(symptom.id, symptom.name),
            );
          },
        );
      },
    );
  }
}

class _ProductList extends ConsumerWidget {
  const _ProductList({
    required this.collapsingIds,
    required this.onUnfavorite,
    super.key,
  });

  final Set<String> collapsingIds;
  final void Function(String id, String label) onUnfavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteProductsProvider);
    return async.when(
      loading: () =>
          SkeletonList(builder: (_, _) => const ProductCardSkeleton()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(favoritesProvider)),
      data: (products) {
        if (products.isEmpty) {
          return EmptyState(
            title: '즐겨찾기한 용품이 없어요',
            message: '증상 상세의 추천 용품에서 별을 눌러 저장해 보세요',
            icon: Icons.star_outline_rounded,
            actionLabel: '홈에서 둘러보기',
            onAction: () => context.goNamed(Routes.home),
          );
        }
        final duration = AppMotion.resolve(context, AppMotion.base);
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final collapsing = collapsingIds.contains(product.id);
            return Column(
              key: ValueKey(product.id),
              children: [
                FavoriteProductTile(
                  product: product,
                  collapsing: collapsing,
                  onUnfavorite: () => onUnfavorite(product.id, product.title),
                ),
                if (index != products.length - 1)
                  AnimatedContainer(
                    duration: duration,
                    curve: AppMotion.exit,
                    height: collapsing ? 0 : AppSpacing.listItemGap,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
