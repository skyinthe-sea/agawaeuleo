import 'package:agawaeuleo/data/repositories/support/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 우선 개인기록(§5.3)의 소유자 식별자 저장소.
///
/// 로그인/세션과 **독립적으로** 기록·아기·즐겨찾기를 로컬에 남기기 위한 안정적 uuid를
/// `shared_preferences`에 보관한다(§2-4 로그인·연결 무관 기록). 이 값은:
///   - 개인기록 로컬 행의 `user_id`로 사용되어 로컬 유니크 제약(favorites)과 조회를
///     일관되게 만든다.
///   - 동기화 push 시 원격 데이터소스가 `user_id`를 `auth.uid()`로 덮어쓰므로 서버
///     소유권과 무관하다(로컬 그룹핑 전용).
///
/// 세션이 익명↔로그인으로 승격돼도 이 값은 바뀌지 않아, 게스트 상태에서 남긴 로컬 기록이
/// 그대로 이어진다.
class LocalIdentityStore {
  LocalIdentityStore();

  /// `shared_preferences` 저장 키.
  static const String prefsKey = 'personal.local_user_id';

  String? _cached;

  /// 이미 로드된 경우의 캐시 값(없으면 null). 동기 접근용.
  String? get idOrNull => _cached;

  /// 로컬 사용자 id를 반환한다. 없으면 새로 생성해 저장한다(최초 1회).
  Future<String> ensureId() async {
    final cached = _cached;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(prefsKey);
    if (id == null || id.isEmpty) {
      id = newUuidV4();
      await prefs.setString(prefsKey, id);
    }
    return _cached = id;
  }

  /// 로컬 식별자를 초기화한다(계정 파기 후 새 게스트 신원 발급 — §3.3).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
    _cached = null;
  }
}
