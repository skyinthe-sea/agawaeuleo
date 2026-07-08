import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 고정 검색 바. 높이 52 · r.full · 배경 `paper.card` · e1 ·
/// 좌측 돋보기 20 `ink.500` · placeholder `ink.300`.
///
/// 탭 시 검색 화면으로 Hero 전환한다(태그 계약: `'home-search-bar'` — 검색 화면과 공유).
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({required this.onTap, super.key});

  /// 검색 바 Hero 태그(검색 화면과 정확히 동일해야 morph 된다).
  static const String heroTag = 'home-search-bar';

  static const double height = 52;
  static const String _hint = '배앓이, ㅂㅇㅇ …';

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Hero(
      tag: heroTag,
      // 비행 중 텍스트가 밑줄/기본 스타일로 깨지지 않도록 Material로 감싼다.
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paperCard,
            borderRadius: AppRadius.brFull,
            boxShadow: context.shadows.e1,
            border: Border.all(color: colors.line),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: AppRadius.brFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashFactory: InkWashSplash.splashFactory,
              splashColor: colors.accentWash,
              highlightColor: Colors.transparent,
              borderRadius: AppRadius.brFull,
              onTap: onTap,
              child: SizedBox(
                height: height,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.x16),
                    Icon(Icons.search_rounded, size: 20, color: colors.ink500),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      child: Text(
                        _hint,
                        style: context.texts.bodyL.copyWith(
                          color: colors.ink300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
