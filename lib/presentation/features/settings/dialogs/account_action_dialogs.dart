import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// §11.16 계정 그룹 다이얼로그 골격.
///
/// **범위**: 여기 있는 두 플로우는 확인 UI만 완성한다. 실제 세션 종료/서버 계정
/// 파기 호출과 그 이후 내비게이션(홈·스플래시 이동)은 M5(계정 연결/삭제) 몫이다.
/// [SettingsScreen]/[AccountScreen] 양쪽에서 공유해 쓴다.

/// "로그아웃" 탭 → 확인 다이얼로그. 확인 시 true를 반환할 뿐, 실제 로그아웃은
/// 호출부가 TODO로 남긴 자리에서 M5가 연결한다.
Future<void> showLogoutConfirmDialog(BuildContext context) async {
  final colors = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('로그아웃 할까요?'),
      content: const Text('다시 로그인하면 연결된 기록을 이어서 볼 수 있어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('로그아웃', style: TextStyle(color: colors.coral)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // TODO(M5): ref.read(authRepositoryProvider).signOut() 호출 → 세션 종료 후
  //   게스트(익명) 세션 재부트스트랩 또는 인증 화면 이동(§11.16 동작 참고).
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('로그아웃 기능은 곧 제공될 예정이에요')));
}

/// "계정 삭제" 탭 → 2단계 확인(§11.16, 스토어 필수 요건).
/// 1단계: 삭제 결과 경고. 2단계: 재확인 문구 입력.
Future<void> showDeleteAccountConfirmFlow(BuildContext context) async {
  final colors = context.colors;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('계정을 삭제할까요?'),
      content: Text(
        '모든 기록이 삭제되고 되돌릴 수 없어요.',
        style: TextStyle(color: colors.coral),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('계속', style: TextStyle(color: colors.coral)),
        ),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteAccountReconfirmDialog(),
  );
  if (confirmed != true || !context.mounted) return;

  // TODO(M5): ref.read(authRepositoryProvider).deleteAccount() 호출(서버 계정·
  //   데이터 파기) 후 스플래시/온보딩으로 이동(§11.16, 스토어 필수 요건).
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('계정 삭제 기능은 곧 제공될 예정이에요')));
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
    final colors = context.colors;
    return AlertDialog(
      title: const Text('마지막으로 확인할게요'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계속하려면 아래에 "$_confirmWord"라고 입력해 주세요.',
            style: context.texts.body.copyWith(color: colors.ink700),
          ),
          const SizedBox(height: AppSpacing.x12),
          AppTextField(
            controller: _controller,
            hintText: _confirmWord,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) =>
                setState(() => _matches = value.trim() == _confirmWord),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text('계정 삭제', style: TextStyle(color: colors.coral)),
        ),
      ],
    );
  }
}
