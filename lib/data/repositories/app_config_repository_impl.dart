import 'dart:async';

import 'package:agawaeuleo/data/repositories/support/retry.dart';
import 'package:agawaeuleo/data/supabase/app_config_remote_data_source.dart';
import 'package:agawaeuleo/domain/entities/remote_app_config.dart';
import 'package:agawaeuleo/domain/repositories/app_config_repository.dart';

/// [AppConfigRepository] 구현 (§3.3 강제 업데이트·점검, §7.1 `app_config`).
///
/// **미구성 가드**: Supabase 데이터소스가 없거나(미구성) 조회가 실패하면 앱을 잠그지 않도록
/// 항상 [RemoteAppConfig.safeDefault]를 반환한다(강제 업데이트/점검 오탐 방지). 원격 설정은
/// 앱 접근 자체를 막을 수 있는 값이므로, 불확실할 때는 "열어두는" 쪽으로 실패한다.
class AppConfigRepositoryImpl implements AppConfigRepository {
  AppConfigRepositoryImpl([this._remote]);

  final AppConfigRemoteDataSource? _remote;

  @override
  Future<RemoteAppConfig> getConfig() async {
    final remote = _remote;
    if (remote == null) return RemoteAppConfig.safeDefault();
    try {
      return await retryWithBackoff(remote.getConfig);
    } on Object {
      // 미구성 가드와 동일한 정신: 실패 시 앱을 잠그지 않는다.
      return RemoteAppConfig.safeDefault();
    }
  }

  @override
  Stream<RemoteAppConfig> watch() {
    final remote = _remote;
    if (remote == null) {
      return Stream<RemoteAppConfig>.value(RemoteAppConfig.safeDefault());
    }
    // error 이벤트도 앱을 잠그지 않도록 안전 기본값으로 치환한다.
    return remote.watch().transform(
      StreamTransformer<RemoteAppConfig, RemoteAppConfig>.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.add(RemoteAppConfig.safeDefault()),
      ),
    );
  }
}
