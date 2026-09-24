import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/buttons/ghost_button.dart';
import 'package:agawaeuleo/presentation/widgets/buttons/primary_button.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/stage/paper_blob_painter.dart';
import 'package:agawaeuleo/presentation/widgets/states/clay_scene_art.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/offline_banner.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// DESIGN v3 "몽글 클레이" 공용 컴포넌트 계약 스모크.
void main() {
  /// [label] 버튼의 알약 면(AnimatedContainer) 데코레이션.
  BoxDecoration pillOf(WidgetTester tester, String label) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  group('PrimaryButton', () {
    testWidgets('accentFill 면에 클레이 광택(세로 2색)과 알약 라디우스를 입힌다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        PrimaryButton(label: '확인', onPressed: () {}),
      );

      final deco = pillOf(tester, '확인');
      expect(deco.borderRadius, AppRadius.brFull);
      final gradient = deco.gradient! as LinearGradient;
      expect(gradient.colors.last, AppColors.light.accentFill);
      expect(deco.boxShadow, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tone을 주면 그 색이 면이 된다(파괴 동작의 coral 등)', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        PrimaryButton(
          label: '삭제',
          onPressed: () {},
          tone: AppColors.light.coral,
        ),
      );

      final gradient = pillOf(tester, '삭제').gradient! as LinearGradient;
      expect(gradient.colors.last, AppColors.light.coral);
    });

    testWidgets('비활성은 ink300 무광(그라데이션·그림자 없음)', (tester) async {
      await pumpWidgetWithTheme(tester, const PrimaryButton(label: '저장'));

      final deco = pillOf(tester, '저장');
      expect(deco.color, AppColors.light.ink300);
      expect(deco.gradient, isNull);
      expect(deco.boxShadow, isEmpty);
    });

    testWidgets('expand: false면 글자 폭에 맞춘 작은 알약이 된다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        Column(
          children: [
            PrimaryButton(label: '다시 시도', expand: false, onPressed: () {}),
          ],
        ),
      );

      final width = tester.getSize(find.byType(PrimaryButton)).width;
      final screen = tester.getSize(find.byType(Scaffold)).width;
      expect(width, lessThan(screen / 2));
      expect(width, greaterThan(PrimaryButton.height));
    });
  });

  testWidgets('GhostButton은 paperRaised 면 + lineStrong 1.5 윤곽의 알약이다', (
    tester,
  ) async {
    await pumpWidgetWithTheme(
      tester,
      GhostButton(label: '나중에', onPressed: () {}),
    );

    final deco = pillOf(tester, '나중에');
    expect(deco.color, AppColors.light.paperRaised);
    expect(deco.borderRadius, AppRadius.brFull);
    final border = deco.border! as Border;
    expect(border.top.color, AppColors.light.lineStrong);
    expect(border.top.width, 1.5);
  });

  group('AppCard', () {
    BoxDecoration surfaceOf(WidgetTester tester, String label) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    testWidgets('flat은 라이트에서 윤곽 없이 lg 라디우스 + e1이다', (tester) async {
      await pumpWidgetWithTheme(tester, const AppCard(child: Text('flat')));

      final deco = surfaceOf(tester, 'flat');
      expect(deco.border, isNull);
      expect(deco.borderRadius, AppRadius.brLg);
      expect(deco.boxShadow, AppShadows.light.e1);
    });

    testWidgets('다크에서는 line 1px 윤곽이 면을 받친다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        const AppCard(child: Text('dark')),
        dark: true,
      );

      expect(surfaceOf(tester, 'dark').border, isNotNull);
    });

    testWidgets('showBorder: true면 모드와 무관하게 윤곽을 그린다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        const AppCard(showBorder: true, child: Text('border')),
      );

      expect(surfaceOf(tester, 'border').border, isNotNull);
    });

    testWidgets('hero 아랫장은 stackColor(기본 accentWash) 파스텔로 칠한다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        Column(
          children: [
            const AppCard(emphasis: AppCardEmphasis.hero, child: Text('a')),
            AppCard(
              emphasis: AppCardEmphasis.hero,
              stackColor: AppColors.light.amberWash,
              child: const Text('b'),
            ),
          ],
        ),
      );

      final stackColors = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Positioned),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).color)
          .toList();
      expect(stackColors, contains(AppColors.light.accentWash));
      expect(stackColors, contains(AppColors.light.amberWash));
    });
  });

  group('상태 위젯', () {
    testWidgets('EmptyState illustrationAsset은 아이콘 버블 대신 클레이 장면을 그린다', (
      tester,
    ) async {
      await pumpWidgetWithTheme(
        tester,
        const EmptyState(
          title: '아직 비어 있어요',
          illustrationAsset: 'assets/illustrations/scenes/empty_heart.webp',
        ),
        reduceMotion: true,
      );

      expect(find.byType(ClaySceneArt), findsOneWidget);
      expect(find.byType(InkHaloIcon), findsNothing);
      expect(find.text('아직 비어 있어요'), findsOneWidget);
    });

    testWidgets('EmptyState 기본은 클레이 버블(InkHaloIcon)을 유지한다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        const EmptyState(title: '비어 있어요'),
        reduceMotion: true,
      );

      expect(find.byType(InkHaloIcon), findsOneWidget);
      expect(find.byType(ClaySceneArt), findsNothing);
    });

    testWidgets('ErrorState illustrationAsset도 클레이 장면으로 바뀐다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        ErrorState(
          onRetry: () {},
          illustrationAsset: 'assets/illustrations/scenes/oops.webp',
        ),
        reduceMotion: true,
      );

      expect(find.byType(ClaySceneArt), findsOneWidget);
      expect(find.byType(InkHaloIcon), findsNothing);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('OfflineBanner는 visible일 때만 알약 배너를 보인다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        const OfflineBanner(visible: true, message: '오프라인'),
        reduceMotion: true,
      );
      expect(find.text('오프라인'), findsOneWidget);

      await pumpWidgetWithTheme(
        tester,
        const OfflineBanner(visible: false, message: '오프라인'),
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('오프라인'), findsNothing);
    });
  });

  testWidgets('스켈레톤 셸·블록은 예외 없이 렌더된다(paperStack 블록)', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const SizedBox(
        width: 320,
        child: Column(
          children: [
            SymptomCardSkeleton(),
            ProductCardSkeleton(),
            ListItemSkeleton(),
          ],
        ),
      ),
      reduceMotion: true,
    );

    expect(find.byType(SkeletonLine), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('StickerChip은 라벨을 한 줄 알약으로 그린다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const StickerChip(label: 'BEST', icon: Icons.favorite_rounded),
    );

    expect(find.text('BEST'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  group('PaperBlobPainter', () {
    testWidgets('하트·반짝이·동그라미 행성과 점선 궤도가 예외 없이 그려진다', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        SizedBox(
          width: 340,
          height: 380,
          child: CustomPaint(
            painter: PaperBlobPainter(
              page: 0.4,
              breath: 0.2,
              washes: [AppColors.light.accentWash, AppColors.light.sageWash],
              under: AppColors.light.paperStack,
              orbit: AppColors.light.lineStrong,
              rim: AppColors.light.paperBg,
              planets: [
                AppColors.light.seal,
                AppColors.light.amber,
                AppColors.light.accent,
              ],
              orbitProgress: 0.6,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('하트·반짝이 경로는 중심 둘레의 결정적 크기다', () {
      const c = Offset(50, 50);
      final heart = PaperBlobPainter.heartPath(c, 10).getBounds();
      expect(heart.width, closeTo(20, 0.5));
      expect(heart.center.dx, closeTo(50, 0.5));

      final sparkle = PaperBlobPainter.sparklePath(c, 10).getBounds();
      expect(sparkle.width, closeTo(20, 0.5));
      expect(sparkle.height, closeTo(20, 0.5));
    });

    test('모양 목록이 바뀌면 다시 그린다', () {
      final colors = [AppColors.light.seal];
      PaperBlobPainter painter(List<BlobPlanetShape> shapes) =>
          PaperBlobPainter(
            page: 0,
            breath: 0,
            washes: colors,
            under: AppColors.light.paperStack,
            orbit: AppColors.light.lineStrong,
            rim: AppColors.light.paperBg,
            planets: colors,
            planetShapes: shapes,
          );

      expect(
        painter(const [
          BlobPlanetShape.dot,
        ]).shouldRepaint(painter(const [BlobPlanetShape.heart])),
        isTrue,
      );
      expect(
        painter(const [
          BlobPlanetShape.dot,
        ]).shouldRepaint(painter(const [BlobPlanetShape.dot])),
        isFalse,
      );
    });
  });
}
