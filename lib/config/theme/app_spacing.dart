/// §9.3 여백 스케일(4pt 기반, dp). 값을 이름에 그대로 인코딩(x2 == 2dp).
class AppSpacing {
  const AppSpacing._();

  static const double x2 = 2;
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;

  static const List<double> scale = [2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64];

  static const double screenPadding = 20;
  static const double cardPadding = 16;
  static const double sectionGap = 24;
  static const double listItemGap = 12;
  static const double iconTextGap = 8;
}
