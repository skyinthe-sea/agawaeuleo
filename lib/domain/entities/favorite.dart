import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite.freezed.dart';

/// 즐겨찾기 대상 종류 (§7.1 `favorites.target_type` = 'symptom'|'product').
enum FavoriteTargetType {
  symptom('symptom'),
  product('product');

  const FavoriteTargetType(this.wire);

  /// DB `target_type` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없으면 예외.
  static FavoriteTargetType fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'Unknown FavoriteTargetType');
  }

  /// DB 텍스트 → enum. 알 수 없거나 null이면 null.
  static FavoriteTargetType? tryFromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// 즐겨찾기 엔티티 (§7.1 `favorites`, §3 C5). 로컬 + 계정 동기화.
@freezed
abstract class Favorite with _$Favorite {
  const factory Favorite({
    required String id,
    required String userId,

    /// `target_type`.
    required FavoriteTargetType targetType,

    /// `target_id` — 대상 증상/제품의 uuid.
    required String targetId,

    required DateTime createdAt,
  }) = _Favorite;
}
