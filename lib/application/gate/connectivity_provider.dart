import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.17 전역 네트워크 상태(온라인 여부) 스트림.
///
/// `connectivity_plus`의 초기 상태 + 변화 스트림을 온라인 불리언으로 정규화한다.
/// (`ConnectivityResult.none` 외의 인터페이스가 하나라도 있으면 온라인으로 본다.)
/// 값이 아직 없을 때(로딩)는 셸이 온라인으로 간주해 배너를 숨긴다(오탐 방지).
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);
