/// Supabase 데이터 레이어 배럴 (§5.2 data). 부트스트랩·에러 매퍼·원격 데이터소스 모음.
///
/// 리포지토리/프로바이더 레이어는 이 배럴 하나로 필요한 데이터소스를 가져온다. 각 데이터소스는
/// [SupabaseClient]를 생성자 주입받는 순수 클래스(Riverpod 비의존)이며, 실패는 모두
/// `AppException`(lib/core/error) 계열로 변환해 던진다.
library;

export 'app_config_remote_data_source.dart';
export 'auth_data_source.dart';
export 'baby_remote_data_source.dart';
export 'daily_encouragement_remote_data_source.dart';
export 'favorite_remote_data_source.dart';
export 'product_remote_data_source.dart';
export 'row_mappers.dart';
export 'supabase_bootstrap.dart';
export 'supabase_error_mapper.dart';
export 'symptom_info_remote_data_source.dart';
export 'symptom_remote_data_source.dart';
export 'tracking_remote_data_source.dart';
