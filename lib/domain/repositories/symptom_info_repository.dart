import '../entities/symptom_info.dart';

/// 증상별 참고정보 읽기 전용 저장소 (§3 C3, §7.1 `symptom_infos`, §11.9).
///
/// 실패 시 구현체는 `AppException` 계열을 던지거나 스트림 error 이벤트로 전달한다.
abstract class SymptomInfoRepository {
  /// 특정 증상의 참고정보를 관찰. 없으면 null 방출.
  Stream<SymptomInfo?> watchBySymptom(String symptomId);

  /// 특정 증상의 참고정보 1회 조회. 없으면 null.
  Future<SymptomInfo?> getBySymptom(String symptomId);
}
