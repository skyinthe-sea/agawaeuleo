import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../router/routes.dart';
import '../../widgets/animated/tap_spring.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'data/onboarding_prefs.dart';
import 'widgets/onboarding_page_data.dart';
import 'widgets/onboarding_page_view.dart';
import 'widgets/onboarding_stage.dart';
import 'widgets/page_indicator.dart';

/// §11.2 온보딩(첫 실행, 3장 + 스킵).
///
/// "시작하기"(마지막 장) 또는 "건너뛰기" 모두 `onboarding.done`(§[OnboardingPrefs])을
/// 저장한 뒤 곧장 홈(게스트 진입)으로 이동한다. 회원가입/로그인은 강제하지 않는다
/// (§2-8, §4.1).
///
/// 구성(위→아래): 인디케이터 + 건너뛰기 → 히어로 스테이지(일러스트 + 실제 UI 조각)
/// → 오버라인·제목·본문 → CTA. 스테이지는 페이지뷰 뒤에 고정된 무대라 스와이프를
/// 어디서 시작해도 되고, 모든 전환 연출이 페이지 값에 1:1로 묶여 손가락을 따라간다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  /// 가장 가까운 페이지 — 스와이프 중간(0.5)을 넘는 순간 바뀐다(CTA 라벨·햅틱).
  int _index = 0;

  /// 스크롤이 멈춰 안착한 페이지 — 장면 마이크로 인터랙션 트리거.
  int _settledIndex = 0;
  bool _finishing = false;

  bool get _isLast => _index == onboardingPages.length - 1;

  /// 글 영역에 최소로 남길 높이(오버라인 + 제목 2줄 + 본문 3줄).
  static const double _copyMinHeight = 236;

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
    if (context.reduceMotion) {
      _pageController.jumpToPage(_index + 1);
    } else {
      _pageController.animateToPage(
        _index + 1,
        duration: AppMotion.slow,
        curve: AppMotion.enter,
      );
    }
  }

  void _handlePageChanged(int i) {
    if (i == _index) return;
    unawaited(AppHaptics.toggle());
    setState(() => _index = i);
  }

  bool _handleScrollEnd(ScrollEndNotification notification) {
    final page = _pageController.hasClients ? _pageController.page : null;
    if (page != null) {
      final settled = page.round();
      if ((page - settled).abs() < 0.01 && settled != _settledIndex) {
        setState(() => _settledIndex = settled);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: PaperBackground(
        child: SafeArea(
          // 큰 글자 설정에서도 고정 무대 아래 글 영역이 넘치지 않게 상한을 둔다.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              children: [
                _TopBar(
                  controller: _pageController,
                  index: _index,
                  showSkip: !_isLast,
                  onSkip: _finishing ? null : () => unawaited(_finish()),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stageHeight =
                          (constraints.maxHeight - _copyMinHeight).clamp(
                            200.0,
                            constraints.maxWidth * 1.02,
                          );
                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: stageHeight,
                            child: OnboardingStage(
                              controller: _pageController,
                              pages: onboardingPages,
                              activeIndex: _settledIndex,
                            ),
                          ),
                          Positioned.fill(
                            child: NotificationListener<ScrollEndNotification>(
                              onNotification: _handleScrollEnd,
                              child: PageView.builder(
                                controller: _pageController,
                                // 옆 페이지를 미리 빌드 — 스와이프 첫 프레임 빌드 지연 제거.
                                allowImplicitScrolling: true,
                                itemCount: onboardingPages.length,
                                onPageChanged: _handlePageChanged,
                                itemBuilder: (context, i) => OnboardingPageView(
                                  data: onboardingPages[i],
                                  index: i,
                                  pageController: _pageController,
                                  topInset: stageHeight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x24,
                    AppSpacing.x8,
                    AppSpacing.x24,
                    AppSpacing.x16,
                  ),
                  child: PrimaryButton(
                    label: _isLast ? '시작하기' : '다음',
                    loading: _finishing,
                    onPressed: _finishing ? null : _handleNext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 바 — 좌측 인디케이터, 우측 "건너뛰기"(마지막 장에서는 CTA와 같은 동작이라 숨김).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.controller,
    required this.index,
    required this.showSkip,
    required this.onSkip,
  });

  final PageController controller;
  final int index;
  final bool showSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.x24,
          right: AppSpacing.x8,
        ),
        child: Row(
          children: [
            PageIndicator(
              controller: controller,
              count: onboardingPages.length,
              index: index,
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: showSkip ? 1 : 0,
              duration: duration,
              child: IgnorePointer(
                ignoring: !showSkip,
                child: ExcludeSemantics(
                  excluding: !showSkip,
                  child: TapSpring(
                    onTap: onSkip,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x16,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '건너뛰기',
                            style: context.texts.label.copyWith(
                              color: colors.ink500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
