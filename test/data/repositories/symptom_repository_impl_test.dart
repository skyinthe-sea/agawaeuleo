import 'package:agawaeuleo/data/repositories/symptom_repository_impl.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:flutter_test/flutter_test.dart';

/// §11.7 홈 그리드 · §11.8 초성/부분/별칭 검색 — 미구성(데모) 모드에서 픽스처로 검증.
///
/// 원격 데이터소스를 주입하지 않으면 리포지토리는 데모 모드로 동작해 시드와 동일한
/// 16종 증상 픽스처를 반환한다(§12.2 빈 화면 방지).
void main() {
  late SymptomRepositoryImpl repo;

  setUp(() {
    repo = SymptomRepositoryImpl(); // 원격 없음 → 데모(픽스처) 모드
  });

  Iterable<String> names(List<Symptom> list) => list.map((s) => s.name);

  group('마스터 조회', () {
    test('getAll은 16종 픽스처를 order_index 오름차순으로 반환한다', () async {
      final all = await repo.getAll();
      expect(all, hasLength(16));

      final orders = all.map((s) => s.orderIndex).toList();
      final sorted = [...orders]..sort();
      expect(orders, sorted, reason: 'order_index 오름차순 정렬이어야 한다');

      expect(all.first.name, '배앓이'); // order_index 1
    });

    test('getBySlug는 slug로 단건을 찾는다', () async {
      final colic = await repo.getBySlug('colic');
      expect(colic, isNotNull);
      expect(colic!.name, '배앓이');

      expect(await repo.getBySlug('does-not-exist'), isNull);
    });

    test('getById는 id로 단건을 찾고, 없으면 null', () async {
      final colic = await repo.getBySlug('colic');
      final byId = await repo.getById(colic!.id);
      expect(byId, isNotNull);
      expect(byId!.slug, 'colic');

      expect(await repo.getById('nope'), isNull);
    });
  });

  group('검색 (§11.8)', () {
    test("초성열 'ㅂㅇㅇ' → 배앓이", () async {
      final result = await repo.search('ㅂㅇㅇ');
      expect(names(result), contains('배앓이'));
    });

    test("초성 부분열 'ㅅㅁ' → 수면퇴행", () async {
      // 수면퇴행의 초성열은 'ㅅㅁㅌㅎ' — 접두 초성 'ㅅㅁ'으로 매칭돼야 한다.
      final result = await repo.search('ㅅㅁ');
      expect(names(result), contains('수면퇴행'));
    });

    test("별칭 매칭 '가스' → 배앓이 포함, 1건 이상", () async {
      // '배앓이'의 aliases에 '가스'가 있다.
      final result = await repo.search('가스');
      expect(result, isNotEmpty);
      expect(names(result), contains('배앓이'));
    });

    test('부분 문자열 매칭 — 이름 일부로도 찾는다', () async {
      final result = await repo.search('수면');
      expect(names(result), contains('수면퇴행'));
    });

    test('공백/빈 질의는 빈 목록', () async {
      expect(await repo.search(''), isEmpty);
      expect(await repo.search('   '), isEmpty);
    });
  });

  test('watchAll의 최초 방출이 16종 데모 목록을 준다', () async {
    await expectLater(
      repo.watchAll(),
      emits(predicate<List<Symptom>>((l) => l.length == 16)),
    );
  });
}
