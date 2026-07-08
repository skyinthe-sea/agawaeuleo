import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §11.7 홈 화면 상태 — 코드젠 없는 수동 Riverpod.
///
/// 리포지토리 프로바이더(전부 keepAlive)는 `lib/application/providers.dart`의
/// 것을 watch 한다. 데이터 소스는 Supabase 미구성 시 픽스처가 자동 공급한다.

/// 홈 증상 그리드 스트림(활성 증상, `order_index` 순 — §11.7).
///
/// pull-to-refresh는 `ref.refresh(homeSymptomsProvider.future)`로 재조회한다.
final homeSymptomsProvider = StreamProvider<List<Symptom>>((ref) {
  return ref.watch(symptomRepositoryProvider).watchAll();
});

/// 본인 소유 아기 목록 스트림(인사 문구용).
final _babiesProvider = StreamProvider<List<Baby>>((ref) {
  return ref.watch(babyRepositoryProvider).watchAll();
});

/// 현재 선택된 아기 id 스트림(다둥이 전환 — §11.10).
final _selectedBabyIdProvider = StreamProvider<String?>((ref) {
  return ref.watch(babyRepositoryProvider).watchSelectedBabyId();
});

/// 상단바 인사에 쓰는 현재 아기. 로딩/에러/없음이면 `null`(기본 인사로 폴백).
final selectedBabyProvider = Provider<Baby?>((ref) {
  final babies = ref.watch(_babiesProvider).value ?? const <Baby>[];
  if (babies.isEmpty) return null;
  final selectedId = ref.watch(_selectedBabyIdProvider).value;
  if (selectedId != null) {
    for (final baby in babies) {
      if (baby.id == selectedId) return baby;
    }
  }
  return babies.first;
});

/// 최근 본 증상 slug 목록(로컬 저장, 최신 우선 — §11.7 선택 항목).
///
/// `shared_preferences`에 직접 저장한다. 증상 카드/칩 탭 시 [RecentSymptomsNotifier.record]로
/// 갱신한다. 통합 시 증상 상세 화면 진입에서도 record를 호출하면 상세 열람까지 반영된다.
final recentSymptomsProvider =
    NotifierProvider<RecentSymptomsNotifier, List<String>>(
      RecentSymptomsNotifier.new,
    );

/// [recentSymptomsProvider]의 노티파이어. slug 리스트를 SharedPreferences에 유지.
class RecentSymptomsNotifier extends Notifier<List<String>> {
  static const String _prefsKey = 'home.recent_symptom_slugs';
  static const int _maxItems = 10;

  SharedPreferences? _prefs;

  @override
  List<String> build() {
    // 동기 초기값은 빈 목록. 저장소는 비동기로 로드해 state에 반영한다.
    _load();
    return const <String>[];
  }

  Future<void> _load() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const <String>[];
  }

  /// [slug]를 최신으로 올린다(중복 제거, 최대 [_maxItems]개 유지).
  Future<void> record(String slug) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final next = <String>[
      slug,
      ...state.where((existing) => existing != slug),
    ].take(_maxItems).toList(growable: false);
    state = next;
    await prefs.setStringList(_prefsKey, next);
  }
}
