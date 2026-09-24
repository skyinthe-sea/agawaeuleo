import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/utils/hangul_typing.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 검색 바. 높이 52 · r.full · 배경 `paperRaised` · `line` 1.5 · e1.
///
/// DESIGN v3 §5.2 — 말랑한 알약 입력. 왼쪽 돋보기는 딸기 워시 동그라미(클레이 버블)
/// 안에 앉고, 타이핑 커서는 딸기(accent) 알약.
///
/// 2026-09-11 홈 개편 — 비어 있던 알약에 **타이핑 힌트**를 넣었다. [hints]의 증상
/// 이름을 한글 IME 조합 순서(ㅂ → 배 → 뱅 → 배아 …)로 쳤다가 지우기를 한 바퀴
/// 돌고, 마지막엔 정적인 안내 문구로 쉰다(상시 반복 금지 — 한 바퀴만). 온보딩 첫
/// 장의 검색 알약과 같은 문법이라 "여기에 검색하면 된다"가 바로 읽힌다.
/// reduce-motion이면 처음부터 정적 문구.
///
/// 탭 시 검색 화면으로 Hero 전환한다(태그 계약: `'home-search-bar'` — 검색 화면과 공유).
class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({required this.onTap, super.key, this.hints = const []});

  /// 검색 바 Hero 태그(검색 화면과 정확히 동일해야 morph 된다).
  static const String heroTag = 'home-search-bar';

  static const double height = 52;

  /// 타이핑이 끝난 뒤 머무는 안내 문구.
  static const String restingHint = '궁금한 증상을 검색해 보세요';

  final VoidCallback onTap;

  /// 차례로 타이핑해 보여 줄 예시 검색어(보통 증상 이름 앞쪽 몇 개).
  final List<String> hints;

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

/// 타이핑 연출 한 프레임 — 이 시각부터 [text]를 보여 준다.
typedef _Frame = ({Duration at, String text, bool caret});

class _HomeSearchBarState extends State<HomeSearchBar>
    with TickerProviderStateMixin {
  static const Duration _startDelay = Duration(milliseconds: 900);
  static const Duration _keyStroke = Duration(milliseconds: 105);
  static const Duration _hold = Duration(milliseconds: 1500);
  static const Duration _eraseStroke = Duration(milliseconds: 55);
  static const Duration _gap = Duration(milliseconds: 320);

  // reduce-motion에서도 dispose가 안전하도록 즉시 생성(지연 초기화 금지).
  late final AnimationController _script = AnimationController(vsync: this);
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  List<_Frame> _frames = const [];

  @override
  void initState() {
    super.initState();
    _script.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 증상 목록이 늦게 도착(스트림 첫 방출)하면 그때 한 바퀴를 시작한다.
    if (oldWidget.hints.isEmpty && widget.hints.isNotEmpty) _start();
  }

  void _start() {
    if (!mounted || widget.hints.isEmpty || _script.isAnimating) return;
    if (context.reduceMotion || _frames.isNotEmpty) return;
    _frames = _buildFrames(widget.hints);
    _script
      ..duration = _frames.last.at
      ..forward(from: 0).whenCompleteOrCancel(() {
        if (mounted) _blink.stop();
      });
    _blink.repeat();
  }

  static List<_Frame> _buildFrames(List<String> hints) {
    final frames = <_Frame>[];
    var t = _startDelay;
    frames.add((at: Duration.zero, text: '', caret: true));
    for (final hint in hints) {
      for (final step in hangulTypingSteps(hint)) {
        frames.add((at: t, text: step, caret: true));
        t += _keyStroke;
      }
      t += _hold;
      for (final step in hangulErasingSteps(hint)) {
        frames.add((at: t, text: step, caret: true));
        t += _eraseStroke;
      }
      t += _gap;
    }
    frames.add((at: t, text: '', caret: false));
    return frames;
  }

  _Frame? _frameAt(double value) {
    if (_frames.isEmpty || value >= 1) return null;
    final now = _frames.last.at * value;
    _Frame? current;
    for (final frame in _frames) {
      if (frame.at > now) break;
      current = frame;
    }
    return current;
  }

  @override
  void dispose() {
    _script.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final hint = AnimatedBuilder(
      animation: _script,
      builder: (context, _) {
        final frame = _frameAt(_script.value);
        if (frame == null) {
          return Text(
            HomeSearchBar.restingHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texts.bodyL.copyWith(color: colors.ink300, height: 1),
          );
        }
        return Row(
          children: [
            Flexible(
              child: Text(
                frame.text,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: texts.bodyL.copyWith(color: colors.ink700, height: 1),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            if (frame.caret)
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _blink,
                  curve: const Threshold(0.5),
                ),
                child: Container(
                  width: 2,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
          ],
        );
      },
    );

    return Semantics(
      button: true,
      label: '증상 검색',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: Hero(
        tag: HomeSearchBar.heroTag,
        // 비행 중 텍스트가 밑줄/기본 스타일로 깨지지 않도록 Material로 감싼다.
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.paperRaised,
              borderRadius: AppRadius.brFull,
              boxShadow: context.shadows.e1,
              border: Border.all(color: colors.line, width: 1.5),
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
                onTap: widget.onTap,
                child: SizedBox(
                  height: HomeSearchBar.height,
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.x8),
                      const SearchPillBubble(),
                      const SizedBox(width: AppSpacing.x12),
                      Expanded(child: hint),
                      const SizedBox(width: AppSpacing.x16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 검색 알약 왼쪽의 돋보기 버블 — 딸기 워시 동그라미 + 은은한 클레이 광택.
///
/// 홈 검색 바와 검색 화면 입력이 같은 버블을 써야 Hero morph가 이음새 없이 이어진다.
class SearchPillBubble extends StatelessWidget {
  const SearchPillBubble({super.key});

  static const double size = 34;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: ClaySheen.gradient(context, colors.accentWash),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.search_rounded, size: 19, color: colors.accent),
    );
  }
}
