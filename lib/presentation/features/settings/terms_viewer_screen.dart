import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../widgets/brand/ink_seal.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/dividers/brush_divider.dart';
import '../../widgets/navigation/app_app_bar.dart';
import 'terms_doc.dart';

/// §11.16 "정책/약관 탭 → 인앱 뷰어". [doc]으로 [TermsDoc.privacy]/[TermsDoc.terms]를
/// 구분해 같은 뷰어를 재사용한다.
///
/// **범위**: 본문은 현재 앱 동작(로그인 없는 게스트 전용 · 기록은 기기에 로컬 저장 ·
/// 개인정보 미수집)에 맞춘 내용이다. 서버/제휴 구성이 바뀌면(계정 연결 도입, 수집
/// 항목 추가 등) 이 문구도 함께 갱신해야 하며, 스토어 제출 전 발주자의 최종 확인을
/// 권장한다(§13.4 "개인정보처리방침·이용약관 링크"). 대가성(§13.2)·의학 면책(§13.3)
/// 문구는 앱 내 다른 표기와 동일한 원문을 사용한다. **본문은 원문 그대로 — 이 화면의
/// 변경은 컨테이너 스타일에 한정된다.**
///
/// DESIGN v3 §6 — 조항 목록을 큰 라운드 카드(`AppCard.raised`)에 담고, 섹션 제목
/// 앞 번호 배지를 주아체(§3.3 — 순번은 모노 대신 주아체 숫자)로 바꿨다. 문서 말미는
/// `InkSeal`(watermark) + 시행일로 마무리한다(유지).
class TermsViewerScreen extends StatelessWidget {
  const TermsViewerScreen({required this.doc, super.key});

  final String doc;

  static const String _effectiveDateNotice = '시행일: 2026년 7월 12일';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final title = TermsDoc.titleOf(doc);
    final sections = _sectionsFor(doc);

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppAppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: texts.title.copyWith(color: colors.ink900)),
            const SizedBox(height: AppSpacing.x4),
            Text(
              _effectiveDateNotice,
              style: texts.caption.copyWith(color: colors.ink500),
            ),
            const SizedBox(height: AppSpacing.x20),
            // DESIGN v3 §6 "cute container" — 조항 전체를 큰 라운드 카드 하나에 담는다.
            AppCard(
              emphasis: AppCardEmphasis.raised,
              padding: const EdgeInsets.all(AppSpacing.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SectionNumberBadge(number: i + 1),
                        const SizedBox(width: AppSpacing.iconTextGap),
                        Expanded(
                          child: Text(
                            _stripLeadingNumber(sections[i].heading),
                            style: texts.heading.copyWith(color: colors.ink900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    Text(
                      sections[i].body,
                      style: texts.body.copyWith(color: colors.ink700),
                    ),
                    if (i != sections.length - 1)
                      const SizedBox(height: AppSpacing.x24),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x24),
            const BrushDivider.center(),
            const SizedBox(height: AppSpacing.x24),
            Center(
              child: Column(
                children: [
                  const InkSeal.md(watermark: true),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    _effectiveDateNotice,
                    style: texts.caption.copyWith(color: colors.ink500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TermsSection> _sectionsFor(String doc) => switch (doc) {
    TermsDoc.privacy => const [
      _TermsSection(
        '1. 개인정보를 수집하지 않습니다',
        '아가왜울어는 회원가입과 로그인이 없으며, 이름·이메일·전화번호·주소처럼 '
            '개인을 식별할 수 있는 정보를 수집하지 않습니다. 서비스를 이용하기 위해 '
            '별도의 계정을 만들 필요가 없습니다.',
      ),
      _TermsSection(
        '2. 육아 기록은 기기에 저장됩니다',
        '수유·수면·기저귀 같은 육아 기록, 아기 프로필, 즐겨찾기 등 이용자가 입력한 '
            '정보는 이용자의 기기(로컬 저장소)에 저장됩니다. 로그인이 없으므로 이 기록은 '
            '이름·이메일 같은 개인을 식별하는 정보와 연결되지 않으며, 제3자에게 판매·'
            '공유되지 않습니다. 앱을 삭제하면 기기의 기록도 삭제되니, 중요한 기록은 기기 '
            '분실에 대비해 별도로 보관해 주세요.',
      ),
      _TermsSection(
        '3. 증상·제품 정보의 표시',
        '앱이 보여 주는 증상 참고정보와 육아용품 목록은 서버에서 내려받아 표시하는 '
            '공용 콘텐츠입니다. 이 정보를 불러오는 과정에서 이용자를 식별하는 개인정보는 '
            '서버로 전송되지 않습니다.',
      ),
      _TermsSection(
        '4. 외부 서비스로의 연결',
        '육아용품 추천 링크를 누르면 외부 브라우저 또는 쿠팡 앱이 열립니다. 링크 이동 '
            '이후의 정보 처리는 해당 서비스(쿠팡)의 개인정보처리방침을 따릅니다. '
            '아가왜울어는 쿠팡 파트너스 활동으로 수수료를 받습니다.',
      ),
      _TermsSection(
        '5. 앱 안정성 진단',
        '앱의 오류를 개선하기 위해, 개인을 식별할 수 없는 익명의 오류·진단 정보가 '
            '수집될 수 있습니다. 이 정보에는 이름·연락처 등 개인정보가 포함되지 않습니다.',
      ),
      _TermsSection('6. 문의', '개인정보 처리에 관한 문의는 myclick90@gmail.com 으로 연락해 주세요.'),
    ],
    TermsDoc.terms => const [
      _TermsSection('1. 목적', '본 약관은 아가왜울어(이하 ‘앱’)의 이용 조건과 절차를 정합니다.'),
      _TermsSection(
        '2. 서비스의 내용',
        '앱은 아기 증상에 대한 참고정보, 육아용품 추천, 육아 기록(트래킹) 기능을 '
            '제공합니다. 증상 정보는 의학적 진단이 아니라 일반적인 참고 목적으로 '
            '제공됩니다.',
      ),
      _TermsSection(
        '3. 로그인 없는 이용',
        '앱은 회원가입이나 로그인 없이 게스트 상태로 모든 기능을 이용할 수 있습니다. '
            '이용자가 입력한 기록은 이용자의 기기 안에만 저장됩니다.',
      ),
      _TermsSection(
        '4. 의학 정보에 관한 면책',
        '본 정보는 의학적 진단이 아니며 참고용입니다. 증상이 우려되면 소아과 전문의와 '
            '상담하세요. 발열·호흡곤란·경련 등 응급 신호가 있으면 지체 없이 병원을 '
            '방문하거나 119에 연락하세요.',
      ),
      _TermsSection(
        '5. 제휴 및 수수료 고지',
        '앱의 제품 추천 링크는 쿠팡 파트너스 활동의 일환입니다. 아가왜울어는 쿠팡 '
            '파트너스 활동으로 수수료를 받습니다.',
      ),
      _TermsSection(
        '6. 책임의 한계',
        '앱은 정보의 정확성을 위해 노력하지만, 제공된 정보의 이용으로 발생한 결과에 '
            '대해서는 관련 법령이 허용하는 범위에서 책임을 지지 않습니다. 기기에 저장된 '
            '기록은 기기 분실이나 앱 삭제 시 복구되지 않을 수 있습니다.',
      ),
      _TermsSection(
        '7. 약관 변경 및 문의',
        '약관이 변경되면 앱을 통해 공지합니다. 문의: myclick90@gmail.com',
      ),
    ],
    _ => const [_TermsSection('문서를 찾을 수 없어요', '요청하신 약관 문서가 존재하지 않습니다.')],
  };
}

/// 섹션 heading의 "N. " 접두를 제거한다 — 번호는 [_SectionNumberBadge]가 대신 보여준다.
final RegExp _leadingNumberPattern = RegExp(r'^\d+\.\s*');

String _stripLeadingNumber(String heading) =>
    heading.replaceFirst(_leadingNumberPattern, '');

/// DESIGN v3 §3.3/§6 섹션 제목 앞 번호 배지 — 22dp 원, accentWash/accent,
/// **주아체 숫자**(순번 강조는 모노 대신 `AppFontFamily.display`).
class _SectionNumberBadge extends StatelessWidget {
  const _SectionNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: context.texts.data.copyWith(
          color: colors.accent,
          fontFamily: AppFontFamily.display,
          fontFamilyFallback: AppFontFamily.displayFallback,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.heading, this.body);

  final String heading;
  final String body;
}
