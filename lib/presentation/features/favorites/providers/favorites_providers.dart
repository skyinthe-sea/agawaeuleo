import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/entities.dart';

/// §11.15 즐겨찾기 화면 상태 — 코드젠 없는 수동 Riverpod(feature 소유 규칙).
///
/// [FavoriteRepository]는 대상(증상/제품) id만 저장하므로, 실제 엔티티는
/// [SymptomRepository]/[ProductRepository]에서 별도로 조인한다.
/// [ProductRepository]가 증상 단위 조회(`watchBySymptom`)만 제공해 제품 id
/// 단건 조회가 없으므로, 활성 증상 전체를 순회해 제품 카탈로그를 구성한 뒤
/// 즐겨찾기 id로 필터링한다 — 픽스처 규모(16종 × 2~3개)에서 가볍다. 통합
/// 단계에서 제품 단건 조회 API가 생기면 [_productCatalogProvider]를 교체할 것.

/// 본인 즐겨찾기 전체(§7.1 `favorites`) — `created_at` 역순(최신 우선).
final favoritesProvider = StreamProvider.autoDispose<List<Favorite>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watchAll();
});

/// 활성 증상 전체(증상 카탈로그 조인 + 제품 카탈로그 구성용 — §11.15).
final _allSymptomsProvider = StreamProvider.autoDispose<List<Symptom>>((ref) {
  return ref.watch(symptomRepositoryProvider).watchAll();
});

/// 전체 활성 증상의 제품을 모은 카탈로그(id → Product). 증상별 `getBySymptom`을
/// 모아 구성한다(§11.9와 동일한 픽스처/원격 소스 재사용).
final _productCatalogProvider =
    FutureProvider.autoDispose<Map<String, Product>>((ref) async {
      final symptoms = await ref.watch(_allSymptomsProvider.future);
      final repo = ref.watch(productRepositoryProvider);
      final lists = await Future.wait(
        symptoms.map((s) => repo.getBySymptom(s.id)),
      );
      final catalog = <String, Product>{};
      for (final list in lists) {
        for (final product in list) {
          catalog[product.id] = product;
        }
      }
      return catalog;
    });

/// §11.15 "증상" 탭 — 즐겨찾기된 증상 목록(즐겨찾기 최신순 유지).
final favoriteSymptomsProvider =
    Provider.autoDispose<AsyncValue<List<Symptom>>>((ref) {
      final favoritesAsync = ref.watch(favoritesProvider);
      final symptomsAsync = ref.watch(_allSymptomsProvider);

      if (favoritesAsync.isLoading || symptomsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      final error = favoritesAsync.error ?? symptomsAsync.error;
      if (error != null) {
        return AsyncValue.error(
          error,
          favoritesAsync.stackTrace ??
              symptomsAsync.stackTrace ??
              StackTrace.current,
        );
      }

      final favorites = favoritesAsync.value ?? const <Favorite>[];
      final bySymptomId = <String, Symptom>{
        for (final s in symptomsAsync.value ?? const <Symptom>[]) s.id: s,
      };
      final list = <Symptom>[
        for (final f in favorites)
          if (f.targetType == FavoriteTargetType.symptom &&
              bySymptomId[f.targetId] != null)
            bySymptomId[f.targetId]!,
      ];
      return AsyncValue.data(list);
    });

/// §11.15 "제품" 탭 — 즐겨찾기된 제품 목록(즐겨찾기 최신순 유지).
final favoriteProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
      final favoritesAsync = ref.watch(favoritesProvider);
      final catalogAsync = ref.watch(_productCatalogProvider);

      if (favoritesAsync.isLoading || catalogAsync.isLoading) {
        return const AsyncValue.loading();
      }
      final error = favoritesAsync.error ?? catalogAsync.error;
      if (error != null) {
        return AsyncValue.error(
          error,
          favoritesAsync.stackTrace ??
              catalogAsync.stackTrace ??
              StackTrace.current,
        );
      }

      final favorites = favoritesAsync.value ?? const <Favorite>[];
      final catalog = catalogAsync.value ?? const <String, Product>{};
      final list = <Product>[
        for (final f in favorites)
          if (f.targetType == FavoriteTargetType.product &&
              catalog[f.targetId] != null)
            catalog[f.targetId]!,
      ];
      return AsyncValue.data(list);
    });
