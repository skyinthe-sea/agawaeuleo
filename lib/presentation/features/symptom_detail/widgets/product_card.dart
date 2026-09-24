import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_thumbnail.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-6 추천 제품 카드(DESIGN v2 §7.3-6 확장 — "에디토리얼 랭킹 보드",
/// v3 "몽글 클레이" 외형).
///
/// 1위는 [ProductHeroCard](버터 아랫장 hero 격 + 버터 스티커 리본 + 큰 썸네일 +
/// 딸기 젤리 CTA)로, 2위 이하는 이 [ProductCard] 행으로 그린다. 두 카드 모두
/// 제목과 한 줄 설명(`blurb`)을 노출하며, 가격·평점은 표시하지 않는다 — 파트너스
/// API 승인 전까지 어드민 수동 입력값이라 시세를 따라가지 못한다(마이그레이션
/// 0011). 엔티티 필드는 보존되므로 승인 후 되살릴 수 있다.
///
/// 순위 배지는 **포디엄 톤 사다리**를 스티커 문법(동그란 wash + 흰 테두리 + e1 +
/// 주아체 숫자)으로 그린다 — 1위 amber · 2위 accent · 3위 sage · 4위 이하 중립
/// (`paperRaised`/`ink500`). 전부 기존 토큰 조합이며 새 색을 만들지 않는다.
///
/// 탭 → 딥링크 외부 오픈(§13.1) + 스프링/눌림 그림자 + 워시 리플(AppCard 처리).

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
/// 구조: 상단 리본(`1` 스티커 배지 + 버터 스티커 `BEST PICK`) → 큰 썸네일 104
/// (느린 호흡 모션) + 제목 `bodyL` 3줄 + 한 줄 설명 → 딸기 젤리 CTA 알약
/// ("쿠팡에서 보기" + 화살표 넛지). 카드 격은 `AppCardEmphasis.hero`
/// (`paperRaised` + e3 + 버터 wash 아랫장 + 점토 결).
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
      stackColor: tone.wash,
      onTap: () => ExternalLauncher.openDeeplink(product.deeplink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _RankBadge(rank: 1),
              const SizedBox(width: AppSpacing.iconTextGap),
              // 버터 스티커 리본.
              // 남는 폭을 스페이서와 나눠 갖지 않게 Expanded + 왼쪽 정렬(좁은 폰·큰 글자에서
              // "BEST PI…"로 잘리던 문제).
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StickerChip(
                    label: 'BEST PICK',
                    icon: Icons.workspace_premium_rounded,
                    wash: tone.wash,
                    fg: tone.fg,
                    dense: true,
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: colors.seal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumbnail(
                imageUrl: product.imageUrl,
                size: 104,
                radius: AppRadius.brLg,
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
          const SizedBox(height: AppSpacing.x20),
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

/// 2위 이하 행 카드 — 썸네일 76(좌상단에 걸친 순위 스티커) + 제목 2줄 + 한 줄
/// 설명 + 우측 동그란 외부링크 버블.
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
            // 순위 스티커가 썸네일 모서리에 걸쳐 붙고, 등장 때 스탬프처럼 크게
            // 들어왔다 앉으므로(RevealMotion) 클립을 끈다.
            clipBehavior: Clip.none,
            children: [
              ProductThumbnail(
                imageUrl: product.imageUrl,
                size: 76,
                radius: AppRadius.brMd,
              ),
              // 카드 모서리 곡선(lg) 안쪽에 머물도록 4dp만 걸친다.
              Positioned(
                top: -AppSpacing.x4,
                left: -AppSpacing.x4,
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

/// 순위 스티커(1부터) — 동그란 톤 wash + 흰 스티커 테두리 + e1 + 주아체 숫자.
/// 두 자리 순위·큰 textScaler에서도 넘치지 않도록 [FittedBox]로 축소한다.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  static const double _size = 26;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = _rankTone(colors, rank);

    // 카드가 앉는 동안(0.3~0.75) 도장 찍히듯 크게 들어와 제자리에 앉는다.
    return RevealMotion(
      begin: 0.3,
      end: 0.75,
      curve: AppMotion.spring,
      scaleFrom: 1.7,
      fade: true,
      child: ClayBubble(
        size: _size,
        wash: tone.wash,
        outline: true,
        lifted: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            child: ClayNumber('$rank', color: tone.fg, size: 15),
          ),
        ),
      ),
    );
  }
}

/// 제목 아래 한 줄 설명(`products.blurb` — 어드민 수동 입력, 0011의 가격 대체).
/// [dot]이면 앞에 딸기 핑크 동그라미 점을 찍어 제목과 시각적으로 분리한다.
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: colors.seal, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.x4 + AppSpacing.x2),
        Expanded(child: text),
      ],
    );
  }
}

/// 히어로 카드 하단 CTA — 딸기 젤리 알약(클레이 광택 + 톤 그림자). 카드 전체가
/// 이미 탭 대상이므로 제스처는 갖지 않고 **어피던스만** 담당한다(§13.1 외부 오픈은
/// 카드 탭이 수행).
class _CtaPill extends StatelessWidget {
  const _CtaPill();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    // 딸기 핑크 면(accentFill) + 주아체 19 큰 글자(§3.1) — 주 버튼과 같은 알약.
    final fill = colors.accentFill;

    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: 18,
      color: colors.paperRaised,
    );

    return Container(
      // 고정 높이 대신 최소 높이 — 큰 textScaler에서도 라벨이 잘리지 않는다.
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        gradient: ClaySheen.gradient(context, fill),
        borderRadius: AppRadius.brFull,
        boxShadow: ClaySheen.toneShadow(context, fill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              '쿠팡에서 보기',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.heading.copyWith(
                color: colors.paperRaised,
                height: 1.2,
              ),
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

/// 행 카드 우측 동그란 외부링크 버블(34dp 딸기 워시 + 광택 + 대각 화살표).
class _OpenAffordance extends StatelessWidget {
  const _OpenAffordance();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClayBubble(
      size: 34,
      wash: colors.accentWash,
      icon: Icons.arrow_outward_rounded,
      iconColor: colors.accent,
      iconSize: 17,
    );
  }
}
