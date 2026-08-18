import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_thumbnail.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-6 추천 제품 카드(DESIGN v2 §7.3-6 확장 — "에디토리얼 랭킹 보드").
///
/// 1위는 [ProductHeroCard](겹친 한지 hero 격 + 큰 썸네일 + CTA)로, 2위 이하는
/// 이 [ProductCard] 행으로 그린다. 두 카드 모두 제목과 한 줄 설명(`blurb`)을
/// 노출하며, 가격·평점은 표시하지 않는다 — 파트너스 API 승인 전까지 어드민
/// 수동 입력값이라 시세를 따라가지 못한다(마이그레이션 0011). 엔티티 필드는
/// 보존되므로 승인 후 되살릴 수 있다.
///
/// 순위 배지는 §7.3-6의 "1위만 amber"를 **포디엄 톤 사다리**로 확장한다 —
/// 1위 amber · 2위 accent · 3위 sage · 4위 이하 중립(`paperRaised`/`ink500`).
/// 전부 기존 토큰 조합이며 새 색을 만들지 않는다.
///
/// 탭 → 딥링크 외부 오픈(§13.1) + 스프링/눌림 그림자 + 잉크 워시(AppCard 처리).

/// 순위별 배지 톤(전경/배경). 4위부터는 사진 위에서도 읽히도록 불투명
/// `paperRaised` + `ink500`을 쓴다.
({Color fg, Color wash}) _rankTone(AppColors colors, int rank) =>
    switch (rank) {
      1 => (fg: colors.amber, wash: colors.amberWash),
      2 => (fg: colors.accent, wash: colors.accentWash),
      3 => (fg: colors.sage, wash: colors.sageWash),
      _ => (fg: colors.ink500, wash: colors.paperRaised),
    };

/// 1위 전용 히어로 쇼케이스 카드.
///
/// 구조: 상단 리본(`1` 배지 + `BEST PICK` 오버라인 + 왕관) → 큰 썸네일 104
/// (느린 호흡 모션) + 제목 `bodyL` 3줄 + 한 줄 설명 → 헤어라인 → CTA 알약
/// ("쿠팡에서 보기" + 화살표 넛지). 카드 격은 `AppCardEmphasis.hero`
/// (`paperRaised` + e2 + 겹친 한지 아랫장 + 그레인).
class ProductHeroCard extends StatelessWidget {
  const ProductHeroCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final blurb = product.blurb?.trim() ?? '';
    final tone = _rankTone(colors, 1);

    return AppCard(
      emphasis: AppCardEmphasis.hero,
      onTap: () => ExternalLauncher.openDeeplink(product.deeplink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _RankBadge(rank: 1),
              const SizedBox(width: AppSpacing.iconTextGap),
              Expanded(
                child: Text(
                  'BEST PICK',
                  style: texts.overline.copyWith(color: tone.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.workspace_premium_rounded, size: 18, color: tone.fg),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumbnail(
                imageUrl: product.imageUrl,
                size: 104,
                radius: AppRadius.brMd,
                breathe: true,
              ),
              const SizedBox(width: AppSpacing.x16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: texts.bodyL.copyWith(color: colors.ink900),
                    ),
                    if (blurb.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x8),
                      _BlurbLine(blurb: blurb, maxLines: 2),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          ColoredBox(
            color: colors.line,
            child: const SizedBox(height: 1, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.x16),
          // 카드가 앉는 동안(0.45~0.9) CTA가 밀려 올라오며 자리를 잡는다.
          const RevealMotion(
            begin: 0.45,
            end: 0.9,
            rise: AppSpacing.x16,
            fade: true,
            child: _CtaPill(),
          ),
        ],
      ),
    );
  }
}

/// 2위 이하 행 카드 — 썸네일 76(좌상단 순위 배지) + 제목 2줄 + 한 줄 설명 +
/// 우측 원형 외부링크 어피던스.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.rank, super.key});

  final Product product;

  /// 증상 내 노출 순위(1부터). 배지에 그대로 표시된다.
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    // 어드민이 설명을 비워둘 수 있다 → 빈 값이면 설명 줄을 아예 그리지 않는다.
    final blurb = product.blurb?.trim() ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x12),
      onTap: () => ExternalLauncher.openDeeplink(product.deeplink),
      child: Row(
        children: [
          Stack(
            // 순위 배지가 스탬프처럼 크게 들어왔다 앉으므로(RevealMotion) 기본
            // hardEdge 클립을 끄지 않으면 등장 순간 배지 모서리가 잘린다.
            clipBehavior: Clip.none,
            children: [
              ProductThumbnail(imageUrl: product.imageUrl, size: 76),
              Positioned(
                top: AppSpacing.x4,
                left: AppSpacing.x4,
                child: _RankBadge(rank: rank),
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
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: texts.body.copyWith(color: colors.ink900),
                ),
                if (blurb.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x4),
                  _BlurbLine(blurb: blurb, maxLines: 1, dot: true),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          const _OpenAffordance(),
        ],
      ),
    );
  }
}

/// 순위 배지(1부터). 포디엄 톤 사다리 + 톤 헤어라인. 두 자리 순위·큰 textScaler
/// 에서도 넘치지 않도록 [FittedBox]로 축소한다.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final tone = _rankTone(colors, rank);

    // 카드가 앉는 동안(0.3~0.75) 도장 찍히듯 크게 들어와 제자리에 앉는다.
    return RevealMotion(
      begin: 0.3,
      end: 0.75,
      curve: AppMotion.spring,
      scaleFrom: 1.7,
      fade: true,
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.wash,
          borderRadius: AppRadius.brXs,
          border: Border.all(color: tone.fg.withValues(alpha: 0.35)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
            child: Text('$rank', style: texts.data.copyWith(color: tone.fg)),
          ),
        ),
      ),
    );
  }
}

/// 제목 아래 한 줄 설명(`products.blurb` — 어드민 수동 입력, 0011의 가격 대체).
/// [dot]이면 앞에 3dp 잉크 점을 찍어 제목과 시각적으로 분리한다.
class _BlurbLine extends StatelessWidget {
  const _BlurbLine({
    required this.blurb,
    required this.maxLines,
    this.dot = false,
  });

  final String blurb;
  final int maxLines;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final text = Text(
      blurb,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: texts.caption.copyWith(color: colors.ink500),
    );
    if (!dot) return text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: colors.ink300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.x4),
        Expanded(child: text),
      ],
    );
  }
}

/// 히어로 카드 하단 CTA 알약. 카드 전체가 이미 탭 대상이므로 제스처는 갖지
/// 않고 **어피던스만** 담당한다(§13.1 외부 오픈은 카드 탭이 수행).
class _CtaPill extends StatelessWidget {
  const _CtaPill();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: 18,
      color: colors.accentDeep,
    );

    return Container(
      // 고정 높이 대신 최소 높이 — 큰 textScaler에서도 라벨이 잘리지 않는다.
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              '쿠팡에서 보기',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.label.copyWith(color: colors.accentDeep),
            ),
          ),
          const SizedBox(width: AppSpacing.iconTextGap),
          if (context.reduceMotion)
            arrow
          else
            // 모션 토큰 파생값(shimmer 1200ms) — 6dp 왕복 넛지로 "나간다"는 신호.
            arrow
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .moveX(
                  begin: 0,
                  end: 6,
                  duration: AppMotion.shimmer,
                  curve: AppMotion.standard,
                ),
        ],
      ),
    );
  }
}

/// 행 카드 우측 원형 외부링크 어피던스(32dp 워시 원 + 대각 화살표).
class _OpenAffordance extends StatelessWidget {
  const _OpenAffordance();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_outward_rounded, size: 16, color: colors.accent),
    );
  }
}
