import 'package:agawaeuleo/data/repositories/daily_encouragement_repository_impl.dart';
import 'package:agawaeuleo/domain/entities/daily_encouragement.dart';
import 'package:flutter_test/flutter_test.dart';

/// 홈 "오늘의 응원" — 미구성(데모) 모드에서 픽스처 폴백 검증.
///
/// 원격 데이터소스를 주입하지 않으면 리포지토리는 데모 모드로 동작해 시드(0006)와 동일한
/// 100개 문구 픽스처를 `order_index` 오름차순으로 반환한다(§12.2 빈 화면 방지).
void main() {
  late DailyEncouragementRepositoryImpl repo;

  setUp(() {
    repo = DailyEncouragementRepositoryImpl(); // 원격 없음 → 데모(픽스처) 모드
  });

  test('getAll은 100개 픽스처를 order_index 오름차순(1..100)으로 반환한다', () async {
    final all = await repo.getAll();
    expect(all, hasLength(100));
    expect(
      all.map((e) => e.orderIndex).toList(),
      List<int>.generate(100, (i) => i + 1),
    );
    expect(
      all.every((e) => e.message.trim().isNotEmpty),
      isTrue,
      reason: '빈 문구가 없어야 한다',
    );
  });

  test('문구는 서로 중복되지 않는다', () async {
    final all = await repo.getAll();
    expect(all.map((e) => e.message).toSet(), hasLength(100));
  });

  test('watchAll의 최초 방출이 100개 데모 목록을 준다', () async {
    await expectLater(
      repo.watchAll(),
      emits(predicate<List<DailyEncouragement>>((l) => l.length == 100)),
    );
  });
}
