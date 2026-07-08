import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.16 알림 토글 스위치. 트랙 색 트윈 + thumb 이동(§10.2).
///
/// 순수 표시용(터치 처리 없음) — 탭/햅틱(`selectionClick`)·상태 변경은 호출부의
/// [SettingsTile.onTap]이 담당한다(행 전체가 탭 영역이 되도록). 독립적으로 탭
/// 가능한 스위치가 필요하면 이 위젯을 `GestureDetector`로 감싸 쓴다.
class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, super.key, this.enabled = true});

  final bool value;
  final bool enabled;

  static const double _width = 46;
  static const double _height = 28;
  static const double _padding = 3;
  static const double _thumbSize = _height - _padding * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    final Color track = !enabled
        ? colors.line
        : (value ? colors.accent : colors.ink300);

    return IgnorePointer(
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.standard,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(color: track, borderRadius: AppRadius.brFull),
        child: AnimatedAlign(
          duration: duration,
          curve: AppMotion.standard,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumbSize,
            height: _thumbSize,
            decoration: BoxDecoration(
              color: colors.paperRaised,
              shape: BoxShape.circle,
              boxShadow: context.shadows.e1,
            ),
          ),
        ),
      ),
    );
  }
}
