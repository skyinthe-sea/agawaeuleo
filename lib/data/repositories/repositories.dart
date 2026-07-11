/// data 레이어 리포지토리 구현 배럴 (§5.2 data → domain 인터페이스 구현).
///
/// `lib/application/providers.dart`가 이 배럴로 구현체와 지원 클래스를 가져와 도메인
/// 인터페이스(lib/domain/repositories)에 바인딩한다. 미구성(데모) 시 마스터 데이터는
/// 픽스처로, 개인기록은 로컬 전용으로 동작한다(§5.3).
library;

export 'app_config_repository_impl.dart';
export 'auth_repository_impl.dart';
export 'baby_repository_impl.dart';
export 'daily_encouragement_repository_impl.dart';
export 'favorite_repository_impl.dart';
export 'product_repository_impl.dart';
export 'recent_search_repository.dart';
export 'support/id_generator.dart';
export 'support/local_identity_store.dart';
export 'support/personal_payloads.dart';
export 'support/retry.dart';
export 'symptom_info_repository_impl.dart';
export 'symptom_repository_impl.dart';
export 'tracking_repository_impl.dart';
