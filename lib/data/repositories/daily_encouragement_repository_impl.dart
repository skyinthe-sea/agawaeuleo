import 'package:agawaeuleo/data/fixtures/fixture_encouragements.dart';
import 'package:agawaeuleo/data/repositories/support/retry.dart';
import 'package:agawaeuleo/data/supabase/daily_encouragement_remote_data_source.dart';
import 'package:agawaeuleo/domain/entities/daily_encouragement.dart';
import 'package:agawaeuleo/domain/repositories/daily_encouragement_repository.dart';

/// [DailyEncouragementRepository] 구현 (§7.1 공개 읽기, 홈 "오늘의 응원").
///
/// - **구성됨(isConfigured)**: Supabase [DailyEncouragementRemoteDataSource]에서 읽고
///   메모리 캐시.
/// - **미구성(데모 모드) / 원격이 빈 목록**: [fixtureEncouragements]로 폴백해 인사 영역이
///   비지 않게 한다(§12.2 빈 화면 방지). 응원 한 줄은 늘 보여야 하는 정서적 UI라
///   빈 목록도 데모로 대체한다.
class DailyEncouragementRepositoryImpl implements DailyEncouragementRepository {
  DailyEncouragementRepositoryImpl([this._remote]);

  final DailyEncouragementRemoteDataSource? _remote;

  /// getAll 결과 메모리 캐시. 스트림 방출 시에도 갱신한다.
  List<DailyEncouragement>? _cache;

  bool get _isDemo => _remote == null;

  @override
  Stream<List<DailyEncouragement>> watchAll() {
    if (_isDemo) return Stream<List<DailyEncouragement>>.value(_demo());
    return _remote!.watchAll().map((list) {
      final resolved = list.isEmpty ? _demo() : list;
      _cache = resolved;
      return resolved;
    });
  }

  @override
  Future<List<DailyEncouragement>> getAll() async {
    if (_isDemo) return _demo();
    final cached = _cache;
    if (cached != null) return cached;
    final list = await retryWithBackoff(() => _remote!.getAll());
    final resolved = list.isEmpty ? _demo() : list;
    return _cache = resolved;
  }

  /// 데모(미구성) 응원 목록 — 활성만, `order_index` 오름차순.
  List<DailyEncouragement> _demo() =>
      fixtureEncouragements.where((e) => e.isActive).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
}
