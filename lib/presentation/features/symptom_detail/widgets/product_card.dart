import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/external_launcher.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';

/// §11.9-6 추천 제품 카드.
///
/// 높이 ~96, radius `r.md`, e1. 좌측 썸네일 72×72 `r.sm`, 우측 제목 body 2줄
/// (말줄임) + 가격 data 16 `ink.900` + (있으면) 별점 caption. 우측 끝 외부링크
/// 아이콘 16 `ink.300`. 탭 → 딥링크 외부 오픈 + 스프링/눌림 그림자 + 라이트 햅틱
/// (AppCard가 처리).
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x12),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texts.body.copyWith(color: colors.ink900),
                  ),
                  _PriceRow(price: product.price, rating: product.rating),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x8),
            Icon(Icons.open_in_new_rounded, size: 16, color: colors.ink300),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price, required this.rating});

  final int? price;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (price != null)
          Text(
            _formatPrice(price!),
            style: texts.data.copyWith(color: colors.ink900),
          ),
        if (rating != null) ...[
          const SizedBox(width: AppSpacing.x8),
          Icon(Icons.star_rounded, size: 13, color: colors.amber),
          const SizedBox(width: AppSpacing.x2),
          Text(
            rating!.toStringAsFixed(1),
            style: texts.caption.copyWith(color: colors.ink500),
          ),
        ],
      ],
    );
  }

  /// 천 단위 구분 + '원' 접미. 예: 12900 → '12,900원'.
  static String _formatPrice(int won) {
    final digits = won.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$buffer원';
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
