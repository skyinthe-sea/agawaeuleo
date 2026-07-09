import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/notifications/notifications.dart';

/// §11.16 "권한 꺼져있으면 안내+설정 이동" · §11.6(개정) "설정 → 알림 진입도 프라이밍
/// 노출 지점".
///
/// 이 위젯은 **OS 권한이 켜져 있지 않을 때만** 노출된다(노출 판단은 호출부에서
/// [notificationPermissionStatusProvider]로 배선). 상태에 따라 행동이 달라진다.
///   - [NotificationPermissionStatus.notDetermined]: 아직 요청 전 → "알림 켜기"로
///     권한 프라이밍 화면([onOpenPriming])을 띄워 이유를 먼저 설명하고 요청한다.
///   - [NotificationPermissionStatus.denied]: 이미 꺼짐 → OS는 재요청을 띄우지
///     않으므로 기기 설정 앱으로 이동("설정 열기")을 안내한다.
class NotificationPermissionHint extends StatelessWidget {
  const NotificationPermissionHint({
    required this.status,
    required this.onOpenPriming,
    super.key,
  });

  /// 현재 OS 알림 권한 상태(호출부에서 granted가 아닐 때만 이 위젯을 노출한다).
  final NotificationPermissionStatus status;

  /// "알림 켜기" 탭 시 권한 프라이밍 화면으로 진입시키는 콜백(§11.6 개정).
  final VoidCallback onOpenPriming;

  bool get _isNotDetermined =>
      status == NotificationPermissionStatus.notDetermined;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = _isNotDetermined
        ? '알림을 켜면 다음 수유 예상 시각과 기록 리마인더를 받을 수 있어요'
        : '기기 알림 권한이 꺼져 있어 알림을 받을 수 없어요';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x8,
        AppSpacing.x4,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              message,
              style: context.texts.caption.copyWith(color: colors.ink500),
            ),
          ),
          if (_isNotDetermined)
            TextButton(onPressed: onOpenPriming, child: const Text('알림 켜기'))
          else
            TextButton(
              onPressed: _openNotificationSettings,
              child: const Text('설정 열기'),
            ),
        ],
      ),
    );
  }

  Future<void> _openNotificationSettings() async {
    try {
      final Uri uri;
      if (Platform.isIOS) {
        // iOS에서 앱 설정 화면을 여는 표준 트릭.
        uri = Uri(scheme: 'app-settings');
      } else {
        final info = await PackageInfo.fromPlatform();
        uri = Uri.parse('package:${info.packageName}');
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      // TODO(M5): Android는 `package:` URI가 기기/버전에 따라 열리지 않을 수 있다.
      // permission_handler의 openAppSettings() 등 신뢰성 있는 방식으로 교체할 것.
    } on Object {
      // 설정 화면을 못 열어도 앱 동작에는 지장이 없어야 하므로 조용히 무시한다.
    }
  }
}
