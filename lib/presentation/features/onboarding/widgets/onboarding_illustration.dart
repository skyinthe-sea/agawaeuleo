import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.2 온보딩 일러스트 프레임. radius `r.xl` · 배경 `accent.wash`.
///
/// 실제 일러스트 에셋이 준비되기 전까지, 각 장의 내용을 절제된 라인 아이콘 하나로
/// 표현한다(§9.6 아이콘 원칙 — 과한 컬러 금지, 라인 스타일).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colors.accentWash,
              borderRadius: AppRadius.brXl,
            ),
            child: Center(child: Icon(icon, size: 88, color: colors.accent)),
          ),
        ),
      ),
    );
  }
}
