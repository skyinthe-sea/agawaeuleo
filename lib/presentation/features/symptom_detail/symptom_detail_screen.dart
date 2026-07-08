import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/emergency_card.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/info_accordion.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_section.dart';
import 'package:agawaeuleo/presentation/widgets/animated/sparkle.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_app_bar.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9 증상 상세 — 정보 + 제품(수익 화면).
///
/// 라우트 `slug`(§4.1)로 증상을 조회한 뒤 헤더(Hero) · 요약 · (해당 시) 응급 경고 ·
/// 정보 아코디언 · 의학 면책(§13.3) · 추천 제품(§13.2 대가성 표시)을 구성한다.
class SymptomDetailScreen extends ConsumerStatefulWidget {
  const SymptomDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<SymptomDetailScreen> createState() =>
      _SymptomDetailScreenState();
}

class _SymptomDetailScreenState extends ConsumerState<SymptomDetailScreen> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    final scrolled = notification.metrics.pixels > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final symptomAsync = ref.watch(symptomBySlugProvider(widget.slug));

    return Scaffold(
      backgroundColor: context.colors.paperBg,
      appBar: AppAppBar(scrolled: _scrolled),
      body: symptomAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => ErrorState(
          onRetry: () => ref.invalidate(symptomBySlugProvider(widget.slug)),
        ),
        data: (symptom) {
          if (symptom == null) {
            return const EmptyState(
              title: '증상을 찾을 수 없어요',
              message: '홈에서 다른 증상을 골라 보세요.',
              icon: Icons.search_off_rounded,
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: _DetailBody(symptom: symptom),
          );
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final infoAsync = ref.watch(symptomInfoProvider(symptom.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(symptom: symptom),
          const SizedBox(height: AppSpacing.sectionGap),
          infoAsync.when(
            loading: _SummarySkeleton.new,
            error: (_, _) => const SizedBox.shrink(),
            data: (info) => _InfoBlock(info: info),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // §11.9-5 / §13.3 의학 면책 — 정보 유무와 무관하게 항상 노출.
          Text(
            '본 정보는 의학적 진단이 아니며 참고용입니다. '
            '증상이 우려되면 소아과 전문의와 상담하세요.',
            style: texts.caption.copyWith(color: colors.ink500),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          ProductSection(symptomId: symptom.id),
        ],
      ),
    );
  }
}

/// §11.9-1 헤더: Hero 아이콘 56 + 증상명 title 22 + 즐겨찾기 별 24.
class _Header extends ConsumerWidget {
  const _Header({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final isFavorite =
        ref.watch(symptomFavoriteProvider(symptom.id)).value ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'symptom-icon-${symptom.id}',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.accentWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              SymptomIcons.resolve(symptom.emojiOrIcon),
              size: 30,
              color: colors.accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x16),
        Expanded(
          child: Hero(
            tag: 'symptom-name-${symptom.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                symptom.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: texts.title.copyWith(color: colors.ink900),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        Sparkle(
          isActive: isFavorite,
          onChanged: (_) => ref
              .read(favoriteRepositoryProvider)
              .toggle(
                targetType: FavoriteTargetType.symptom,
                targetId: symptom.id,
              ),
        ),
      ],
    );
  }
}

/// 요약 카드 + (해당 시) 응급 경고 + 정보 아코디언.
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.info});

  final SymptomInfo? info;

  @override
  Widget build(BuildContext context) {
    final data = info;
    if (data == null) return const SizedBox.shrink();

    final colors = context.colors;
    final texts = context.texts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // §11.9-2 요약 카드.
        AppCard(
          child: Text(
            data.summary,
            style: texts.bodyL.copyWith(color: colors.ink700),
          ),
        ),
        if (data.hasEmergency) ...[
          const SizedBox(height: AppSpacing.x16),
          EmergencyCard(signs: data.emergency),
        ],
        if (data.sections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          InfoAccordionList(sections: data.sections),
        ],
      ],
    );
  }
}

/// 요약 자리 로딩 스켈레톤(정보 도착 전).
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brMd,
        boxShadow: context.shadows.e1,
        border: Border.all(color: colors.line),
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
    );
  }
}

/// 증상 로딩 시 전체 화면 스켈레톤.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              SkeletonBox(size: 56, circle: true),
              SizedBox(width: AppSpacing.x16),
              Expanded(child: SkeletonLine(height: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const _SummarySkeleton(),
          const SizedBox(height: AppSpacing.sectionGap),
          const ProductCardSkeleton(),
          const SizedBox(height: AppSpacing.listItemGap),
          const ProductCardSkeleton(),
        ],
      ),
    );
  }
}
