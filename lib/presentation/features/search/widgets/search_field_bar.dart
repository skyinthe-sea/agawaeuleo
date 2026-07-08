import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/material.dart';

/// §11.8 상단 검색 입력. 홈 검색바(§11.7 — 높이 52 · r.full · paper.card · e1 ·
/// 좌측 돋보기 20 ink.500)에서 Hero `home-search-bar`로 morph 되는 알약형 필드.
///
/// 자동 포커스, 우측 X(클리어)를 포함한다. 좌측 뒤로가기는 화면(부모)이 배치한다.
class SearchFieldBar extends StatelessWidget {
  const SearchFieldBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  /// 홈 검색바와 동일한 placeholder(§11.7).
  static const String _hint = '배앓이, ㅂㅇㅇ …';
  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Hero(
      tag: 'home-search-bar',
      flightShuttleBuilder: _flightShuttle,
      child: _Pill(
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colors.ink500),
            const SizedBox(width: AppSpacing.iconTextGap),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                cursorColor: colors.accent,
                style: context.texts.bodyL.copyWith(color: colors.ink900),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: _hint,
                  hintStyle: context.texts.bodyL.copyWith(color: colors.ink300),
                ),
              ),
            ),
            _ClearButton(visible: controller.text.isNotEmpty, onTap: onClear),
          ],
        ),
      ),
    );
  }

  /// Hero 비행 중에는 라이브 TextField 대신 동일 형태의 정적 알약을 렌더한다
  /// (오버레이에는 Scaffold의 Material/focus 트리가 없어 TextField 재생성이 위험).
  Widget _flightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final colors = flightContext.colors;
    final text = controller.text;
    return Material(
      type: MaterialType.transparency,
      child: _Pill(
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colors.ink500),
            const SizedBox(width: AppSpacing.iconTextGap),
            Expanded(
              child: Text(
                text.isEmpty ? _hint : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: flightContext.texts.bodyL.copyWith(
                  color: text.isEmpty ? colors.ink300 : colors.ink900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// §11.7 검색바 셸 — 높이 52 · r.full · paper.card · e1 · 헤어라인 line.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: SearchFieldBar._height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brFull,
        boxShadow: context.shadows.e1,
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

/// 우측 X — 클리어 + 재포커스(§11.8). 입력이 있을 때만 페이드 인.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.resolve(context, AppMotion.fast),
      curve: AppMotion.standard,
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.x8),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: context.colors.ink500,
            ),
          ),
        ),
      ),
    );
  }
}
