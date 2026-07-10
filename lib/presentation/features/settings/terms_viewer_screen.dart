import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../widgets/brand/ink_seal.dart';
import '../../widgets/dividers/brush_divider.dart';
import '../../widgets/navigation/app_app_bar.dart';
import 'terms_doc.dart';

/// §11.16 "정책/약관 탭 → 인앱 뷰어". [doc]으로 [TermsDoc.privacy]/[TermsDoc.terms]를
/// 구분해 같은 뷰어를 재사용한다.
///
/// **범위**: 여기 있는 본문은 구조를 보여주는 자리표시자(placeholder) 초안이다.
/// §12.1-9에 따라 실제 법률 문구의 작성·최종 검수 책임은 발주자에게 있다 — 아래
/// `_sectionsFor`의 TODO 지점을 확정 텍스트로 교체해야 스토어 제출이 가능하다
/// (§13.4 "개인정보처리방침·이용약관 링크").
///
/// DESIGN v2 §7.7 — amber 하드코딩 배경을 `amberWash` 토큰으로, 섹션 제목 앞에
/// 번호 배지(20dp 원, accentWash/accent, data체)를 붙이고, 문서 말미에
/// `InkSeal`(watermark) + 시행일로 마무리한다.
class TermsViewerScreen extends StatelessWidget {
  const TermsViewerScreen({required this.doc, super.key});

  final String doc;

  static const String _effectiveDateNotice = '시행일: TODO(발주자) — 최종 확정 후 표기';

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
            const SizedBox(height: AppSpacing.x16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: colors.amberWash,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                '이 문서는 개발 단계의 임시 초안입니다. 발주자의 법률 검토를 거쳐 '
                '확정된 문구로 교체한 뒤 스토어에 제출해야 합니다(§12.1, §13.4).',
                style: texts.caption.copyWith(color: colors.ink700),
              ),
            ),
            const SizedBox(height: AppSpacing.x24),
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
              const SizedBox(height: AppSpacing.x24),
            ],
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
        '1. 수집하는 개인정보 항목',
        'TODO(발주자): 이메일, 아기 프로필(생년월일 등), '
            '트래킹 기록, 기기 식별자 등 실제 수집 항목을 확정해 채워주세요.',
      ),
      _TermsSection(
        '2. 개인정보의 수집 및 이용 목적',
        'TODO(발주자): 서비스 제공, 계정 식별, '
            '맞춤 콘텐츠 제공 등 목적을 명시해주세요.',
      ),
      _TermsSection(
        '3. 개인정보의 보유 및 이용 기간',
        'TODO(발주자): 계정 삭제 시 파기 원칙 및 '
            '법령에 따른 보존 예외를 기재해주세요(§13.4 계정 삭제 요건).',
      ),
      _TermsSection(
        '4. 이용자의 권리와 행사 방법',
        'TODO(발주자): 열람·정정·삭제·처리정지 요구권 '
            '및 설정 내 계정 삭제 경로를 안내해주세요.',
      ),
      _TermsSection(
        '5. 제3자 제공 및 위탁',
        'TODO(발주자): Supabase, 쿠팡 파트너스, 푸시(FCM) '
            '등 사용 중인 외부 서비스와 위탁 범위를 기재해주세요.',
      ),
    ],
    TermsDoc.terms => const [
      _TermsSection(
        '1. 목적',
        'TODO(발주자): 본 약관이 아가왜울어 앱 이용에 관한 조건을 '
            '규정함을 명시해주세요.',
      ),
      _TermsSection(
        '2. 서비스의 내용',
        'TODO(발주자): 증상 정보 제공(참고용, 진단 아님), '
            '육아용품 추천(쿠팡 파트너스 활동으로 수수료 수취 — §13.2), 트래킹 등 '
            '제공 기능을 기재해주세요.',
      ),
      _TermsSection(
        '3. 회원가입 및 게스트 이용',
        'TODO(발주자): 로그인 없이 이용 가능한 범위와 '
            '계정 연결 시 데이터 승계 원칙을 안내해주세요(§3.3 게스트 우선).',
      ),
      _TermsSection(
        '4. 의학 정보에 관한 면책',
        'TODO(발주자): 앱 내 증상 정보는 의학적 진단이 '
            '아니며 참고용이라는 점, 응급 시 병원 방문을 안내해주세요(§13.3).',
      ),
      _TermsSection(
        '5. 계정 해지(탈퇴)',
        'TODO(발주자): 설정 › 계정 관리에서 계정 삭제 시 '
            '데이터 파기 범위와 절차를 안내해주세요.',
      ),
    ],
    _ => const [_TermsSection('문서를 찾을 수 없어요', '요청하신 약관 문서가 존재하지 않습니다.')],
  };
}

/// 섹션 heading의 "N. " 접두를 제거한다 — 번호는 [_SectionNumberBadge]가 대신 보여준다.
final RegExp _leadingNumberPattern = RegExp(r'^\d+\.\s*');

String _stripLeadingNumber(String heading) =>
    heading.replaceFirst(_leadingNumberPattern, '');

/// DESIGN v2 §7.7 섹션 제목 앞 번호 배지 — 20dp 원, accentWash/accent, data체.
class _SectionNumberBadge extends StatelessWidget {
  const _SectionNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: context.texts.data.copyWith(color: colors.accent),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.heading, this.body);

  final String heading;
  final String body;
}
