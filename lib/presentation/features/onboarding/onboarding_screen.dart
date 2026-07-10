import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import '../../widgets/animated/tap_spring.dart';
import '../../widgets/brand/ink_seal.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'data/onboarding_prefs.dart';
import 'widgets/onboarding_page_data.dart';
import 'widgets/onboarding_page_view.dart';
import 'widgets/page_indicator.dart';

/// §11.2 온보딩(첫 실행, 3장 + 스킵).
///
/// "시작하기"(마지막 장) 또는 "건너뛰기" 모두 `onboarding.done`(§[OnboardingPrefs])을
/// 저장한 뒤 곧장 홈(게스트 진입 — 내부적으로 익명 세션 자동 생성)으로 이동한다.
/// 여기서는 회원가입/로그인을 강제하지 않는다(§2-8, §4.1).
///
/// DESIGN v2 §7.6.6 — 상단 좌측에 스텝 라벨("1 / 3") + `PaperBackground` 그레인을
/// 더하고, 마지막 장 CTA 위에 `InkSeal.sm`을 얹는다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  bool _finishing = false;

  bool get _isLast => _index == onboardingPages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// "시작하기"/"건너뛰기" 공통 종료 동작: 플래그 저장 후 홈(게스트)으로 이동.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingPrefs.markDone();
    if (!mounted) return;
    context.goNamed(Routes.home);
  }

  void _handleNext() {
    if (_isLast) {
      unawaited(_finish());
      return;
    }
    final reduce = context.reduceMotion;
    if (reduce) {
      _pageController.jumpToPage(_index + 1);
    } else {
      _pageController.animateToPage(
        _index + 1,
        duration: AppMotion.base,
        curve: AppMotion.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 상단 좌측 스텝 라벨("1 / 3") + 우측 "건너뛰기"(caption, ink.500).
              // DESIGN v2 §7.6.6 레이아웃.
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.x8,
                  left: AppSpacing.x20,
                  right: AppSpacing.x12,
                ),
                child: Row(
                  children: [
                    _StepLabel(
                      current: _index + 1,
                      total: onboardingPages.length,
                    ),
                    const Spacer(),
                    TapSpring(
                      onTap: _finishing ? null : () => unawaited(_finish()),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.x8,
                          vertical: AppSpacing.x8,
                        ),
                        child: _SkipLabel(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => OnboardingPageView(
                    data: onboardingPages[i],
                    index: i,
                    pageController: _pageController,
                  ),
                ),
              ),
              PageIndicator(count: onboardingPages.length, index: _index),
              const SizedBox(height: AppSpacing.x24),
              // DESIGN v2 §7.6.6 — 마지막 장 CTA 위 낙관(印) 스탬프.
              if (_isLast) ...[
                const Center(child: InkSeal.sm(animate: true)),
                const SizedBox(height: AppSpacing.x16),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
                child: PrimaryButton(
                  label: _isLast ? '시작하기' : '다음',
                  loading: _finishing,
                  onPressed: _finishing ? null : _handleNext,
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
            ],
          ),
        ),
      ),
    );
  }
}

/// §7.6.6 상단 좌측 스텝 라벨("1 / 3"). overline 스타일에 데이터체(모노) 숫자를 허용한다.
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
      child: Text(
        '$current / $total',
        style: context.texts.overline.copyWith(
          color: context.colors.ink500,
          fontFamily: AppFontFamily.mono,
        ),
      ),
    );
  }
}

/// "건너뛰기" 라벨. 색은 빌드 시점 테마를 그대로 읽어 별도 위젯으로 분리(가독성 목적).
class _SkipLabel extends StatelessWidget {
  const _SkipLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      '건너뛰기',
      style: context.texts.caption.copyWith(color: context.colors.ink500),
    );
  }
}
