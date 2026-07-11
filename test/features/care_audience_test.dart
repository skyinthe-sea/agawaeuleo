import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/domain/repositories/symptom_repository.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/symptom_card.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

/// §11.7 개정(홈 2그룹) + §13.3 개정(면책 audience 분기) 검증.
///
/// mom 카드 유무에 따른 홈 그룹핑과, 상세 의학 면책 문구의 audience 분기
/// (baby 원문 바이트 불변 / mom 산부인과 안내)를 확인한다.
void main() {
  testWidgets('홈: mom 카드가 있으면 아기 돌봄/엄마 돌봄 2그룹으로 렌더한다', (tester) async {
    await pumpBootedApp(
      tester,
      overrides: [
        symptomRepositoryProvider.overrideWith(
          (ref) => _FakeSymptomRepository([
            _symptom(slug: 'colic', name: '배앓이', orderIndex: 1),
            _symptom(slug: 'fever', name: '열', orderIndex: 2),
            _symptom(
              slug: 'lochia',
              name: '오로',
              orderIndex: 26,
              audience: SymptomAudience.mom,
            ),
          ]),
        ),
      ],
    );

    expect(find.text('아기 돌봄'), findsOneWidget);
    expect(find.text('엄마 돌봄'), findsOneWidget);
    expect(find.byType(SectionHeader), findsNWidgets(2));
    expect(find.byType(SymptomCard), findsNWidgets(3));
    expect(find.text('오로'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('홈: mom 카드가 없으면 그룹 헤더 없이 기존 단일 그리드', (tester) async {
    await pumpBootedApp(
      tester,
      overrides: [
        symptomRepositoryProvider.overrideWith(
          (ref) => _FakeSymptomRepository([
            _symptom(slug: 'colic', name: '배앓이', orderIndex: 1),
            _symptom(slug: 'fever', name: '열', orderIndex: 2),
          ]),
        ),
      ],
    );

    expect(find.text('아기 돌봄'), findsNothing);
    expect(find.text('엄마 돌봄'), findsNothing);
    expect(find.byType(SectionHeader), findsNothing);
    expect(find.byType(SymptomCard), findsNWidgets(2));

    await disposeApp(tester);
  });

  testWidgets('상세 면책: baby 카드는 기존 문구 바이트 불변(소아과 안내)', (tester) async {
    final router = await pumpBootedApp(tester);

    router.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: 'colic'},
    );
    await tester.pumpAndSettle();

    expect(
      find.text('본 정보는 의학적 진단이 아니며 참고용입니다. 증상이 우려되면 소아과 전문의와 상담하세요.'),
      findsOneWidget,
    );

    await disposeApp(tester);
  });

  testWidgets('상세 면책: mom 카드는 산부인과 의료진 안내로 분기한다', (tester) async {
    final router = await pumpBootedApp(
      tester,
      overrides: [
        symptomRepositoryProvider.overrideWith(
          (ref) => _FakeSymptomRepository([
            _symptom(
              slug: 'lochia',
              name: '오로',
              orderIndex: 26,
              audience: SymptomAudience.mom,
            ),
          ]),
        ),
      ],
    );

    router.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: 'lochia'},
    );
    await tester.pumpAndSettle();

    expect(
      find.text('본 정보는 의학적 진단이 아니며 참고용입니다. 증상이 우려되면 산부인과 전문의 등 의료진과 상담하세요.'),
      findsOneWidget,
    );

    await disposeApp(tester);
  });
}

Symptom _symptom({
  required String slug,
  required String name,
  required int orderIndex,
  SymptomAudience audience = SymptomAudience.baby,
}) => Symptom(
  id: 'test-symptom-$slug',
  slug: slug,
  name: name,
  chosung: 'ㅌㅅㅌ',
  orderIndex: orderIndex,
  audience: audience,
  createdAt: DateTime.utc(2026),
);

/// 홈/상세가 쓰는 최소 동작의 테스트 더블(고정 목록, order_index 순 가정).
class _FakeSymptomRepository implements SymptomRepository {
  _FakeSymptomRepository(this._symptoms);

  final List<Symptom> _symptoms;

  @override
  Stream<List<Symptom>> watchAll() => Stream.value(_symptoms);

  @override
  Future<List<Symptom>> getAll() async => _symptoms;

  @override
  Future<Symptom?> getById(String id) async => _firstWhere((s) => s.id == id);

  @override
  Future<Symptom?> getBySlug(String slug) async =>
      _firstWhere((s) => s.slug == slug);

  @override
  Future<List<Symptom>> search(String query) async => _symptoms;

  Symptom? _firstWhere(bool Function(Symptom) test) {
    for (final s in _symptoms) {
      if (test(s)) return s;
    }
    return null;
  }
}
