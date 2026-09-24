import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/care_note.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_app_bar.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9 증상 상세 — 정보 + 제품(수익 화면).
///
/// 라우트 `slug`(§4.1)로 증상을 조회해 [CareNote](장을 겹쳐 넘기는 케어 노트)를
/// 연다. 의학 면책(§13.3)은 모든 장 끝에, 대가성 표시(§13.2)는 '추천 용품' 장의
/// 목록 바로 위에 있다. [initialChapter]로 특정 장(`?chapter=products` 등)을 바로 연다.
class SymptomDetailScreen extends ConsumerWidget {
  const SymptomDetailScreen({
    required this.slug,
    super.key,
    this.initialChapter,
  });

  final String slug;
  final String? initialChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final symptomAsync = ref.watch(symptomBySlugProvider(slug));
    final symptom = symptomAsync.value;

    // 데이터가 있으면 노트가 자체 머리(뒤로·즐겨찾기)를 가진다.
    if (symptom != null) {
      return Scaffold(
        backgroundColor: colors.paperBg,
        body: CareNote(symptom: symptom, initialChapter: initialChapter),
      );
    }

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: const AppAppBar(),
      // DESIGN v2 §7.3-7 → v3 — 화면 전체에 무광 점토 결 표면을 얹는다.
      body: PaperBackground(
        child: symptomAsync.when(
          loading: () => const _DetailSkeleton(),
          error: (error, _) => ErrorState(
            onRetry: () => ref.invalidate(symptomBySlugProvider(slug)),
          ),
          data: (_) => const EmptyState(
            title: '증상을 찾을 수 없어요',
            message: '홈에서 다른 증상을 골라 보세요.',
            icon: Icons.search_off_rounded,
          ),
        ),
      ),
    );
  }
}

/// 증상 로딩 시 전체 화면 스켈레톤 — 노트 머리(이름·무대)와 요약 카드 뼈대.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(
                      width: 116,
                      height: 24,
                      radius: AppRadius.brFull,
                    ),
                    SizedBox(height: AppSpacing.x12),
                    SkeletonLine(width: 140, height: 28),
                    SizedBox(height: AppSpacing.x8),
                    SkeletonLine(width: 110, height: 14),
                  ],
                ),
              ),
              SkeletonBox(size: 120, circle: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Container(
            decoration: BoxDecoration(
              color: colors.paperRaised,
              borderRadius: AppRadius.brLg,
              boxShadow: context.shadows.e2,
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonLine(),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(width: 180),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const ProductCardSkeleton(),
        ],
      ),
    );
  }
}
