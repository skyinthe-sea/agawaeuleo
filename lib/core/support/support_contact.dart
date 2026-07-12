import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 고객 문의 창구(§11.13/§11.16).
///
/// 발주자 문의 이메일. 화면·테스트가 하드코딩하지 않도록 단일 소스로 노출한다.
const String supportEmail = 'myclick90@gmail.com';

/// 문의 메일 앱을 **외부 애플리케이션**으로 연다.
///
/// 메일 앱을 열 수 없는 기기(메일 계정 미설정 등)에서도 문의가 "먹통"이 되지 않도록,
/// 실패 시 주소를 클립보드에 복사하고 스낵바로 안내한다. Android 11+ 에서
/// `launchUrl(mailto)` 가 성공하려면 매니페스트 `<queries>` 에 mailto(SENDTO)
/// 인텐트가 선언돼 있어야 한다(AndroidManifest.xml 참조).
Future<void> launchSupportEmail(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.parse(
    'mailto:$supportEmail?subject=${Uri.encodeComponent('[아가왜울어] 문의')}',
  );

  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    launched = false;
  }
  if (launched) return;

  // 폴백: 메일 앱을 열 수 없을 때 주소를 복사해 직접 보낼 수 있게 안내한다.
  await Clipboard.setData(const ClipboardData(text: supportEmail));
  messenger.showSnackBar(
    SnackBar(content: Text('메일 주소를 복사했어요 · $supportEmail')),
  );
}
