import 'package:flutter/material.dart';

import 'symptom_illustration_data.dart';

/// 증상 카드 일러스트 — [SymptomIcons](`symptom_icon.dart`)·
/// [SymptomTone](`symptom_tone.dart`)과 나란한 프레젠테이션 유틸.
///
/// DESIGN v3 §4 "몽글 클레이" — 손으로 빚은 3D 점토 오브제 스타일. 32종 전부
/// `tool/illustrations/clay/generate_clay_illustrations.py`가 한 셰이딩 엔진
/// (`clay.py`)으로 렌더한 WebP(768², 투명 배경 + 부드러운 바닥 그림자)이고,
/// 등록 키 목록은 같은 스크립트가 `symptom_illustration_data.dart`로 생성한다.
/// 그림 수정은 반드시 생성기에서 — 에셋·생성 파일 직접 편집 금지.
class SymptomIllustrations {
  const SymptomIllustrations._();

  /// [key]에 대응하는 일러스트가 등록되어 있는지.
  static bool has(String? key) =>
      key != null && symptomIllustrationKeys.contains(key);

  /// 등록된 [key]의 에셋 경로.
  static String assetOf(String key) =>
      'assets/illustrations/symptoms/$key.webp';
}

/// 등록된 증상 일러스트를 그리는 정사각 이미지.
///
/// 장식 요소이므로 시맨틱스에서 제외한다(카드의 제목/설명 텍스트가 의미 전달).
class SymptomIllustration extends StatelessWidget {
  const SymptomIllustration({
    required this.illustrationKey,
    required this.size,
    super.key,
  });

  /// [SymptomIllustrations]에 등록된 `emoji_or_icon` 키.
  final String illustrationKey;

  /// 렌더 한 변 길이(dp).
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!SymptomIllustrations.has(illustrationKey)) {
      return SizedBox.square(dimension: size);
    }
    return ClayIllustration(
      asset: SymptomIllustrations.assetOf(illustrationKey),
      size: size,
    );
  }
}

/// 클레이 일러스트 에셋 경로 모음(증상 외 장면 — 온보딩·빈 상태 등).
///
/// 전부 `generate_clay_illustrations.py`의 `SCENES`가 만든다.
class ClayScenes {
  const ClayScenes._();

  static const String _dir = 'assets/illustrations/scenes';

  /// 온보딩 1 — 우는 아가(왜 우는지 찾아요).
  static const String onboardingCry = '$_dir/onboarding_cry.webp';

  /// 온보딩 2 — 기저귀 가방 속 케어 용품.
  static const String onboardingCare = '$_dir/onboarding_care.webp';

  /// 온보딩 3 — 구름 위에서 새근새근(안심하는 밤).
  static const String onboardingSleep = '$_dir/onboarding_sleep.webp';

  /// 스플래시·앱 아이콘과 같은 아가 얼굴 — 우는 얼굴.
  static const String babyCry = '$_dir/baby_cry.webp';

  /// 스플래시 — 방긋 웃는 얼굴(우는 얼굴과 픽셀 정렬이 같다).
  static const String babySmile = '$_dir/baby_smile.webp';

  /// 빈 상태(검색 결과 없음 등) — 돋보기를 든 아가.
  static const String emptySearch = '$_dir/empty_search.webp';

  /// 빈 상태(찜 없음) — 하트를 안은 아가.
  static const String emptyHeart = '$_dir/empty_heart.webp';

  /// 오류·오프라인 — 구름 뒤에 숨은 아가.
  static const String oops = '$_dir/oops.webp';

  /// 내 정보 헤더 — 엄마와 아가.
  static const String momAndBaby = '$_dir/mom_and_baby.webp';
}

/// 클레이 에셋 한 장을 정사각으로 그린다(증상·장면 공용 진입점).
///
/// 디코드 해상도를 두 단계로 묶는다 — 작은 썸네일(≤ [_smallTier]dp)은 384px,
/// 그보다 크면 원본(768px). 레일에 32장이 떠도 메모리가 원본의 1/4로 줄고,
/// 덱 무대 ↔ 상세 머리처럼 큰 크기끼리의 Hero 비행은 같은 디코드를 재사용해
/// 비행 중 다시 디코딩하며 깜박이지 않는다.
class ClayIllustration extends StatelessWidget {
  const ClayIllustration({required this.asset, required this.size, super.key});

  final String asset;

  /// 렌더 한 변 길이(dp).
  final double size;

  static const double _smallTier = 120;

  @override
  Widget build(BuildContext context) {
    final small = size <= _smallTier;
    return ExcludeSemantics(
      // 카드 프레스 스케일/리플·스와이프 트랜스폼과 페인트를 분리한다.
      child: RepaintBoundary(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          cacheWidth: small ? 384 : null,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              SizedBox.square(dimension: size),
        ),
      ),
    );
  }
}
