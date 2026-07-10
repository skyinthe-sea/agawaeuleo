import 'package:flutter/material.dart';

/// DESIGN v2 §3.4 종이 그레인. 자산 1장을 타일 반복, ink900으로 틴트.
///
/// 렌더 계약(소비처, 예: `PaperBackground`):
/// ```dart
/// DecorationImage(
///   image: AssetImage(AppTexture.grainAsset),
///   repeat: ImageRepeat.repeat,
///   opacity: AppTexture.opacityOf(brightness),
///   colorFilter: ColorFilter.mode(colors.ink900, BlendMode.srcIn),
/// )
/// ```
/// `ink900`이 모드별로 뒤집히므로 라이트=어두운 결, 다크=밝은 결이 자동으로 나온다.
/// `MediaQuery.highContrast == true`면 그레인을 표시하지 않는다(소비처 책임).
class AppTexture {
  const AppTexture._();

  static const String grainAsset = 'assets/textures/paper_grain.png';
  static const double opacityLight = 0.05;
  static const double opacityDark = 0.045;

  static double opacityOf(Brightness b) =>
      b == Brightness.dark ? opacityDark : opacityLight;
}
