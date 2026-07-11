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
    // 단일행 알약(52px) 세로 중앙 정렬 — 원인: 테마 InputDecorationTheme.constraints
    // (minHeight 52)가 데코레이터 박스만 52로 늘리는데, InputDecorator는 내부
    // 콘텐츠를 고유 높이(containerHeight)로만 배치하고 잉여 공간을 전부 아래에
    // 붙인다(min-height는 레이아웃 계산에 미반영). 그래서 textAlignVertical·
    // isDense·SizedBox 어떤 조합으로도 중앙에 오지 않는다.
    // 해결: constraints를 로컬에서 비워 테마 min-height를 무력화하고, isCollapsed로
    // 데코레이터를 텍스트 고유 높이로 줄인 뒤 Align이 기하학적으로 중앙 배치.
    // 줄간격 1.0은 라인박스=폰트크기로 만들어 광학 중앙을 보장.
    final fieldStyle = context.texts.bodyL.copyWith(
      color: colors.ink900,
      height: 1,
    );
    final hintFieldStyle = context.texts.bodyL.copyWith(
      color: colors.ink300,
      height: 1,
    );
    return Hero(
      tag: 'home-search-bar',
      flightShuttleBuilder: _flightShuttle,
      child: _Pill(
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colors.ink500),
            const SizedBox(width: AppSpacing.iconTextGap),
            Expanded(
              // 알약 전체(빈 여백 포함)를 탭 히트영역으로 유지 — 데코레이터가
              // 텍스트 높이로 줄었으므로 GestureDetector가 포커스를 복원한다.
              // (텍스트 위 탭은 제스처 아레나에서 TextField가 우선.)
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: focusNode.requestFocus,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    cursorColor: colors.accent,
                    style: fieldStyle,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      constraints: const BoxConstraints(),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: _hint,
                      hintStyle: hintFieldStyle,
                    ),
                  ),
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
                  height: 1,
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
