import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/domain/entities/favorite.dart';
import 'package:drift/drift.dart';

/// 도메인 `Favorite` ↔ Drift 행/컴패니언 매퍼 (§5.2 도메인 분리).
extension FavoriteRowMapper on FavoriteRow {
  /// 로컬 행 → 도메인 엔티티.
  Favorite toDomain() => Favorite(
    id: id,
    userId: userId,
    targetType: FavoriteTargetType.fromWire(targetType),
    targetId: targetId,
    createdAt: createdAt,
  );
}

extension FavoriteCompanionMapper on Favorite {
  /// 도메인 엔티티 → upsert용 컴패니언.
  FavoritesCompanion toCompanion({
    Value<String?> serverId = const Value.absent(),
  }) => FavoritesCompanion.insert(
    id: id,
    serverId: serverId,
    userId: userId,
    targetType: targetType.wire,
    targetId: targetId,
    createdAt: createdAt,
  );
}
