import 'dart:async';
import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_header.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9 증상 상세 **케어 노트**(2026-09-11 전면 개편 — 긴 한 장 스크롤 폐기).
///
/// 한 증상의 정보를 장(요약 → 병원 신호 → 돌보는 법 → 추천 용품)으로 나눠 **종이를
/// 한 장씩 겹쳐 올리듯** 넘겨 본다. 홈 덱(옆으로 늘어선 증상을 넘기는 무대)과
/// 메커니즘을 일부러 다르게 했다:
/// - 다음 장은 오른쪽에서 **위로 겹쳐** 들어오고, 덮이는 장은 제자리에서 살짝
///   물러나며(축소·그늘) 아래로 가라앉는다. 되돌아가면 거꾸로 걷힌다.
/// - 머리([NoteHeader])는 장 위에 떠 있고, 현재 장을 스크롤하면 히어로 줄이 접힌다.
///   장 탭의 젤리 알약·무대 블롭 색·일러스트 기울기가 전부 페이지 연속 값을 따른다.
/// - 옆 장은 미리 빌드하되, 장 안의 등장 모션은 그 장이 화면에 들어오는 순간
///   재생한다([RevealGate]).
class CareNote extends ConsumerStatefulWidget {
  const CareNote({required this.symptom, super.key, this.initialChapter});

  final Symptom symptom;

  /// 처음 펼칠 장(`NoteChapter.slug`). 없거나 그 장이 없으면 요약.
  final String? initialChapter;

  @override
  ConsumerState<CareNote> createState() => _CareNoteState();
}

class _CareNoteState extends ConsumerState<CareNote>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  final Map<NoteChapter, ScrollController> _scrolls = {
    for (final c in NoteChapter.values)
      c: ScrollController(keepScrollOffset: false),
  };
  final Map<NoteChapter, ValueNotifier<bool>> _gates = {
    for (final c in NoteChapter.values) c: ValueNotifier<bool>(false),
  };

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  List<NoteChapter> _chapters = const [NoteChapter.overview];
  late final Listenable _headerListenable = Listenable.merge([
    _pages,
    ..._scrolls.values,
  ]);

  /// 딥링크 장으로 넘어가기 전까지 노트를 가려 첫 장이 한 번 비치는 깜빡임을 없앤다.
  late bool _hidden =
      NoteChapter.fromSlug(widget.initialChapter) != null &&
      NoteChapter.fromSlug(widget.initialChapter) != NoteChapter.overview;

  /// 딥링크 이동을 이미 예약했는지.
  bool _initialScheduled = false;

  /// 데이터가 끝내 오지 않아도(원격 지연) 빈 화면으로 남지 않게 하는 안전망.
  Timer? _revealFallback;

  @override
  void initState() {
    super.initState();
    _gates[NoteChapter.overview]!.value = true;
    _pages.addListener(_openGates);
    if (_hidden) {
      _revealFallback = Timer(const Duration(milliseconds: 1200), () {
        if (mounted && _hidden) setState(() => _hidden = false);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _ambient
        ..stop()
        ..value = 0;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _revealFallback?.cancel();
    _pages
      ..removeListener(_openGates)
      ..dispose();
    for (final c in _scrolls.values) {
      c.dispose();
    }
    for (final g in _gates.values) {
      g.dispose();
    }
    _ambient.dispose();
    super.dispose();
  }

  double get _page {
    if (_pages.hasClients &&
        _pages.positions.length == 1 &&
        _pages.position.haveDimensions) {
      return _pages.page ?? 0;
    }
    return 0;
  }

  /// 화면에 조금이라도 들어온 장의 관문을 연다(한 번 열리면 닫지 않는다).
  void _openGates() {
    final page = _page;
    for (final (i, chapter) in _chapters.indexed) {
      if ((page - i).abs() < 0.999) _gates[chapter]!.value = true;
    }
  }

  double _collapseOf(NoteChapter chapter) {
    final c = _scrolls[chapter]!;
    if (!c.hasClients || c.positions.length != 1) return 0;
    return c.offset.clamp(0.0, NoteHeader.collapseRange);
  }

  /// 두 장 사이의 머리 접힘 — 페이지 값으로 보간.
  double _collapse() {
    final n = _chapters.length;
    final page = _page.clamp(0.0, (n - 1).toDouble());
    final i0 = page.floor();
    final i1 = math.min(i0 + 1, n - 1);
    final a = _collapseOf(_chapters[i0]);
    final b = _collapseOf(_chapters[i1]);
    return a + (b - a) * (page - i0);
  }

  /// 넘기기 직전, 다른 장들의 접힘을 현재 장에 맞춘다 — 넘기는 동안 머리가
  /// 펼쳐졌다 접혔다 널뛰지 않게(깊이 읽던 장은 둘 다 완전히 접혀 있으면 유지).
  void _syncCollapse() {
    if (_chapters.isEmpty) return;
    final current = _chapters[_page.round().clamp(0, _chapters.length - 1)];
    final target = _collapseOf(current);
    for (final chapter in _chapters) {
      if (chapter == current) continue;
      final c = _scrolls[chapter]!;
      if (!c.hasClients ||
          c.positions.length != 1 ||
          !c.position.hasContentDimensions) {
        continue;
      }
      final offset = c.offset;
      final fullyCollapsed =
          offset >= NoteHeader.collapseRange &&
          target >= NoteHeader.collapseRange;
      if (fullyCollapsed) continue;
      final next = math.min(target, c.position.maxScrollExtent);
      if ((offset - next).abs() > 0.5) c.jumpTo(next);
    }
  }

  bool _onPagerScroll(ScrollNotification n) {
    if (n.depth == 0 && n is ScrollStartNotification) _syncCollapse();
    return false;
  }

  void _goTo(int index) {
    if (!_pages.hasClients) return;
    final current = _page.round();
    if (index == current) return;
    unawaited(AppHaptics.toggle());
    _syncCollapse();
    if (context.reduceMotion) {
      _pages.jumpToPage(index);
    } else {
      unawaited(
        _pages.animateToPage(
          index,
          duration: AppMotion.slow,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  void _goToChapter(NoteChapter chapter) {
    final index = _chapters.indexOf(chapter);
    if (index >= 0) _goTo(index);
  }

  /// 데이터가 다 모이면(장 구성이 확정되면) 딥링크 장으로 한 번 넘긴다.
  void _applyInitialChapter({required bool ready}) {
    if (!_hidden || _initialScheduled || !ready) return;
    _initialScheduled = true;
    final target = NoteChapter.fromSlug(widget.initialChapter);
    final index = target == null ? -1 : _chapters.indexOf(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (index > 0 && _pages.hasClients) {
        _pages.jumpToPage(index);
        _gates[_chapters[index]]!.value = true;
      }
      _revealFallback?.cancel();
      setState(() => _hidden = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final symptom = widget.symptom;
    final infoAsync = ref.watch(symptomInfoProvider(symptom.id));
    final productsAsync = ref.watch(symptomProductsProvider(symptom.id));
    final info = infoAsync.value;
    final products = productsAsync.value ?? const <Product>[];

    final chapters = <NoteChapter>[
      NoteChapter.overview,
      if (info != null && info.hasEmergency) NoteChapter.emergency,
      if (info != null && (info.sections.isNotEmpty || info.sources.isNotEmpty))
        NoteChapter.guide,
      // 로딩 중에도 자리를 잡아 둔다(비었다고 확인되면 빠진다) — 탭이 늦게 튀어나오지 않게.
      if (!productsAsync.hasValue || products.isNotEmpty) NoteChapter.products,
    ];
    _chapters = chapters;
    final ready =
        (infoAsync.hasValue || infoAsync.hasError) &&
        (productsAsync.hasValue || productsAsync.hasError);
    _applyInitialChapter(ready: ready);

    final note = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onPagerScroll,
                child: PageView.builder(
                  controller: _pages,
                  // 옆 장을 미리 빌드 — 넘기는 첫 프레임에 빌드 지연이 없다.
                  allowImplicitScrolling: true,
                  itemCount: chapters.length,
                  onPageChanged: (_) => unawaited(AppHaptics.toggle()),
                  itemBuilder: (context, i) => _NoteSheet(
                    key: ValueKey(chapters[i]),
                    index: i,
                    pages: _pages,
                    width: width,
                    child: RevealGate(
                      open: _gates[chapters[i]]!,
                      child: _chapterScroll(
                        chapter: chapters[i],
                        index: i,
                        chapters: chapters,
                        info: infoAsync,
                        products: products,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _headerListenable,
                builder: (context, _) => NoteHeader(
                  symptom: symptom,
                  chapters: chapters,
                  page: _page,
                  collapse: _collapse(),
                  ambient: _ambient,
                  productCount: products.length,
                  onSelect: _goTo,
                ),
              ),
            ),
          ],
        );
      },
    );

    // 구조를 바꾸지 않고 불투명도만 토글한다(페이지뷰 상태 유지).
    return IgnorePointer(
      ignoring: _hidden,
      child: Opacity(opacity: _hidden ? 0 : 1, child: note),
    );
  }

  Widget _chapterScroll({
    required NoteChapter chapter,
    required int index,
    required List<NoteChapter> chapters,
    required AsyncValue<SymptomInfo?> info,
    required List<Product> products,
  }) {
    final symptom = widget.symptom;
    final data = info.value;
    final next = index + 1 < chapters.length ? chapters[index + 1] : null;

    final Widget body = switch (chapter) {
      NoteChapter.overview => NoteOverviewChapter(
        symptom: symptom,
        info: info,
        chapters: chapters,
        productCount: products.length,
        topProductTitle: products.isEmpty ? null : products.first.title,
        onJump: _goToChapter,
      ),
      NoteChapter.emergency => NoteEmergencyChapter(
        signs: data?.emergency ?? const [],
        visible: _gates[chapter]!,
      ),
      NoteChapter.guide =>
        data == null ? const SizedBox.shrink() : NoteGuideChapter(info: data),
      NoteChapter.products => NoteProductsChapter(symptomId: symptom.id),
    };

    return CustomScrollView(
      controller: _scrolls[chapter],
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(height: NoteHeader.maxExtent + AppSpacing.x8),
        ),
        // 장 콘텐츠는 한 덩어리로 빌드한다 — 면책 문구(§13.3)가 스크롤 위치와
        // 무관하게 늘 트리에 있고, 장이 짧아 지연 빌드의 이득도 없다.
        //
        // DESIGN v3 §6 — 장마다 윗변이 둥근(xl) 크림 시트가 머리 아래에서 솟아
        // 오른다. 넘기면 다음 시트가 그 위로 겹쳐 올라온다(_NoteSheet).
        SliverToBoxAdapter(
          child: _ChapterSurface(
            top: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.x24,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  body,
                  // 요약은 목차가 다음 장 안내를 대신한다.
                  if (next != null && chapter != NoteChapter.overview) ...[
                    const SizedBox(height: AppSpacing.x32),
                    NoteNextCard(
                      number: index + 2,
                      chapter: next,
                      onTap: () => _goTo(index + 1),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x24),
                  NoteDisclaimer(audience: symptom.audience),
                  const SizedBox(height: AppSpacing.x40),
                ],
              ),
            ),
          ),
        ),
        // 장이 화면보다 짧아도 시트가 바닥까지 이어진다(당겨도 바탕이 비치지 않게).
        const SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: true,
          child: _ChapterSurface(child: SizedBox.expand()),
        ),
      ],
    );
  }
}

/// 장 시트의 면 — `paperCard` 크림. [top]이면 윗변을 xl로 둥글리고 위쪽으로
/// 은은한 장밋빛 그림자를 드리워 머리 아래에서 떠오른 한 장처럼 보이게 한다.
class _ChapterSurface extends StatelessWidget {
  const _ChapterSurface({required this.child, this.top = false});

  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!top) return ColoredBox(color: colors.paperCard, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        // e2를 위로 뒤집은 그림자(토큰 파생) — 시트 윗변만 부드럽게 뜬다.
        boxShadow: [
          for (final s in context.shadows.e2)
            BoxShadow(
              color: s.color,
              blurRadius: s.blurRadius,
              offset: Offset(0, -s.offset.dy / 2),
            ),
        ],
      ),
      child: child,
    );
  }
}

/// 장 한 장 — 페이지 값에 따라 **겹쳐 올라오고 / 물러나 가라앉는** 종이.
///
/// 페이지뷰는 뒤 인덱스를 위에 그리므로, 들어오는 장은 손가락과 1:1로 덮으며
/// 들어오고(앞 가장자리에 그림자), 덮이는 장은 이동을 대부분 상쇄해 제자리 근처에서
/// 축소·그늘로 가라앉는다.
class _NoteSheet extends StatelessWidget {
  const _NoteSheet({
    required this.index,
    required this.pages,
    required this.width,
    required this.child,
    super.key,
  });

  final int index;
  final PageController pages;
  final double width;
  final Widget child;

  /// 덮이는 장이 남은 이동의 몇 %만큼 따라가는지(0 = 완전히 제자리).
  static const double _recedeFollow = 0.22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shade = context.shadows.e3.first.color;
    // 다크는 그림자 토큰 알파가 높아(0.65) 그대로 쓰면 장이 먹칠된다.
    final shadeStrength = context.isDark ? 0.4 : 1.2;

    final sheet = RepaintBoundary(
      child: ColoredBox(
        color: colors.paperBg,
        child: PaperBackground(child: child),
      ),
    );

    return AnimatedBuilder(
      animation: pages,
      child: sheet,
      builder: (context, sheet) {
        final hasPage =
            pages.hasClients &&
            pages.positions.length == 1 &&
            pages.position.haveDimensions;
        final p = (hasPage ? pages.page ?? 0 : 0) - index;
        // 덮이는 중(p > 0) — 제자리 근처에서 물러난다.
        final covered = p > 0 ? p.clamp(0.0, 1.0) : 0.0;
        // 들어오는 중(p < 0) — 앞 가장자리 그림자가 아래 장에 드리운다.
        final incoming = p < 0
            ? math.sin(p.abs().clamp(0.0, 1.0) * math.pi)
            : 0.0;

        // 트리 구조는 늘 같게 유지한다 — 분기마다 모양이 바뀌면 장의 스크롤 위치와
        // 등장 모션 상태가 초기화된다.
        return Transform.translate(
          offset: Offset(covered * width * (1 - _recedeFollow), 0),
          child: Transform.scale(
            scale: 1 - 0.05 * covered,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: shade.withValues(
                      alpha: (shade.a * shadeStrength * incoming).clamp(
                        0.0,
                        1.0,
                      ),
                    ),
                    blurRadius: 36,
                    offset: const Offset(-6, 0),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  sheet!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: shade.withValues(
                          alpha: (shade.a * shadeStrength * covered).clamp(
                            0.0,
                            1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
