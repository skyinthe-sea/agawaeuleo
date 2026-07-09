import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// §3.3 푸시 카테고리 · §12 발주자 준비물(google-services 설정 파일).
///
/// FCM 클라이언트 래퍼. **미구성 가드**: `google-services.json` /
/// `GoogleService-Info.plist`(및 `firebase_options.dart`)가 아직 없으면
/// [Firebase.initializeApp]이 예외를 던진다 — 이를 잡아 조용히 비활성화하고 앱은 계속
/// 부팅된다(발주자가 나중에 파일을 추가하면 자동 활성). 현재 범위는 **토큰 조회/로깅**까지이며
/// 서버 발송·토픽 구독은 범위 밖이다.
class FcmClient {
  bool _available = false;

  /// Firebase 초기화에 성공해 FCM을 쓸 수 있는지.
  bool get isAvailable => _available;

  String? _token;

  /// 마지막으로 확보한 FCM 등록 토큰(미구성/실패 시 null).
  String? get token => _token;

  /// Firebase 초기화 + 토큰 조회/로깅. 설정 파일이 없으면 no-op으로 조용히 비활성화한다.
  Future<void> ensureInitialized() async {
    if (_available) return;
    try {
      await Firebase.initializeApp();
      _available = true;
    } on Object catch (error) {
      // google-services 설정 파일 미추가 → 푸시 비활성(§12 발주자가 나중에 추가).
      _available = false;
      debugPrint('[FcmClient] Firebase 미구성 — 푸시 비활성: $error');
      return;
    }

    try {
      _token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FcmClient] FCM token: $_token');
      FirebaseMessaging.instance.onTokenRefresh.listen((refreshed) {
        _token = refreshed;
        debugPrint('[FcmClient] FCM token refreshed: $refreshed');
      });
    } on Object catch (error) {
      // 토큰 조회 실패는 치명적이지 않다(APNs 미구성 등) — 앱 동작에 영향 없음.
      debugPrint('[FcmClient] 토큰 조회 실패: $error');
    }
  }
}
