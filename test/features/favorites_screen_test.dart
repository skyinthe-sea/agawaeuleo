import 'package:agawaeuleo/presentation/features/favorites/favorites_screen.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/segments/sliding_segment.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

void main() {
  testWidgets(
    'DESIGN v2 §7.4: 상단 SectionHeader(모아보기/즐겨찾기) + 공용 SlidingSegment 렌더',
    (tester) async {
      final router = await pumpBootedApp(tester);

      router.pushNamed(Routes.favorites);
      await tester.pumpAndSettle();

      // §7.4-1 SectionHeader(overline="모아보기", title="즐겨찾기"). 화면
      // 제목은 AppAppBar에도 동일 문자열이 있어 총 2곳에서 발견되어야 한다.
      expect(find.text('모아보기'), findsOneWidget);
      expect(find.text('즐겨찾기'), findsNWidgets(2));

      // §4.7/§7.4-2 세그먼트 탭이 수제 FavoriteSegmentTabs 대신 공용
      // SlidingSegment<FavoriteTab>로 통합되었다.
      expect(find.byType(SlidingSegment<FavoriteTab>), findsOneWidget);

      // 새 인메모리 DB라 즐겨찾기가 비어 있어 기본(증상) 탭은 빈 상태를 보여준다.
      expect(find.text('즐겨찾기한 증상이 없어요'), findsOneWidget);

      await disposeApp(tester);
    },
  );
}
