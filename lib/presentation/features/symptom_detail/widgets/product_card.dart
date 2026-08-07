import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';

/// §11.9-6 추천 제품 카드.
///
/// 높이 ~96, radius `r.md`, e1. 좌측 썸네일 72×72 `r.sm`, 우측 제목 body 2줄
/// (말줄임) + 한 줄 설명 caption `ink.500`. 우측 끝 외부링크 아이콘 16 `ink.300`.
/// 탭 → 딥링크 외부 오픈 + 스프링/눌림 그림자 + 라이트 햅틱(AppCard가 처리).
///
/// 좌상단에 20dp 순위 배지를 **모든 카드에** 얹는다([rank], 1부터). 1위는
/// DESIGN v2 §7.3-6에 따라 `amberWash`/`amber` 배지 + `lineStrong` 보더로
/// 승격하고, 2위 이하는 `paperBg`/`line`/`ink.500`의 중립 배지를 쓴다.
///
/// 가격·평점은 노출하지 않는다 — 파트너스 API 승인 전까지 어드민 수동 입력값
/// 이라 시세를 따라가지 못한다(마이그레이션 0011). 엔티티 필드는 보존되며,
/// 대신 어드민이 쓴 `blurb`(한 줄 설명)를 보여준다.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.rank, super.key});

  final Product product;

  /// 증상 내 노출 순위(1부터). 배지에 그대로 표시된다.
  final int rank;

  /// 1위 강조(`amberWash` 배지 + `lineStrong` 보더) 적용 여부.
  bool get _topRanked => rank == 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    // 어드민이 설명을 비워둘 수 있다 → 빈 값이면 설명 줄을 아예 그리지 않고,
    // 제목만 고정 높이 안에서 세로 중앙에 놓는다.
    final blurb = product.blurb?.trim() ?? '';

    final card = AppCard(
      padding: const EdgeInsets.all(AppSpacing.x12),
      // 1위는 아래 외곽 lineStrong 보더로 대체하므로 AppCard 자체 헤어라인은 끈다.
      showBorder: !_topRanked,
      onTap: () => ExternalLauncher.openDeeplink(product.deeplink),
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(imageUrl: product.imageUrl),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: blurb.isEmpty
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texts.body.copyWith(color: colors.ink900),
                  ),
                  if (blurb.isNotEmpty) _Blurb(blurb: blurb),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            Icon(Icons.open_in_new_rounded, size: 16, color: colors.ink300),
          ],
        ),
      ),
    );

    // §7.3-6: 균일색 Border.all + radius이므로 app_card.dart:54-66의
    // 비균일-보더 assert 위험이 없다(단일 색 전체 보더). `Container`(가
    // `DecoratedBox`와 달리 border 두께만큼 child에 암묵적 padding을 더해줌)를
    // 써야 보더가 내부의 불투명한 AppCard에 완전히 가려지지 않는다.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_topRanked)
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: colors.lineStrong),
            ),
            child: card,
          )
        else
          card,
        Positioned(
          top: 6,
          left: 6,
          child: _RankBadge(rank: rank, highlighted: _topRanked),
        ),
      ],
    );
  }
}

/// 좌상단 순위 배지. 1위만 `amberWash`/`amber`로 강조하고, 2위 이하는 썸네일
/// 사진 위에서도 읽히도록 불투명 `paperBg` + `line` 헤어라인을 쓴다.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.highlighted});

  final int rank;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      width: AppSpacing.x20,
      height: AppSpacing.x20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? colors.amberWash : colors.paperBg,
        shape: BoxShape.circle,
        border: highlighted ? null : Border.all(color: colors.line),
      ),
      // 두 자리 순위(10위 이상)·큰 textScaler에서도 배지를 넘치지 않게 축소.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$rank',
          style: texts.data.copyWith(
            color: highlighted ? colors.amber : colors.ink500,
          ),
        ),
      ),
    );
  }
}

/// 제목 아래 한 줄 설명(`products.blurb`). 어드민이 직접 쓴 값이며, 비어 있으면
/// 호출부에서 아예 렌더하지 않는다(§0011 — 가격 표시 대체).
class _Blurb extends StatelessWidget {
  const _Blurb({required this.blurb});

  final String blurb;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Text(
      blurb,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: texts.caption.copyWith(color: colors.ink500),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: AppRadius.brSm,
      ),
      child: Icon(Icons.shopping_bag_outlined, size: 28, color: colors.ink300),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(width: 72, height: 72, child: placeholder);
    }
    return SizedBox(
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: AppRadius.brSm,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : placeholder,
        ),
      ),
    );
  }
}
