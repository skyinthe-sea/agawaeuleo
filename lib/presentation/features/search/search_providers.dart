import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.8 검색 화면 상태 배선 — 코드젠 없는 수동 Riverpod.
///
/// 리포지토리 프로바이더([symptomRepositoryProvider], [recentSearchRepositoryProvider])는
/// application/providers.dart 의 codegen keepAlive 프로바이더를 그대로 watch 한다.

/// 디바운스된 [query]에 대한 증상 검색 결과(§11.8).
///
/// 초성('ㅂㅇㅇ')·부분일치·별칭 매칭은 리포지토리가 `HangulChosung.matches`로 처리한다.
/// 공백/빈 질의는 빈 목록. family 키(질의)마다 캐시되며 화면 이탈 시 autoDispose 된다.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Symptom>, String>((ref, query) {
      final q = query.trim();
      if (q.isEmpty) return const <Symptom>[];
      return ref.watch(symptomRepositoryProvider).search(q);
    });

/// 최근 검색어(로컬 전용, 최신순) — 입력이 비었을 때 노출(§11.8).
final recentSearchesProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(recentSearchRepositoryProvider).watchRecent(),
);
