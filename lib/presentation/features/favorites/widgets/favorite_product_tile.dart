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
///
/// DESIGN v2 §7.4-3 — [addedAt](즐겨찾기 추가일, `Favorite.createdAt` 조인)이
/// 주어지면 가격/별점 옆에 caption(ink300)으로 표시한다. 없으면 생략.
class FavoriteProductTile extends StatelessWidget {
  const FavoriteProductTile({
    required this.product,
    required this.collapsing,
    required this.onUnfavorite,
    super.key,
    this.addedAt,
  });

  final Product product;
  final bool collapsing;
  final VoidCallback onUnfavorite;

  /// 즐겨찾기에 추가된 시각. 없으면(§7.4-3) 캡션을 생략한다.
  final DateTime? addedAt;

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
                              _MetaRow(blurb: product.blurb, addedAt: addedAt),
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

/// 제목 아래 메타 줄 — 한 줄 설명(`products.blurb`) + 즐겨찾기 추가일.
///
/// 가격·평점은 노출하지 않는다(마이그레이션 0011 — 파트너스 API 승인 전까지
/// 어드민 수동 입력값이라 시세를 따라가지 못한다).
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.blurb, this.addedAt});

  /// `products.blurb`. 비어 있으면 설명을 생략하고 추가일만 오른쪽에 남긴다.
  final String? blurb;

  /// DESIGN v2 §7.4-3 — 즐겨찾기 추가일. 있으면 caption(ink300)으로 노출.
  final DateTime? addedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final added = addedAt;
    final text = blurb?.trim() ?? '';
    return Row(
      children: [
        if (text.isEmpty)
          const Spacer()
        else
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.caption.copyWith(color: colors.ink500),
            ),
          ),
        if (added != null) ...[
          const SizedBox(width: AppSpacing.x8),
          Text(
            '${added.month}월 ${added.day}일 추가',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texts.caption.copyWith(color: colors.ink300),
          ),
        ],
      ],
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
