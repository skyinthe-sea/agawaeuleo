import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// §3.3·§11.1 강제 업데이트 안내 화면. 현재 버전이 원격 최소 버전 미만이면 스플래시가 앱 진입을
/// 잠그고 이 화면을 노출한다. "스토어로 이동"만 제공하며 건너뛰기/재시도는 없다(강제).
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  // TODO(발주자): 실제 App Store ID / Play 패키지명으로 교체.
  //   iOS  : https://apps.apple.com/app/id<APP_STORE_ID>
  //   Android: market://details?id=<PACKAGE_NAME> (없으면 웹 폴백 사용)
  static const String _iosStoreUrl = 'https://apps.apple.com/app/id0000000000';
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.agawaeuleo';

  Future<void> _openStore() async {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosStoreUrl
        : _androidStoreUrl;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object {
      // 스토어를 열지 못해도 화면은 잠금 상태를 유지한다(강제 업데이트 정책).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paperBg,
      body: SafeArea(
        child: EmptyState(
          icon: Icons.system_update_rounded,
          title: '업데이트가 필요해요',
          message: '최신 버전에서 이용할 수 있어요 · 스토어에서 업데이트해 주세요',
          actionLabel: '스토어로 이동',
          onAction: _openStore,
        ),
      ),
    );
  }
}
