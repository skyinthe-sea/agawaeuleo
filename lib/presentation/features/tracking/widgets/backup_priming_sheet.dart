import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/theme.dart';
import '../../../router/routes.dart';
import '../../../widgets/buttons/ghost_button.dart';
import '../../../widgets/buttons/primary_button.dart';

/// §3.3 기록 n건 도달 시 1회 노출하는 "백업 유도" 시트의 노출 조건 헬퍼.
///
/// 게스트가 기록을 [threshold]건 이상 쌓았을 때, 계정 연결(백업)을 부드럽게 권한다.
/// 강제가 아니며 **딱 1회만** 노출한다(이후 다시 뜨지 않음).
class BackupPrimingPrefs {
  const BackupPrimingPrefs._();

  /// shared_preferences 저장 키.
  static const String prefsKey = 'backup.priming.shown';

  /// 백업 유도 시트를 띄우는 기록 수 임계값(§3.3).
  static const int threshold = 5;

  /// 백업 유도 시트를 한 번이라도 노출했는지.
  static Future<bool> hasShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// 아직 노출한 적이 없어 노출 후보인지(임계값·게스트 여부는 호출부에서 판단).
  static Future<bool> shouldShow() async => !await hasShown();

  /// 노출 사실을 기록해 다시 뜨지 않게 한다.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}

/// §3.3 백업 유도 바텀시트("기록을 안전하게 백업하세요").
///
/// "계정 연결"을 누르면 로그인/계정 연결 화면([Routes.login])으로 이동하고,
/// "나중에"를 누르면 닫는다. 노출 사실 기록([BackupPrimingPrefs.markShown])은
/// 호출부에서 처리한다.
Future<void> showBackupPrimingSheet(BuildContext context) {
  final colors = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: colors.ink900.withValues(alpha: 0.32),
    builder: (sheetContext) => _BackupPrimingSheet(
      onConnect: () {
        Navigator.of(sheetContext).pop();
        // 안정적인 바깥(루트) 컨텍스트로 이동 — 시트 컨텍스트는 pop 직후 무효.
        context.pushNamed(Routes.login);
      },
      onLater: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _BackupPrimingSheet extends StatelessWidget {
  const _BackupPrimingSheet({required this.onConnect, required this.onLater});

  final VoidCallback onConnect;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Container(
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: context.shadows.e3,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x8,
            AppSpacing.screenPadding,
            AppSpacing.x20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.accentWash,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x20),
              Text(
                '기록을 안전하게 백업하세요',
                textAlign: TextAlign.center,
                style: texts.title.copyWith(color: colors.ink900),
              ),
              const SizedBox(height: AppSpacing.x12),
              Text(
                '지금까지 남긴 기록이 이 기기에만 저장돼 있어요. '
                '계정을 연결하면 기기를 바꿔도 기록이 그대로 유지돼요.',
                textAlign: TextAlign.center,
                style: texts.body.copyWith(color: colors.ink500),
              ),
              const SizedBox(height: AppSpacing.x24),
              PrimaryButton(
                label: '계정 연결',
                icon: Icons.link_rounded,
                onPressed: onConnect,
              ),
              const SizedBox(height: AppSpacing.x12),
              GhostButton(label: '나중에', onPressed: onLater),
            ],
          ),
        ),
      ),
    );
  }
}
