import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/utils/keep_all.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/emergency_card.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/info_accordion.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_section.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/dividers/brush_divider.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 케어 노트의 장(章). 순서 = 노트 순서 = 탭 순서.
///
/// 요약은 늘 있고, 나머지는 데이터가 있을 때만 생긴다(응급신호·섹션·제품).
/// "정보 → 병원 신호 → 돌보는 법 → 추천 용품" 순으로 넘기게 해, 안전 정보를 먼저
/// 지나 제품에 닿는 흐름을 만든다.
enum NoteChapter {
  overview('요약', 'overview'),
  emergency('병원 신호', 'emergency'),
  guide('돌보는 법', 'guide'),
  products('추천 용품', 'products');

  const NoteChapter(this.label, this.slug);

  final String label;

  /// 라우트 쿼리(`?chapter=`) 값.
  final String slug;

  static NoteChapter? fromSlug(String? value) {
    for (final chapter in values) {
      if (chapter.slug == value) return chapter;
    }
    return null;
  }
}

/// ① 요약 — 한눈에 보기 + 다른 이름 + "이 노트에 담긴 것"(다음 장들로 가는 목차).
class NoteOverviewChapter extends StatelessWidget {
  const NoteOverviewChapter({
    required this.symptom,
    required this.info,
    required this.chapters,
    required this.productCount,
    required this.topProductTitle,
    required this.onJump,
    super.key,
  });

  final Symptom symptom;

  /// 참고정보(로딩 중에는 스켈레톤).
  final AsyncValue<SymptomInfo?> info;
  final List<NoteChapter> chapters;
  final int productCount;
  final String? topProductTitle;
  final ValueChanged<NoteChapter> onJump;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final data = info.value;
    final aliases = symptom.aliases;
    final tone = DetailTone.audience(context, symptom.audience);
    final later = [
      for (final c in chapters)
        if (c != NoteChapter.overview) c,
    ];

    String metaOf(NoteChapter chapter) => switch (chapter) {
      NoteChapter.emergency => '꼭 알아 둘 신호 ${data?.emergency.length ?? 0}가지',
      NoteChapter.guide => '집에서 돌보는 가이드 ${data?.sections.length ?? 0}편',
      NoteChapter.products =>
        topProductTitle == null
            ? '도움되는 용품 $productCount개'
            : '$productCount개 · 1위 $topProductTitle',
      NoteChapter.overview => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (info.isLoading && data == null)
          const _SummarySkeleton()
        else if (data != null)
          ScrollReveal(
            // 겹쳐 빚은 점토 — 아랫장은 대상 톤 wash(아기 딸기 / 엄마 라일락).
            child: AppCard(
              emphasis: AppCardEmphasis.hero,
              stackColor: tone.wash,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeartOverline(
                    label: '한눈에 보기',
                    heartColor: symptom.audience == SymptomAudience.mom
                        ? tone.fg
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    keepAll(data.summary),
                    semanticsLabel: data.summary,
                    style: texts.bodyL.copyWith(color: colors.ink700),
                  ),
                ],
              ),
            ),
          ),
        if (aliases.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x20),
          ScrollReveal(
            delay: AppMotion.fast ~/ 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이렇게도 불러요',
                  style: texts.caption.copyWith(color: colors.ink500),
                ),
                const SizedBox(height: AppSpacing.x8),
                Wrap(
                  spacing: AppSpacing.x8,
                  runSpacing: AppSpacing.x8,
                  children: [
                    // 스티커 칩 — 대상 톤(아기 딸기 / 엄마 라일락) wash + 흰 테두리.
                    for (final alias in aliases)
                      StickerChip(label: alias, wash: tone.wash, fg: tone.fg),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (later.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x24),
          const BrushDivider.section(),
          const SizedBox(height: AppSpacing.x24),
          const SectionHeader(overline: 'CONTENTS', title: '이 노트에 담긴 것'),
          const SizedBox(height: AppSpacing.x12),
          ScrollReveal(
            delay: AppMotion.fast ~/ 3,
            child: AppCard(
              emphasis: AppCardEmphasis.raised,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
              child: Column(
                children: [
                  for (final (i, chapter) in later.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.line,
                        indent: _ContentsRow.textInset,
                        endIndent: AppSpacing.x16,
                      ),
                    _ContentsRow(
                      number: chapters.indexOf(chapter) + 1,
                      chapter: chapter,
                      meta: metaOf(chapter),
                      onTap: () => onJump(chapter),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ② 병원 신호 — 기존 응급 카드(흔들림·바 펄스·병원 찾기·119)를 그대로 쓴다.
class NoteEmergencyChapter extends StatelessWidget {
  const NoteEmergencyChapter({
    required this.signs,
    required this.visible,
    super.key,
  });

  final List<EmergencySign> signs;

  /// 장이 화면에 들어왔는지 — 응급 카드 등장 연출을 그때 1회 재생한다.
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, open, _) => ScrollReveal(
        child: EmergencyCard(signs: signs, active: open),
      ),
    );
  }
}

/// ③ 돌보는 법 — 섹션 아코디언 + 참고 자료.
class NoteGuideChapter extends StatelessWidget {
  const NoteGuideChapter({required this.info, super.key});

  final SymptomInfo info;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final captionStyle = texts.caption.copyWith(color: colors.ink500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '집에서 돌보는 법',
          trailing: StickerChip(
            label: '${info.sections.length}편',
            wash: colors.sageWash,
            fg: colors.sage,
            dense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        InfoAccordionList(sections: info.sections),
        // §11.9 개정 — 참고 자료(출처 label 불릿). 탭 액션·URL 노출 없음.
        // 둥근 크림 메모(오목한 paperBg 면) 안에 출처를 모은다.
        if (info.sources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x12,
              AppSpacing.x16,
              AppSpacing.x12,
            ),
            decoration: BoxDecoration(
              color: colors.paperBg,
              borderRadius: AppRadius.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: colors.ink500,
                    ),
                    const SizedBox(width: AppSpacing.x4 + AppSpacing.x2),
                    Text('참고 자료', style: captionStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                for (final source in info.sources)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors.ink300,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.iconTextGap),
                        Expanded(
                          child: Text(source.label, style: captionStyle),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// ④ 추천 용품 — 에디토리얼 랭킹 보드(§7.3-6)와 대가성 표시(§13.2)를 그대로 쓴다.
class NoteProductsChapter extends StatelessWidget {
  const NoteProductsChapter({required this.symptomId, super.key});

  final String symptomId;

  @override
  Widget build(BuildContext context) => ProductSection(symptomId: symptomId);
}

/// 장 끝의 "다음 장" 카드 — 넘기지 않고 눌러서도 다음 장으로 간다.
///
/// DESIGN v3 — 둥근 크림 카드(e2) + 주아체 번호 버블 + 젤리 화살표 버튼.
class NoteNextCard extends StatelessWidget {
  const NoteNextCard({
    required this.number,
    required this.chapter,
    required this.onTap,
    super.key,
  });

  final int number;
  final NoteChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final arrowFill = colors.accentFill;

    return Semantics(
      button: true,
      label: '다음 장, ${chapter.label}',
      excludeSemantics: true,
      child: TapSpring(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x12,
            AppSpacing.x12,
            AppSpacing.x12,
            AppSpacing.x12,
          ),
          decoration: BoxDecoration(
            color: colors.paperRaised,
            borderRadius: AppRadius.brLg,
            boxShadow: context.shadows.e2,
          ),
          child: Row(
            children: [
              ClayBubble(
                size: 48,
                wash: colors.accentWash,
                child: ClayNumber('$number', color: colors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NEXT',
                      style: texts.overline.copyWith(color: colors.ink500),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      chapter.label,
                      style: texts.heading.copyWith(color: colors.ink900),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ClaySheen.gradient(context, arrowFill),
                  boxShadow: ClaySheen.toneShadow(context, arrowFill),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                  color: colors.paperRaised,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §11.9-5 / §13.3 의학 면책 — 모든 장 끝에 늘 노출(격은 낮게, 존재감만).
/// baby 문구는 원문 그대로(바이트 단위 불변). mom은 상담 대상만 분기(§13.3 개정).
///
/// DESIGN v3 — 시트보다 한 톤 낮은 크림(`paperBg`) 둥근 메모. 캡션 `ink500`은
/// 이 면 위에서 4.78:1(AA).
class NoteDisclaimer extends StatelessWidget {
  const NoteDisclaimer({required this.audience, super.key});

  final SymptomAudience audience;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x12,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colors.ink500,
            ),
          ),
          const SizedBox(width: AppSpacing.iconTextGap),
          Expanded(
            child: Text(
              audience == SymptomAudience.mom
                  ? '본 정보는 의학적 진단이 아니며 참고용입니다. '
                        '증상이 우려되면 산부인과 전문의 등 의료진과 상담하세요.'
                  : '본 정보는 의학적 진단이 아니며 참고용입니다. '
                        '증상이 우려되면 소아과 전문의와 상담하세요.',
              style: texts.caption.copyWith(color: colors.ink500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목차 한 줄 — 파스텔 아이콘 버블(+ 주아체 장 번호 스티커) + 장 이름 + 요약 메타 +
/// 동그란 셰브론 버블.
class _ContentsRow extends StatelessWidget {
  const _ContentsRow({
    required this.number,
    required this.chapter,
    required this.meta,
    required this.onTap,
  });

  final int number;
  final NoteChapter chapter;
  final String meta;
  final VoidCallback onTap;

  static const double _bubble = 42;

  /// 글자 시작 x(구분선 들여쓰기에 맞춘다).
  static const double textInset = AppSpacing.x16 + _bubble + AppSpacing.x12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final (icon, wash, tone) = switch (chapter) {
      NoteChapter.emergency => (
        Icons.local_hospital_rounded,
        colors.coralWash,
        colors.coral,
      ),
      NoteChapter.guide => (Icons.spa_rounded, colors.sageWash, colors.sage),
      NoteChapter.products => (
        Icons.auto_awesome_rounded,
        colors.amberWash,
        colors.amber,
      ),
      NoteChapter.overview => (
        Icons.article_rounded,
        colors.accentWash,
        colors.accent,
      ),
    };

    return Semantics(
      button: true,
      label: '${chapter.label}, $meta',
      excludeSemantics: true,
      child: TapSpring(
        onTap: onTap,
        pressedScale: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x12,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClayBubble(
                    size: _bubble,
                    wash: wash,
                    icon: icon,
                    iconColor: tone,
                    iconSize: 20,
                  ),
                  // 장 번호 스티커(주아체).
                  Positioned(
                    left: -AppSpacing.x4,
                    top: -AppSpacing.x4,
                    child: ClayBubble(
                      size: 20,
                      wash: colors.paperRaised,
                      outline: true,
                      lifted: true,
                      child: ClayNumber('$number', color: tone, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chapter.label,
                      style: texts.body.copyWith(
                        color: colors.ink900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: texts.caption.copyWith(color: colors.ink500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              ClayBubble(
                size: 28,
                wash: colors.paperStack,
                icon: Icons.chevron_right_rounded,
                iconColor: colors.ink500,
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 요약 자리 로딩 스켈레톤 — hero 격(paperRaised/e2/brLg)과 라디우스·표면을 맞춘다.
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
    );
  }
}
