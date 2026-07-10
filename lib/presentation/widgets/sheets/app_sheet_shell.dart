import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../surfaces/paper_background.dart';

/// DESIGN v2 §4.6 표면 격 통일 — 바텀시트 공용 셸.
///
/// `paperRaised` + 상단 `BorderRadius.vertical(top: r.lg)` + e3 + 그레인(0.6배) +
/// 그래버(36×4, r.full, `lineStrong`, 상단 8dp) + 옵션 헤더(명조 `title` 22 +
/// trailing 슬롯, 아래 12dp) + 하단 SafeArea.
///
/// `showAppBottomSheet`의 `builder`가 반환하는 콘텐츠를 이 셸로 감싸 쓴다.
/// `tracking_entry_sheet`·`backup_priming_sheet` 등 수제 시트 chrome(라운드/그림자
/// 중복 구현)을 이 컴포넌트로 대체한다.
class AppSheetShell extends StatelessWidget {
  const AppSheetShell({
    required this.child,
    super.key,
    this.title,
    this.trailing,
    this.showGrabber = true,
  });

  final Widget child;

  /// 시트 헤더 제목(명조 title 22). null이면 헤더 행 자체를 생략.
  final String? title;

  /// 헤더 우측 자유 슬롯(닫기 버튼 등). [title]이 null이면 무시된다.
  final Widget? trailing;

  /// false면 상단 그래버를 생략(이미 그래버가 있는 컨테이너 안에 중첩될 때).
  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = const BorderRadius.vertical(
      top: Radius.circular(AppRadius.lg),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: radius,
        boxShadow: context.shadows.e3,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: PaperBackground(
          opacityScale: 0.6,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showGrabber)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.x8,
                        bottom: AppSpacing.x16,
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.lineStrong,
                            borderRadius: AppRadius.brFull,
                          ),
                        ),
                      ),
                    ),
                  if (title != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title!,
                            style: context.texts.title.copyWith(
                              color: colors.ink900,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x12),
                  ],
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
