import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 증상 상세(§11.9) 화면 전용 프로바이더 모음.
///
/// 코드젠을 쓰지 않는 **수동 Riverpod**이다(피처 규칙). 리포지토리 프로바이더
/// (전부 keepAlive)만 watch 하며, 데이터 소스는 미구성 시 픽스처가 자동 공급한다.

/// 라우트 `slug`(§4.1 딥링크)로 증상 마스터를 1회 조회. 없으면 `null`.
final symptomBySlugProvider = FutureProvider.family<Symptom?, String>(
  (ref, slug) => ref.watch(symptomRepositoryProvider).getBySlug(slug),
);

/// 증상의 참고정보(요약·섹션·응급신호)를 관찰. 없으면 `null` 방출.
final symptomInfoProvider = StreamProvider.family<SymptomInfo?, String>(
  (ref, symptomId) =>
      ref.watch(symptomInfoRepositoryProvider).watchBySymptom(symptomId),
);

/// 증상의 추천 제품을 `rank_index` 순으로 관찰(§11.9 수익 섹션).
final symptomProductsProvider = StreamProvider.family<List<Product>, String>(
  (ref, symptomId) =>
      ref.watch(productRepositoryProvider).watchBySymptom(symptomId),
);

/// 이 증상의 즐겨찾기 여부를 관찰(헤더 별 상태 — §11.9/§11.15).
final symptomFavoriteProvider = StreamProvider.family<bool, String>(
  (ref, symptomId) => ref
      .watch(favoriteRepositoryProvider)
      .watchIsFavorite(
        targetType: FavoriteTargetType.symptom,
        targetId: symptomId,
      ),
);
