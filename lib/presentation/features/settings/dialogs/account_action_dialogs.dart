import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers.dart';
import '../../../../config/theme/theme.dart';
import '../../../../core/error/app_exception.dart';
import '../../../router/routes.dart';
import '../../../widgets/dialogs/app_dialog_shell.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// §11.16 계정 그룹 다이얼로그. [AccountScreen]에서 [WidgetRef]를 받아 실제 세션 종료·
/// 서버 계정 파기까지 완결한다(§13.4 스토어 필수 요건).
///
/// 게스트 우선 원칙(§3.3): 로그아웃/삭제 후에는 익명 세션으로 복귀시켜 앱을 계속 쓸 수
/// 있게 한다. 미구성(데모) 환경에서는 [AuthRepository]가 로컬 신원만 다루므로 무해하게 동작.
///
/// DESIGN v2 §4.6/§7.7 — 스톡 `AlertDialog` 셸을 [AppDialogShell](destructive)로
/// 교체했다. 로직(200ms 지연 스피너, "삭제" 재입력)은 불변.
///
/// 여기서는 공용 `showAppDialog()` 헬퍼 대신 `showDialog` + `AppDialogShell`을 직접
/// 조합한다 — 이 앱은 `StatefulShellRoute`(branch별 중첩 Navigator, §app_router)를 쓰므로
/// `onPrimary`/`onSecondary`에서 팝은 반드시 `builder`가 준 `dialogContext`로 해야
/// 다이얼로그가 실제로 올라간 Navigator를 정확히 찾는다(바깥 화면의 `context`로 팝하면
/// 화면 자신이 속한 branch Navigator를 팝해버려 다이얼로그가 안 닫히고 화면이 먼저
/// 튕겨나가는 버그가 난다). `showAppDialog()`는 바깥 `context`만 캡처된 콜백을
/// 받으므로 이 위험을 그대로 안고 있다 — P2 위젯 버그로 별도 보고.
Future<void> showLogoutConfirmDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: colors.ink900.withValues(alpha: 0.32),
    builder: (dialogContext) => AppDialogShell(
      title: '로그아웃 할까요?',
      message: '다시 로그인하면 연결된 기록을 이어서 볼 수 있어요.',
      icon: Icons.logout_rounded,
      destructive: true,
      primaryLabel: '로그아웃',
      onPrimary: () => Navigator.of(dialogContext).pop(true),
      secondaryLabel: '취소',
      onSecondary: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final auth = ref.read(authRepositoryProvider);
  try {
    await auth.signOut();
    // 게스트 우선: 세션을 비운 뒤 익명으로 다시 부트스트랩(§3.3 익명 복귀).
    await auth.ensureSignedIn();
    if (!context.mounted) return;
    context.go(RoutePaths.home);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('로그아웃했어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  } on AppException catch (error) {
    if (!context.mounted) return;
    _showError(messenger, error.message);
  }
}

/// "계정 삭제" 탭 → 2단계 확인(§11.16, 스토어 필수 요건) → 서버 계정·데이터 파기 →
/// 게스트(익명) 복귀 → 스플래시.
Future<void> showDeleteAccountConfirmFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final colors = context.colors;
  final proceed = await showDialog<bool>(
    context: context,
    barrierColor: colors.ink900.withValues(alpha: 0.32),
    builder: (dialogContext) => AppDialogShell(
      title: '계정을 삭제할까요?',
      message: '모든 기록이 삭제되고 되돌릴 수 없어요.',
      icon: Icons.delete_outline_rounded,
      destructive: true,
      primaryLabel: '계속',
      onPrimary: () => Navigator.of(dialogContext).pop(true),
      secondaryLabel: '취소',
      onSecondary: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  if (proceed != true || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: colors.ink900.withValues(alpha: 0.32),
    builder: (_) => const _DeleteAccountReconfirmDialog(),
  );
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final auth = ref.read(authRepositoryProvider);
  // §10.3 200ms 미만 작업엔 스피너를 띄우지 않는다(깜빡임 방지). 200ms 지나도
  // 진행 중이면 그때 차단 다이얼로그(중복 탭 방지)를 띄운다.
  var completed = false;
  var spinnerShown = false;
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (completed || !context.mounted) return;
      spinnerShown = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );
    }),
  );
  try {
    await auth.deleteAccount();
    // 삭제 후 게스트 우선으로 익명 세션 복귀(§3.3) → 스플래시가 재분기.
    await auth.ensureSignedIn();
    completed = true;
    if (!context.mounted) return;
    if (spinnerShown) Navigator.of(context, rootNavigator: true).pop();
    context.go(RoutePaths.splash);
  } on AppException catch (error) {
    completed = true;
    if (!context.mounted) return;
    if (spinnerShown) Navigator.of(context, rootNavigator: true).pop();
    _showError(messenger, error.message);
  }
}

void _showError(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

/// 계정 삭제 2단계: "삭제"를 직접 입력해야 버튼이 활성화되는 재확인 다이얼로그.
class _DeleteAccountReconfirmDialog extends StatefulWidget {
  const _DeleteAccountReconfirmDialog();

  @override
  State<_DeleteAccountReconfirmDialog> createState() =>
      _DeleteAccountReconfirmDialogState();
}

class _DeleteAccountReconfirmDialogState
    extends State<_DeleteAccountReconfirmDialog> {
  static const String _confirmWord = '삭제';

  final TextEditingController _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이 위젯 자신이 다이얼로그 route의 콘텐츠(= builder가 반환한 트리)이므로,
    // 이 build의 [context]가 바로 다이얼로그가 실제로 올라간 Navigator의 후손이다
    // (원 코드와 동일한 안전한 팝 대상 — 위 showLogoutConfirmDialog 문서 참고).
    return AppDialogShell(
      title: '마지막으로 확인할게요',
      message: '계속하려면 아래에 "$_confirmWord"라고 입력해 주세요.',
      icon: Icons.delete_forever_rounded,
      destructive: true,
      content: AppTextField(
        controller: _controller,
        hintText: _confirmWord,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (value) =>
            setState(() => _matches = value.trim() == _confirmWord),
      ),
      primaryLabel: '계정 삭제',
      onPrimary: _matches ? () => Navigator.of(context).pop(true) : null,
      secondaryLabel: '취소',
      onSecondary: () => Navigator.of(context).pop(false),
    );
  }
}
