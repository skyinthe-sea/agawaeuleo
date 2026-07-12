import 'dart:convert';

import 'package:agawaeuleo/data/local/local.dart';
import 'package:drift/drift.dart' show Value;
import 'package:agawaeuleo/data/repositories/product_repository_impl.dart';
import 'package:agawaeuleo/data/repositories/symptom_info_repository_impl.dart';
import 'package:agawaeuleo/data/repositories/symptom_repository_impl.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/domain/entities/symptom_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// §5.3 캐싱 기능 — Drift 로컬 캐시(구성 모드) 읽기 경로 검증.
///
/// `MasterDataCacheService`가 하는 것과 동일하게 Supabase **와이어 행 JSON**을
/// blob으로 저장(`replace*`)한 뒤, 리포지토리가 그 blob을 공용 매퍼로 도메인화해
/// 올바르게 읽는지(활성/정렬 포함) 확인한다.
void main() {
  late AppDatabase db;
  late MasterCacheDao dao;

  setUp(() {
    db = AppDatabase.inMemory();
    dao = db.masterCacheDao;
  });

  tearDown(() => db.close());

  // 서비스의 _pullSymptoms와 동일한 방식으로 와이어 행을 blob에 넣는다.
  CachedSymptomsCompanion symptomRow({
    required String id,
    required String slug,
    required String name,
    int orderIndex = 0,
    bool isActive = true,
    String audience = 'baby',
  }) {
    final wire = <String, dynamic>{
      'id': id,
      'slug': slug,
      'name': name,
      'chosung': 'ㅌㅅㅌ',
      'aliases': <String>['가스'],
      'tagline': '한 줄 설명',
      'emoji_or_icon': 'tummy_pain',
      'product_keywords': <String>['배앓이'],
      'order_index': orderIndex,
      'audience': audience,
      'is_active': isActive,
      'created_at': '2026-01-01T00:00:00Z',
    };
    return CachedSymptomsCompanion.insert(
      id: id,
      slug: slug,
      orderIndex: Value(orderIndex),
      isActive: Value(isActive),
      data: jsonEncode(wire),
    );
  }

  group('SymptomRepositoryImpl (캐시 모드)', () {
    test('활성 증상을 order_index 순으로 매핑해 읽는다', () async {
      await dao.replaceSymptoms([
        symptomRow(id: 'b', slug: 'teething', name: '이앓이', orderIndex: 2),
        symptomRow(id: 'a', slug: 'colic', name: '배앓이', orderIndex: 1),
        symptomRow(
          id: 'z',
          slug: 'hidden',
          name: '비활성',
          orderIndex: 3,
          isActive: false,
        ),
      ]);
      final repo = SymptomRepositoryImpl(dao);

      final all = await repo.getAll();
      expect(all.map((s) => s.name), ['배앓이', '이앓이']); // 활성만·정렬
      expect(all.first, isA<Symptom>());
      expect(all.first.slug, 'colic');
      expect(all.first.aliases, contains('가스'));
    });

    test('getBySlug는 blob을 도메인으로 왕복 매핑한다', () async {
      await dao.replaceSymptoms([
        symptomRow(id: 'a', slug: 'colic', name: '배앓이', orderIndex: 1),
      ]);
      final repo = SymptomRepositoryImpl(dao);

      final colic = await repo.getBySlug('colic');
      expect(colic, isNotNull);
      expect(colic!.name, '배앓이');
      expect(await repo.getBySlug('nope'), isNull);
    });

    test('watchAll은 캐시 교체 시 재방출한다', () async {
      final repo = SymptomRepositoryImpl(dao);
      final emissions = <int>[];
      final sub = repo.watchAll().listen((list) => emissions.add(list.length));

      await Future<void>.delayed(Duration.zero);
      await dao.replaceSymptoms([
        symptomRow(id: 'a', slug: 'colic', name: '배앓이', orderIndex: 1),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emissions.last, 1);
      await sub.cancel();
    });
  });

  group('SymptomInfoRepositoryImpl (캐시 모드)', () {
    test('증상별 참고정보 blob을 SymptomInfo로 매핑한다', () async {
      final wire = <String, dynamic>{
        'id': 'info-1',
        'symptom_id': 'a',
        'summary': '요약입니다.',
        'sections': <dynamic>[
          {'type': 'text', 'title': '원인', 'body': '본문'},
        ],
        'emergency': <dynamic>[
          {'sign': '고열', 'action': '병원'},
        ],
        'sources': <dynamic>[
          {'label': '질병관리청'},
        ],
        'updated_at': '2026-02-02T00:00:00Z',
      };
      await dao.replaceSymptomInfos([
        CachedSymptomInfosCompanion.insert(
          symptomId: 'a',
          data: jsonEncode(wire),
          updatedAt: DateTime.utc(2026, 2, 2),
        ),
      ]);
      final repo = SymptomInfoRepositoryImpl(dao);

      final info = await repo.getBySymptom('a');
      expect(info, isNotNull);
      expect(info!.summary, '요약입니다.');
      expect(info.sections, hasLength(1));
      expect(info.sections.first, isA<InfoSectionText>());
      expect(info.hasEmergency, isTrue);
      expect(info.sources.first.label, '질병관리청');
      expect(await repo.getBySymptom('missing'), isNull);
    });
  });

  group('ProductRepositoryImpl (캐시 모드)', () {
    test('증상별 활성 제품을 rank_index 순으로 매핑한다', () async {
      CachedProductsCompanion productRow({
        required String id,
        required int rank,
        bool isActive = true,
      }) {
        final wire = <String, dynamic>{
          'id': id,
          'symptom_id': 'a',
          'coupang_pid': 'pid-$id',
          'title': '제품 $id',
          'image_url': null,
          'price': 12000,
          'rating': 4.5,
          'deeplink': 'https://link.coupang.com/$id',
          'rank_index': rank,
          'is_active': isActive,
          'fetched_at': '2026-03-03T00:00:00Z',
        };
        return CachedProductsCompanion.insert(
          id: id,
          symptomId: 'a',
          rankIndex: Value(rank),
          isActive: Value(isActive),
          data: jsonEncode(wire),
        );
      }

      await dao.replaceProducts([
        productRow(id: 'p2', rank: 2),
        productRow(id: 'p1', rank: 1),
        productRow(id: 'p3', rank: 3, isActive: false),
      ]);
      final repo = ProductRepositoryImpl(dao);

      final products = await repo.getBySymptom('a');
      expect(products.map((p) => p.id), ['p1', 'p2']); // 활성만·정렬
      expect(products.first.title, '제품 p1');
      expect(products.first.price, 12000);
    });
  });

  group('cache_meta 버전', () {
    test('setVersion → getVersion 왕복', () async {
      expect(await dao.getVersion('products'), isNull);
      await dao.setVersion('products', 7, DateTime.utc(2026));
      expect(await dao.getVersion('products'), 7);
      await dao.setVersion('products', 8, DateTime.utc(2026));
      expect(await dao.getVersion('products'), 8); // upsert 갱신
    });
  });
}
