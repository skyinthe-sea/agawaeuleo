import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// 케어 덱 아래 **증상 레일** — 동그란 종이 썸네일이 가로로 흐르는 인덱스.
///
/// 덱과 양방향으로 묶인다: 덱을 넘기면 레일이 따라 흘러 현재 증상을 가운데로
/// 데려오고(링·크기·라벨 색이 페이지 연속 값을 따라 보간), 썸네일을 누르면 덱이
/// 그 장으로 넘어간다. 한 장씩 넘기는 덱의 약점(원하는 증상까지 여러 번 넘겨야
/// 함)을 한 번의 탭으로 메운다. 사용자가 레일을 직접 굴리는 동안은 따라가기를 멈춘다.
class DeckRail extends StatefulWidget {
  const DeckRail({
    required this.symptoms,
    required this.controller,
    required this.settledIndex,
    required this.onSelect,
    super.key,
  });

  final List<Symptom> symptoms;

  /// 덱 페이지 컨트롤러(현재 위치의 단일 소스).
  final PageController controller;

  /// 덱이 멈춰 안착한 장 — 바뀌면 남은 간격을 부드럽게 마저 좁힌다.
  final int settledIndex;
  final ValueChanged<int> onSelect;

  static const double itemExtent = 72;
  static const double height = 92;

  @override
  State<DeckRail> createState() => _DeckRailState();
}

class _DeckRailState extends State<DeckRail> {
  final ScrollController _scroll = ScrollController();

  /// 사용자가 레일을 직접 굴리는 중(드래그·플링)인지.
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_follow);
  }

  @override
  void didUpdateWidget(DeckRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_follow);
      widget.controller.addListener(_follow);
    }
    if (oldWidget.settledIndex != widget.settledIndex) {
      // 빌드 중에 스크롤 위치를 바꾸지 않도록 프레임 뒤로 미룬다.
      WidgetsBinding.instance.addPostFrameCallback((_) => _settle());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_follow);
    _scroll.dispose();
    super.dispose();
  }

  double get _page {
    final c = widget.controller;
    if (c.hasClients && c.positions.length == 1 && c.position.haveDimensions) {
      return c.page ?? 0;
    }
    return 0;
  }

  /// 현재 장이 왼쪽에서 두 번째 자리에 오도록 — 바로 앞 증상 하나를 남겨 두어
  /// 레일이 "어디서 왔고 다음이 무엇인지"를 함께 보여 준다.
  static double _targetFor(double page, ScrollPosition position) =>
      ((page - 1) * DeckRail.itemExtent).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

  /// 덱이 움직이는 프레임마다 목표 위치로 **당겨 붙는다**(바로 점프하지 않고 간격의
  /// 40%씩 좁혀서, 레일을 따로 굴려 둔 뒤 덱을 넘겨도 순간이동하지 않는다).
  void _follow() {
    if (_userScrolling || !_scroll.hasClients) return;
    final position = _scroll.position;
    final target = _targetFor(_page, position);
    final current = position.pixels;
    final next = (target - current).abs() < 0.5
        ? target
        : current + (target - current) * 0.4;
    if (next != current) _scroll.jumpTo(next);
  }

  /// 덱이 멈췄을 때 남은 간격을 부드럽게 마저 좁힌다.
  void _settle() {
    if (!mounted || _userScrolling || !_scroll.hasClients) return;
    final position = _scroll.position;
    final target = _targetFor(_page.roundToDouble(), position);
    if ((position.pixels - target).abs() < 0.5) return;
    if (context.reduceMotion) {
      _scroll.jumpTo(target);
      return;
    }
    _scroll.animateTo(
      target,
      duration: AppMotion.resolve(context, AppMotion.base),
      curve: AppMotion.enter,
    );
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userScrolling = true;
    } else if (n is ScrollEndNotification && _userScrolling) {
      _userScrolling = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeckRail.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 마지막 증상도 왼쪽 두 번째 자리까지 올 수 있게 오른쪽 여백을 넉넉히 둔다.
          final trailing = math.max(
            AppSpacing.x16,
            constraints.maxWidth - DeckRail.itemExtent * 2 - AppSpacing.x16,
          );
          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: AppSpacing.x16, right: trailing),
              itemExtent: DeckRail.itemExtent,
              itemCount: widget.symptoms.length,
              itemBuilder: (context, i) => _RailItem(
                symptom: widget.symptoms[i],
                index: i,
                controller: widget.controller,
                onTap: () {
                  _userScrolling = false;
                  widget.onSelect(i);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.symptom,
    required this.index,
    required this.controller,
    required this.onTap,
  });

  final Symptom symptom;
  final int index;
  final PageController controller;
  final VoidCallback onTap;

  static const double _circle = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final Widget art;
    if (SymptomIllustrations.has(symptom.emojiOrIcon)) {
      art = SymptomIllustration(
        illustrationKey: symptom.emojiOrIcon!,
        size: 44,
      );
    } else {
      final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);
      art = Icon(
        SymptomIcons.resolve(symptom.emojiOrIcon),
        size: 22,
        color: tone.fg,
      );
    }
    // 썸네일 원 안의 그림은 페이지와 무관하므로 한 번만 만들어 둔다.
    final thumbnail = ClipOval(
      child: SizedBox.square(
        dimension: _circle,
        child: Center(child: art),
      ),
    );

    return Semantics(
      button: true,
      label: symptom.name,
      excludeSemantics: true,
      child: TapSpring(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller,
          child: thumbnail,
          builder: (context, child) {
            final hasPage =
                controller.hasClients &&
                controller.positions.length == 1 &&
                controller.position.haveDimensions;
            final page = hasPage ? controller.page ?? 0 : 0.0;
            final t = (1 - (page - index).abs()).clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.x8),
                Transform.scale(
                  scale: lerpDouble(0.84, 1, t),
                  child: Container(
                    width: _circle,
                    height: _circle,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        colors.paperCard,
                        colors.paperRaised,
                        t,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(colors.line, colors.ink900, t)!,
                        width: lerpDouble(1, 2, t)!,
                      ),
                      boxShadow: t > 0.5 ? context.shadows.e2 : null,
                    ),
                    child: child,
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                SizedBox(
                  width: DeckRail.itemExtent - AppSpacing.x4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      symptom.name,
                      maxLines: 1,
                      style: texts.caption.copyWith(
                        color: Color.lerp(colors.ink500, colors.ink900, t),
                        fontWeight: t > 0.5 ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
