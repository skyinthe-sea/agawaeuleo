import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:flutter/material.dart';

/// §3.3·§11.1 점검(maintenance) 모드 화면. 원격 `maintenance` 플래그가 켜지면 스플래시가
/// 앱 진입을 잠그고 이 화면을 노출한다. "다시 시도"로 게이트를 재조회한다(§11.17 에러 화법:
/// 사과체가 아니라 원인·해결 중심).
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({required this.onRetry, super.key, this.message});

  /// 게이트 재조회 콜백(보통 `ref.invalidate(appGateProvider)`).
  final VoidCallback onRetry;

  /// 서버가 내려준 점검 안내 문구(없으면 기본 문구).
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paperBg,
      body: SafeArea(
        child: EmptyState(
          icon: Icons.construction_rounded,
          title: '잠깐 점검 중이에요',
          message: message ?? '서비스를 정비하고 있어요 · 잠시 후 다시 시도해 주세요',
          actionLabel: '다시 시도',
          onAction: onRetry,
        ),
      ),
    );
  }
}
