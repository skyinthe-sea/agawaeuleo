import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../surfaces/clay_sheen.dart';
import '../symptom/symptom_illustration.dart';

/// 클레이 장면 + 톤 wash 쿠션 — DESIGN v3 §4("일러스트 뒤에는 톤 wash 쿠션을 깔아
/// 무대를 만든다")·§5.5(빈/에러 상태의 클레이 장면 슬롯).
///
/// 둥근 파스텔 쿠션([wash], 좌상단 은은한 광택) 위에 [ClayIllustration]을 올린다.
/// 쿠션은 일러스트 바닥 그림자와 겹치도록 살짝 아래로 내려 앉힌다. PNG에 색을 입히거나
/// 필터를 걸지 않는다(§4). 일러스트는 장식이라 시맨틱에서 빠진다(위젯이 처리).
///
/// 에셋이 아직 없으면 [ClayIllustration]이 빈 상자로 폴백하므로 쿠션만 보인다.
class ClaySceneArt extends StatelessWidget {
  const ClaySceneArt({
    required this.asset,
    super.key,
    this.size = 140,
    this.wash,
  });

  /// 장면 에셋 경로(보통 `ClayScenes.*`).
  final String asset;

  /// 일러스트 한 변(dp). 쿠션 지름은 이 값의 0.84.
  final double size;

  /// 쿠션 색(미지정 시 `accentWash`).
  final Color? wash;

  @override
  Widget build(BuildContext context) {
    final cushionColor = wash ?? context.colors.accentWash;
    final cushion = size * 0.84;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.04,
            child: ExcludeSemantics(
              child: Container(
                width: cushion,
                height: cushion,
                decoration: BoxDecoration(
                  color: cushionColor,
                  gradient: ClaySheen.bubble(context, cushionColor),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          ClayIllustration(asset: asset, size: size),
        ],
      ),
    );
  }
}
