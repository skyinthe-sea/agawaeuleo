import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../router/routes.dart';
import '../../widgets/animated/check_draw.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../settings/terms_doc.dart';
import 'login_screen.dart';

/// §11.4 회원가입 / 계정 연결.
///
/// 게스트(익명)로 진입한 사용자는 이메일 계정을 **연결(승격)**한다 — `user_id`가 유지되어
/// 게스트 기록·즐겨찾기가 그대로 계정 데이터가 된다. 가입 성공 시 진입했던 화면으로
/// 복귀하며 "계정이 연결됐어요" 토스트를 띄운다.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _loading = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  int _strength = 0;

  bool get _requiredAgreed => _agreeTerms && _agreePrivacy;

  /// DESIGN v2 §7.6.5 "전체 동의" 마스터 체크 상태 — 선택 항목까지 3개 모두 체크됐을 때.
  bool get _allAgreed => _agreeTerms && _agreePrivacy && _agreeMarketing;

  /// 마스터 체크 토글 — 하위 3개(필수 2 + 선택 1)를 일괄 반전한다.
  void _toggleAll() {
    final next = !_allAgreed;
    setState(() {
      _agreeTerms = next;
      _agreePrivacy = next;
      _agreeMarketing = next;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _strength = _scorePassword(value);
      if (_passwordError != null) _passwordError = null;
    });
  }

  Future<void> _submit() async {
    if (_loading || !_requiredAgreed) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    final emailError = validateAuthEmail(email);
    final passwordError = _validateNewPassword(password);
    final confirmError = password != confirm ? '비밀번호가 일치하지 않아요.' : null;
    if (emailError != null || passwordError != null || confirmError != null) {
      AppHaptics.tap();
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmError = confirmError;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _loading = true;
    });

    final auth = ref.read(authRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      // 게스트(익명)면 승격(linkEmail), 아니면 일반 회원가입.
      if (auth.isAnonymous) {
        await auth.linkEmail(email: email, password: password);
      } else {
        await auth.signUpEmail(email: email, password: password);
      }
      if (!mounted) return;
      // 진입했던 화면으로 복귀(셸 아래 유지된 origin) + 성공 토스트(§11.4).
      navigator.popUntil((route) => route.isFirst);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('계정이 연결됐어요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _emailError = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        backgroundColor: colors.paperBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.ink900),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: AuthStagger(
            children: [
              const SizedBox(height: AppSpacing.x8),
              Text('계정 만들기', style: texts.title.copyWith(color: colors.ink900)),
              const SizedBox(height: AppSpacing.x8),
              Text(
                '지금까지의 기록을 안전하게 백업해요.',
                style: texts.body.copyWith(color: colors.ink500),
              ),
              const SizedBox(height: AppSpacing.x24),
              // DESIGN v2 §7.6.3 폼 카드화 — 이메일/비밀번호/확인 필드 그룹을 raised 카드로.
              AppCard(
                emphasis: AppCardEmphasis.raised,
                padding: const EdgeInsets.all(AppSpacing.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _emailController,
                      hintText: '이메일',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_loading,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: colors.ink500,
                      ),
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.x12),
                    AppTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hintText: '비밀번호 (8자 이상)',
                      errorText: _passwordError,
                      obscure: true,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: colors.ink500,
                      ),
                      onChanged: _onPasswordChanged,
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    _StrengthBar(strength: _strength),
                    const SizedBox(height: AppSpacing.x12),
                    AppTextField(
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      hintText: '비밀번호 확인',
                      errorText: _confirmError,
                      obscure: true,
                      enabled: !_loading,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: colors.ink500,
                      ),
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) {
                        if (_confirmError != null) {
                          setState(() => _confirmError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
              // DESIGN v2 §7.6.5 약관 동의 — "전체 동의" 마스터 행 + 마스터/개별 사이·
              // 개별 행 사이 헤어라인 + 필수/선택 미니 칩.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AgreeAllRow(checked: _allAgreed, onToggle: _toggleAll),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  _AgreeRow(
                    checked: _agreeTerms,
                    required_: true,
                    onToggle: () => setState(() => _agreeTerms = !_agreeTerms),
                    label: '이용약관 동의',
                    onLink: () => context.pushNamed(
                      Routes.terms,
                      pathParameters: {RouteParams.doc: TermsDoc.terms},
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  _AgreeRow(
                    checked: _agreePrivacy,
                    required_: true,
                    onToggle: () =>
                        setState(() => _agreePrivacy = !_agreePrivacy),
                    label: '개인정보처리방침 동의',
                    onLink: () => context.pushNamed(
                      Routes.terms,
                      pathParameters: {RouteParams.doc: TermsDoc.privacy},
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.line),
                  _AgreeRow(
                    checked: _agreeMarketing,
                    required_: false,
                    onToggle: () =>
                        setState(() => _agreeMarketing = !_agreeMarketing),
                    label: '마케팅 정보 수신 동의',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x24),
              PrimaryButton(
                label: '가입하기',
                loading: _loading,
                onPressed: (_requiredAgreed && !_loading) ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.x24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 0(빈)~4(강). 길이·문자종류로 산정.
int _scorePassword(String value) {
  if (value.isEmpty) return 0;
  var score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'[a-zA-Z]').hasMatch(value)) score++;
  if (RegExp(r'\d').hasMatch(value)) score++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) score++;
  return score;
}

String? _validateNewPassword(String password) {
  if (password.isEmpty) return '비밀번호를 입력해 주세요.';
  if (password.length < 8) return '비밀번호는 8자 이상이어야 해요.';
  return null;
}

/// §11.4 비밀번호 강도 바 — width/색 트윈 180ms(약 coral → 중 amber → 강 sage).
class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  /// 0~4.
  final int strength;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    final (Color color, String labelText, double fraction) = switch (strength) {
      0 => (colors.line, '', 0.0),
      1 => (colors.coral, '약함', 0.33),
      2 => (colors.amber, '보통', 0.66),
      3 => (colors.sage, '강함', 0.85),
      _ => (colors.sage, '아주 강함', 1.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.brFull,
          child: Stack(
            children: [
              Container(height: 6, color: colors.line),
              LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  height: 6,
                  width: constraints.maxWidth * fraction,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (labelText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x4),
          Text(labelText, style: texts.caption.copyWith(color: color)),
        ],
      ],
    );
  }
}

/// §11.4/DESIGN v2 §7.6.5 약관 동의 24×24 체크박스. 체크 시 accent 배경 + CheckDraw
/// 애니메이션. "전체 동의" 마스터 행과 개별 행이 공용한다.
class _AgreeCheckbox extends StatelessWidget {
  const _AgreeCheckbox({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.toggle();
        onToggle();
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: checked ? colors.accent : Colors.transparent,
          borderRadius: AppRadius.brXs,
          border: Border.all(
            color: checked ? colors.accent : colors.lineStrong,
            width: 1.5,
          ),
        ),
        child: checked
            ? CheckDraw(size: 20, color: colors.paperRaised, trigger: checked)
            : null,
      ),
    );
  }
}

/// DESIGN v2 §7.6.5 필수/선택 미니 칩(caption, `line` 보더) — 기존 인라인 "(필수) "/
/// "(선택) " 문구를 대체한다.
class _AgreeBadge extends StatelessWidget {
  const _AgreeBadge({required this.required_});

  final bool required_;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        required_ ? '필수' : '선택',
        style: context.texts.caption.copyWith(
          color: required_ ? colors.accent : colors.ink500,
          height: 1,
        ),
      ),
    );
  }
}

/// DESIGN v2 §7.6.5 "전체 동의" 마스터 행 — 체크 시 하위 3개(필수 2 + 선택 1)를 일괄
/// 토글한다. 개별 행과 달리 배지·링크가 없다.
class _AgreeAllRow extends StatelessWidget {
  const _AgreeAllRow({required this.checked, required this.onToggle});

  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Row(
        children: [
          _AgreeCheckbox(checked: checked, onToggle: onToggle),
          const SizedBox(width: AppSpacing.x12),
          Text(
            '전체 동의',
            style: context.texts.body.copyWith(
              color: colors.ink900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// §11.4 약관 동의 개별 행. 체크 시 CheckDraw 애니메이션, 라벨 탭 시 약관 뷰어로.
/// 필수/선택은 DESIGN v2 §7.6.5 미니 칩([_AgreeBadge])으로 표시한다.
class _AgreeRow extends StatelessWidget {
  const _AgreeRow({
    required this.checked,
    required this.required_,
    required this.onToggle,
    required this.label,
    this.onLink,
  });

  final bool checked;
  final bool required_;
  final VoidCallback onToggle;
  final String label;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Row(
        children: [
          _AgreeCheckbox(checked: checked, onToggle: onToggle),
          const SizedBox(width: AppSpacing.x12),
          _AgreeBadge(required_: required_),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLink == null
                  ? () {
                      AppHaptics.toggle();
                      onToggle();
                    }
                  : () {
                      AppHaptics.tap();
                      onLink!.call();
                    },
              child: Text(
                label,
                style: texts.body.copyWith(
                  color: colors.ink700,
                  decoration: onLink == null ? null : TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
