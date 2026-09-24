import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../widgets/surfaces/clay_sheen.dart';

/// §11.16 알림 토글 스위치. 트랙 색 트윈 + thumb 이동(§10.2).
///
/// DESIGN v3 §6 "말랑한 스위치" — 꺼짐 트랙은 회색(`ink300`) 대신 크림빛
/// `paperStack`(+헤어라인)으로, 켜짐 트랙은 accentFill 클레이 광택(§5.0)으로 채운다.
/// thumb는 그대로 `paperRaised` + e1(크림 알).
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
    final bool on = enabled && value;
    final Color trackBase = !enabled
        ? colors.line
        : (value ? colors.accentFill : colors.paperStack);
    final Gradient? trackFill = on
        ? ClaySheen.gradient(context, trackBase)
        : null;

    return IgnorePointer(
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.standard,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: trackFill == null ? trackBase : null,
          gradient: trackFill,
          borderRadius: AppRadius.brFull,
          border: on ? null : Border.all(color: colors.lineStrong),
        ),
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
