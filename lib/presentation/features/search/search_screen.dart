import 'dart:async';

import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'search_providers.dart';
import 'widgets/recent_searches_view.dart';
import 'widgets/search_field_bar.dart';
import 'widgets/search_result_tile.dart';

/// §11.8 검색 화면. 상단 검색 입력(자동 포커스, Hero `home-search-bar` morph,
/// 좌 뒤로가기 · 우 X 클리어+재포커스), 200ms 디바운스 → 실시간 결과 리스트.
/// 입력이 비었을 땐 최근 검색어를 노출한다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  /// §11.8 타이핑 디바운스.
  static const Duration _debounceDelay = Duration(milliseconds: 200);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;

  /// 디바운스가 확정한 질의(리포지토리 검색 키). raw 입력과 분리해 결과의 깜빡임을 막는다.
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 타이핑 → 클리어 버튼/본문 전환 즉시 반영 + 200ms 뒤 검색 확정.
  void _onChanged(String value) {
    setState(() {}); // X 버튼 노출 · 최근/결과 전환을 즉시 반영.
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  /// 엔터 → 디바운스 건너뛰고 즉시 확정 + 최근 검색어 저장.
  void _onSubmitted(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    _record(trimmed);
  }

  /// X → 입력 클리어 + 재포커스(§11.8).
  void _onClear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  /// 최근 검색어 탭 → 해당 질의로 재검색(디바운스 없이 즉시).
  void _onSelectRecent(String query) {
    _debounce?.cancel();
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    setState(() => _query = query.trim());
    _focusNode.requestFocus();
  }

  /// 결과 탭 → 최근 검색어 저장 + 증상 상세로 이동.
  void _onOpenSymptom(Symptom symptom) {
    _record(_query);
    context.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: symptom.slug},
    );
  }

  void _record(String query) {
    if (query.isEmpty) return;
    ref.read(recentSearchRepositoryProvider).record(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              onClear: _onClear,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: hasText
                  ? _Results(query: _query, onOpen: _onOpenSymptom)
                  : RecentSearchesView(onSelect: _onSelectRecent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 좌측 뒤로가기(40 탭타깃, arrow_back 24 ink.900) + Hero 검색 입력 필드.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // DESIGN v2 §7.2-1 — TopBar 하단 상시 헤어라인(AppAppBar와 같은 표면 경계 문법).
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x8,
          AppSpacing.x8,
          AppSpacing.screenPadding,
          AppSpacing.x8,
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(Icons.arrow_back, size: 24, color: colors.ink900),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x4),
            Expanded(
              child: SearchFieldBar(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                onClear: onClear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 디바운스된 질의에 대한 결과 리스트. 항목 fadeIn 120ms, 빈 결과 → EmptyState(1회 흔들림).
class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onOpen});

  /// 결과 항목 등장 fadeIn(§11.8 — 빠르게 120ms).
  static const Duration _itemFadeIn = Duration(milliseconds: 120);

  final String query;
  final ValueChanged<Symptom> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 디바운스 확정 전(query 비었지만 입력은 있음)에는 EmptyState 깜빡임을 피해 비워 둔다.
    if (query.isEmpty) return const SizedBox.shrink();

    final async = ref.watch(searchResultsProvider(query));
    final reduce = context.reduceMotion;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => ErrorState(
        onRetry: () => ref.invalidate(searchResultsProvider(query)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return EmptyState(
            key: ValueKey('empty-$query'),
            icon: Icons.search_off_rounded,
            title: '검색 결과가 없어요',
            message: '다른 이름이나 초성으로 검색해 보세요',
          );
        }
        // DESIGN v2 §7.2-2 — 카드화하지 않고 행 사이 inset 헤어라인(좌 72dp)으로
        // 리듬만 부여한다.
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
          itemCount: results.length,
          separatorBuilder: (context, _) => Divider(
            height: 1,
            thickness: 1,
            indent: SearchResultTile.dividerIndent,
            color: context.colors.line,
          ),
          itemBuilder: (context, index) {
            final symptom = results[index];
            final tile = SearchResultTile(
              symptom: symptom,
              query: query,
              onTap: () => onOpen(symptom),
            );
            if (reduce) return tile;
            return tile
                .animate(key: ValueKey('$query-${symptom.id}'))
                .fadeIn(duration: _itemFadeIn, curve: AppMotion.enter);
          },
        );
      },
    );
  }
}
