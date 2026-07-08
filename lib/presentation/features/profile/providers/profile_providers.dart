import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/baby.dart';

/// §11.13/§11.14 내 정보·아기 프로필 화면 전용 프로바이더 모음.
///
/// 코드젠 없는 **수동 Riverpod**(feature 소유 규칙). 리포지토리 프로바이더
/// (전부 keepAlive)만 watch 한다.

/// 인증 세션(익명↔연결) 변화를 감지하기 위한 구독용 프로바이더(§11.13).
///
/// 값 자체(user_id)보다 "이 스트림을 watch해 재빌드를 트리거"하는 목적이 크다.
/// 실제 게스트 여부/식별자는 [authRepositoryProvider]의 동기 getter(`isAnonymous`,
/// `currentUserId`)로 읽는다.
final authStateChangesProvider = StreamProvider.autoDispose<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// §11.13 게스트(미연결) 여부. 세션 변화가 있을 때마다 재계산된다.
///
/// [AuthRepository.isAnonymous]가 핵심 신호지만, Supabase 미구성(픽스처 데모)
/// 환경에서는 원격 인증이 없어 `isSignedIn`이 항상 false이므로 `isAnonymous`
/// 단독으로는 게스트를 판별할 수 없다(둘 다 false). `!isSignedIn`도 함께 봐서
/// "연결된 계정이 아니면 게스트"로 취급한다.
final isGuestProvider = Provider.autoDispose<bool>((ref) {
  ref.watch(authStateChangesProvider);
  final auth = ref.watch(authRepositoryProvider);
  return !auth.isSignedIn || auth.isAnonymous;
});

/// 현재 세션 user_id(§11.13 헤더 표시용 — 이메일 필드가 없어 대체 표기).
final currentUserIdProvider = Provider.autoDispose<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUserId;
});

/// §11.14 아기 프로필 목록(생성순 관찰).
final babiesProvider = StreamProvider.autoDispose<List<Baby>>((ref) {
  return ref.watch(babyRepositoryProvider).watchAll();
});
