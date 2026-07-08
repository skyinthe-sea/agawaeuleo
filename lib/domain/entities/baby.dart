import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby.freezed.dart';

/// 아기 성별 (§7.1 `babies.gender` = 'male'|'female'|'na').
enum BabyGender {
  male('male'),
  female('female'),
  na('na');

  const BabyGender(this.wire);

  /// DB `gender` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없거나 null이면 [BabyGender.na].
  static BabyGender fromWire(String? value) {
    for (final g in values) {
      if (g.wire == value) return g;
    }
    return BabyGender.na;
  }
}

/// 아기 프로필 엔티티 (§7.1 `babies`, §3 S3, §11.14). 다둥이 대비 복수 프로필.
@freezed
abstract class Baby with _$Baby {
  const Baby._();

  const factory Baby({
    required String id,
    required String userId,
    required String name,

    /// `birth_date`(nullable). 없으면 [ageInMonths]는 null.
    DateTime? birthDate,

    /// `gender`(nullable 텍스트 → 기본 [BabyGender.na]).
    @Default(BabyGender.na) BabyGender gender,

    required DateTime createdAt,
  }) = _Baby;

  /// 현재(now) 기준 개월수. 생년월일이 없으면 null. (§11.14 개월수 자동계산)
  int? get ageInMonths => ageInMonthsOn(DateTime.now());

  /// [reference] 기준 개월수(테스트 가능). 생년월일이 없으면 null.
  int? ageInMonthsOn(DateTime reference) {
    final birth = birthDate;
    if (birth == null) return null;
    var months =
        (reference.year - birth.year) * 12 + (reference.month - birth.month);
    if (reference.day < birth.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}
