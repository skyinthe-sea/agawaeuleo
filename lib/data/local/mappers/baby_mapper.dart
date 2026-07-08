import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:drift/drift.dart';

/// 도메인 `Baby` ↔ Drift 행/컴패니언 매퍼 (§5.2 도메인 분리).
extension BabyRowMapper on BabyRow {
  /// 로컬 행 → 도메인 엔티티. [gender]는 미지/null → `na`.
  Baby toDomain() => Baby(
    id: id,
    userId: userId,
    name: name,
    birthDate: birthDate,
    gender: BabyGender.fromWire(gender),
    createdAt: createdAt,
  );
}

extension BabyCompanionMapper on Baby {
  /// 도메인 엔티티 → upsert용 컴패니언.
  BabiesCompanion toCompanion({
    Value<String?> serverId = const Value.absent(),
  }) => BabiesCompanion.insert(
    id: id,
    serverId: serverId,
    userId: userId,
    name: name,
    birthDate: Value(birthDate),
    gender: Value(gender.wire),
    createdAt: createdAt,
  );
}
