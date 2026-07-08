import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme/theme.dart';
import '../../../../domain/entities/product.dart';
import '../../../widgets/animated/sparkle.dart';
import '../../../widgets/cards/app_card.dart';

/// §11.15 즐겨찾기 "제품" 리스트 항목 — 증상 상세(§11.9-6)와 동일한 카드
/// (썸네일 72×72 · 제목 2줄 · 가격/별점 · 외부링크 아이콘)에 좌측 상단 별
/// 오버레이를 더해 해제(unfavorite)를 지원한다.
///
/// [collapsing]이 true면 높이·불투명도가 축소되며 실제 목록 제거는 호출부
/// (지연 후 저장소 반영)가 담당한다 — §11.15 "collapse+fadeOut".
class FavoriteProductTile extends StatelessWidget {
  const FavoriteProductTile({
    required this.product,
    required this.collapsing,
    required this.onUnfavorite,
    super.key,
  });

  final Product product;
  final bool collapsing;
  final VoidCallback onUnfavorite;

  Future<void> _openDeeplink() async {
    final uri = Uri.tryParse(product.deeplink);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // 외부 앱 오픈 실패는 조용히 무시(§11.9와 동일한 방어적 정책).
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.base);

    return ClipRect(
      child: AnimatedAlign(
        duration: duration,
        curve: AppMotion.exit,
        alignment: Alignment.topCenter,
        heightFactor: collapsing ? 0 : 1,
        child: AnimatedOpacity(
          opacity: collapsing ? 0 : 1,
          duration: duration,
          curve: AppMotion.exit,
          child: IgnorePointer(
            ignoring: collapsing,
            child: Stack(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  onTap: _openDeeplink,
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
                                style: texts.body.copyWith(
                                  color: colors.ink900,
                                ),
                              ),
                              _PriceRow(
                                price: product.price,
                                rating: product.rating,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x8),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: colors.ink300,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Sparkle(
                    isActive: true,
                    size: 16,
                    onChanged: (next) {
                      if (!next) onUnfavorite();
                    },
                  ),
                ),
              ],
            ),
          ),
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
