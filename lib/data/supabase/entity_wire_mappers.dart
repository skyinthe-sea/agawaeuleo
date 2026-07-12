import '../../domain/entities/product.dart';
import '../../domain/entities/symptom.dart';
import '../../domain/entities/symptom_info.dart';
import 'row_mappers.dart';
import 'symptom_info_mappers.dart';

/// Supabase 와이어 행(Map) → 도메인 엔티티 매핑 (§5.3 단일 정의).
///
/// 원격 데이터소스(실시간/1회 조회)와 로컬 캐시 읽기 경로(Drift blob 디코드)가
/// **같은 매퍼**를 공유한다. 캐시 blob은 Supabase가 돌려준 행(JSON)을 그대로
/// 저장한 것이므로, 두 경로 모두 snake_case 와이어 셰이프를 입력으로 받는다.
/// jsonb(sections/emergency/sources)와 timestamptz는 postgrest가 디코드해도,
/// blob 왕복(문자열)해도 동일하게 파싱되도록 헬퍼가 방어적으로 처리한다.

/// `symptoms` 행 → [Symptom].
Symptom symptomFromWire(Map<String, dynamic> row) => Symptom(
  id: row['id'] as String,
  slug: row['slug'] as String,
  name: row['name'] as String,
  chosung: row['chosung'] as String,
  aliases: asStringList(row['aliases']),
  tagline: row['tagline'] as String?,
  emojiOrIcon: row['emoji_or_icon'] as String?,
  productKeywords: asStringList(row['product_keywords']),
  orderIndex: asIntOrNull(row['order_index']) ?? 0,
  audience: SymptomAudience.fromWire(row['audience'] as String?),
  isActive: row['is_active'] as bool? ?? true,
  createdAt: parseDate(row['created_at']),
);

/// `symptom_infos` 행 → [SymptomInfo].
SymptomInfo symptomInfoFromWire(Map<String, dynamic> row) => SymptomInfo(
  id: row['id'] as String,
  symptomId: row['symptom_id'] as String,
  summary: row['summary'] as String,
  sections: infoSectionsFromJson(row['sections']),
  emergency: asMapList(row['emergency'])
      .map(
        (m) => EmergencySign(
          sign: (m['sign'] ?? '') as String,
          action: (m['action'] ?? '') as String,
        ),
      )
      .toList(growable: false),
  sources: infoSourcesFromJson(row['sources']),
  updatedAt: parseDate(row['updated_at']),
);

/// `products` 행 → [Product].
Product productFromWire(Map<String, dynamic> row) => Product(
  id: row['id'] as String,
  symptomId: row['symptom_id'] as String,
  coupangPid: row['coupang_pid'] as String,
  title: row['title'] as String,
  imageUrl: row['image_url'] as String?,
  price: asIntOrNull(row['price']),
  rating: asDoubleOrNull(row['rating']),
  deeplink: row['deeplink'] as String,
  rankIndex: asIntOrNull(row['rank_index']) ?? 0,
  isActive: row['is_active'] as bool? ?? true,
  fetchedAt: parseDate(row['fetched_at']),
);
