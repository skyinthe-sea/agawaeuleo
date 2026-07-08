import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme/theme.dart';

/// §11.16 "권한 꺼져있으면 안내+설정 이동". 실제 OS 알림 권한 상태를 감지하는
/// 로직(플랫폼별 권한 조회·요청)은 M5에서 완성한다 — 여기서는 마스터 토글이 켜져
/// 있을 때 항상 안내 문구를 보여주고, "설정 열기"는 기기 설정 앱으로 이동을
/// 시도하는 최선 노력(best-effort) 동작만 제공한다.
class NotificationPermissionHint extends StatelessWidget {
  const NotificationPermissionHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              '기기 알림 권한이 꺼져 있으면 알림을 받을 수 없어요',
              style: context.texts.caption.copyWith(color: colors.ink500),
            ),
          ),
          TextButton(
            onPressed: () => _openNotificationSettings(),
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
