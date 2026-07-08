import 'package:url_launcher/url_launcher.dart';

/// 증상 상세(§11.9)의 외부 연결 헬퍼.
///
/// 정책(§13.1): 쿠팡 딥링크·지도·전화는 모두 **외부 애플리케이션**으로 연다
/// (앱 내 웹뷰 금지 — App Store 4.2 방어 & 수수료 트래킹).
class ExternalLauncher {
  const ExternalLauncher._();

  /// 임의 [uri]를 외부 앱으로 연다. 성공 여부 반환(실패해도 throw하지 않음).
  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  /// 쿠팡 파트너스 딥링크(§7.1 `products.deeplink`)를 외부 브라우저로 연다.
  static Future<void> openDeeplink(String deeplink) async {
    final uri = Uri.tryParse(deeplink);
    if (uri == null) return;
    await open(uri);
  }

  /// "가까운 병원 찾기" — 네이티브 지도 앱의 장소 검색을 연다(§11.9).
  /// `geo:` 스킴을 우선 시도하고, 실패 시 웹 지도로 폴백한다.
  static Future<void> openNearbyHospitals() async {
    const query = '근처 소아과';
    final geo = Uri(
      scheme: 'geo',
      path: '0,0',
      queryParameters: <String, String>{'q': query},
    );
    if (await open(geo)) return;
    final web = Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': query,
    });
    await open(web);
  }

  /// 전화 연결(§11.9). [number] 예: '119'.
  static Future<void> dial(String number) async {
    await open(Uri(scheme: 'tel', path: number));
  }
}
