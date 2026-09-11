import 'package:agawaeuleo/presentation/features/auth/login_screen.dart';
import 'package:agawaeuleo/presentation/features/auth/permission_priming_screen.dart';
import 'package:agawaeuleo/presentation/features/auth/signup_screen.dart';
import 'package:agawaeuleo/presentation/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_app_harness.dart';

Future<void> _pumpAuthScreen(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(
    ProviderScope(child: withReduceMotion(tester, MaterialApp(home: screen))),
  );
  await tester.pump();
}

void main() {
  group('§11.3 로그인 유효성', () {
    testWidgets('잘못된 이메일 + 빈 비밀번호로 로그인 시 필드 에러(흔들기)가 렌더된다', (tester) async {
      await _pumpAuthScreen(tester, const LoginScreen());

      // 이메일 필드에 형식이 틀린 값을 입력(비밀번호는 비움).
      await tester.enterText(find.byType(AppTextField).first, 'not-an-email');
      await tester.pump();

      // '로그인' 탭 → 동기 유효성 검사 실패.
      await tester.tap(find.text('로그인'));
      await tester.pump();

      expect(find.text('이메일 형식을 확인해 주세요.'), findsOneWidget);
      expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
      // 에러를 감싸 흔드는 Shake 위젯이 살아 있다(§11.3 흔들기).
      expect(find.byType(AppTextField), findsWidgets);

      // 포커스된 TextField의 커서 깜빡임 Timer를 정리하기 위해 트리를 언마운트한다.
      await disposeApp(tester);
    });
  });

  group('§11.4 회원가입 비밀번호 강도 바', () {
    testWidgets('입력 문자 구성에 따라 강도 라벨이 약함→아주 강함으로 바뀐다', (tester) async {
      await _pumpAuthScreen(tester, const SignupScreen());

      // 비밀번호 필드(이메일 다음 = index 1)에 약한 값.
      final passwordField = find.byType(AppTextField).at(1);
      await tester.enterText(passwordField, 'abc');
      await tester.pump();
      expect(find.text('약함'), findsOneWidget);

      // 길이·문자종류를 모두 충족하는 강한 값.
      await tester.enterText(passwordField, 'Abcdef1!');
      await tester.pump();
      expect(find.text('아주 강함'), findsOneWidget);
      expect(find.text('약함'), findsNothing);

      await disposeApp(tester);
    });
  });

  group('§11.6 권한 프라이밍', () {
    testWidgets('프라이밍 화면이 제목·이유·두 버튼과 함께 렌더된다', (tester) async {
      await _pumpAuthScreen(tester, const PermissionPrimingScreen());
      // 진입 시 종 아이콘 흔들림 트리거(postFrame setState) 소진.
      await tester.pump();

      // 기록 기능 숨김(2026-09-11) — 수유·기록 약속을 뺀 문구.
      expect(find.text('중요한 안내를 놓치지 않게'), findsOneWidget);
      expect(find.textContaining('수유'), findsNothing);
      expect(find.text('알림 켜기'), findsOneWidget);
      expect(find.text('나중에'), findsOneWidget);

      await disposeApp(tester);
    });
  });
}
