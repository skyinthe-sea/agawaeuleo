import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/notification_providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/notifications/notifications.dart';
import '../../widgets/animated/shake.dart';
import '../../widgets/brand/ink_halo_icon.dart';
import '../../widgets/buttons/ghost_button.dart';
import '../../widgets/buttons/primary_button.dart';

/// §11.6 권한 프라이밍(알림). **노출 시점 개정판**: 첫 실행 온보딩이 아니라 첫 기록 저장
/// 직후 1회 노출한다(노출 조건은 [NotificationPrimingPrefs] 참조 — 트리거 배선은 통합 단계).
///
/// - 종 아이콘 1회 흔들림(주의환기), 버튼 진입 스프링.
/// - "알림 켜기" → OS 권한 요청 → 허용 시 수유 리마인더 스케줄 활성.
/// - "나중에" → 스킵(설정에서 나중에 가능).
/// 어느 쪽이든 노출 사실을 기록해 다시 뜨지 않게 한다.
class PermissionPrimingScreen extends ConsumerStatefulWidget {
  const PermissionPrimingScreen({super.key});

  @override
  ConsumerState<PermissionPrimingScreen> createState() =>
      _PermissionPrimingScreenState();
}

class _PermissionPrimingScreenState
    extends ConsumerState<PermissionPrimingScreen> {
  // 값이 바뀌면 Shake가 1회 재생된다(진입 시 1회 흔들기).
  int _bellShake = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _bellShake = 1);
    });
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    await NotificationPrimingPrefs.markShown();
    if (granted) {
      // 허용 시 최근 수유 기록 기반 "다음 수유 예상" 알림을 즉시 예약.
      await ref.read(feedingReminderSchedulerProvider).rescheduleFromRecent();
      ref.invalidate(notificationPermissionStatusProvider);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _close();
  }

  Future<void> _later() async {
    await NotificationPrimingPrefs.markShown();
    if (!mounted) return;
    _close();
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget buttons = Column(
      children: [
        PrimaryButton(label: '알림 켜기', loading: _busy, onPressed: _enable),
        const SizedBox(height: AppSpacing.x12),
        GhostButton(label: '나중에', onPressed: _busy ? null : _later),
      ],
    );
    if (!reduce) {
      buttons = buttons
          .animate()
          .fadeIn(duration: AppMotion.base)
          .slideY(
            begin: 0.12,
            end: 0,
            duration: AppMotion.base,
            curve: AppMotion.spring,
          );
    }

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Shake(
                  trigger: _bellShake,
                  // DESIGN v2 §7.6.7 — 권한 프라이밍 원을 InkHaloIcon(120, animate)으로 교체.
                  child: const InkHaloIcon(
                    size: 120,
                    icon: Icons.notifications_active_rounded,
                    iconSize: 56,
                    animate: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x32),
              Text(
                '밤중에도 놓치지 않게',
                textAlign: TextAlign.center,
                style: texts.title.copyWith(color: colors.ink900),
              ),
              const SizedBox(height: AppSpacing.x12),
              Text(
                '다음 수유 예상 시각과 기록 리마인더를 알림으로 보내드려요. '
                '새벽에도 타이밍을 놓치지 않도록 도와드릴게요.',
                textAlign: TextAlign.center,
                style: texts.body.copyWith(color: colors.ink500),
              ),
              const Spacer(),
              buttons,
            ],
          ),
        ),
      ),
    );
  }
}
