import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../router/routes.dart';
import '../../widgets/brand/ink_halo_icon.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../onboarding/widgets/ink_drop_logo.dart';

/// §11.3 로그인 / 계정 연결.
///
/// **진입 맥락**: 첫 실행 관문이 아니다(설정 › 계정 연결 · 동기화 유도 시트에서 진입).
/// 익명 세션에 계정을 연결하면 게스트 시절 기록·즐겨찾기가 그대로 유지되므로 상단에
/// "지금까지의 기록은 안전하게 유지돼요" 안내를 노출한다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// 진행 중인 인증 종류(버튼별 로딩 크로스페이드 + 나머지 비활성).
enum _Pending { none, email, apple, google }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  _Pending _pending = _Pending.none;
  String? _emailError;
  String? _passwordError;

  bool get _busy => _pending != _Pending.none;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = validateAuthEmail(email);
    final passwordError = validateAuthPassword(password);
    if (emailError != null || passwordError != null) {
      AppHaptics.tap();
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _pending = _Pending.email;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInEmail(email: email, password: password);
      if (!mounted) return;
      _onAuthenticated();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = _Pending.none;
        _passwordError = error.message;
      });
    }
  }

  Future<void> _linkApple() => _social(
    _Pending.apple,
    () => ref.read(authRepositoryProvider).linkApple(),
  );

  Future<void> _linkGoogle() => _social(
    _Pending.google,
    () => ref.read(authRepositoryProvider).linkGoogle(),
  );

  Future<void> _social(_Pending which, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _pending = which);
    try {
      await action();
      if (!mounted) return;
      _onAuthenticated();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _pending = _Pending.none);
      // 사용자 취소는 조용히 무시(§11.3 소셜 시트 취소).
      if (error.code == 'canceled') return;
      showAuthError(context, error.message);
    }
  }

  void _onAuthenticated() {
    // 계정 연결(승격) 완료 → 앱으로 복귀(홈). 게스트 기록은 user_id 유지로 이어진다.
    context.go(RoutePaths.home);
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
              const Center(child: AuthLogo(size: 64)),
              const SizedBox(height: AppSpacing.x24),
              Text(
                '다시 오셨네요',
                style: texts.title.copyWith(color: colors.ink900),
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                '지금까지의 기록은 안전하게 유지돼요.',
                style: texts.body.copyWith(color: colors.ink500),
              ),
              const SizedBox(height: AppSpacing.x24),
              // DESIGN v2 §7.6.3 폼 카드화 — 이메일/비밀번호 필드 그룹을 raised 카드로.
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
                      enabled: !_busy,
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
                      hintText: '비밀번호',
                      errorText: _passwordError,
                      obscure: true,
                      enabled: !_busy,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: colors.ink500,
                      ),
                      onSubmitted: (_) => _submitEmail(),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AuthLinkText(
                        label: '비밀번호 찾기',
                        onTap: _busy
                            ? null
                            : () => context.pushNamed(Routes.resetPassword),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
              PrimaryButton(
                label: '로그인',
                loading: _pending == _Pending.email,
                onPressed: _busy ? null : _submitEmail,
              ),
              const SizedBox(height: AppSpacing.x24),
              const AuthOrDivider(),
              const SizedBox(height: AppSpacing.x24),
              SocialButton(
                label: 'Apple로 계속하기',
                leading: Icon(Icons.apple, size: 22, color: colors.ink900),
                loading: _pending == _Pending.apple,
                onPressed: _busy ? null : _linkApple,
              ),
              const SizedBox(height: AppSpacing.x12),
              SocialButton(
                label: 'Google로 계속하기',
                leading: const GoogleGlyph(),
                loading: _pending == _Pending.google,
                onPressed: _busy ? null : _linkGoogle,
              ),
              const SizedBox(height: AppSpacing.x32),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '계정이 없으신가요?',
                      style: texts.body.copyWith(color: colors.ink500),
                    ),
                    const SizedBox(width: AppSpacing.x8),
                    AuthLinkText(
                      label: '회원가입',
                      onTap: _busy
                          ? null
                          : () => context.pushNamed(Routes.signup),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 인증 화면 공용 요소. 소유 범위가 auth 스크린 3개 파일로 한정되어 별도 공용 파일을
// 두지 않고 login_screen 에 정의한 뒤 signup/reset 에서 재사용한다.
// ─────────────────────────────────────────────────────────────────────────

/// §11.3/§11.4 이메일 형식 검사. 통과 시 null, 실패 시 coral caption 문구.
String? validateAuthEmail(String email) {
  if (email.isEmpty) return '이메일을 입력해 주세요.';
  final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!pattern.hasMatch(email)) return '이메일 형식을 확인해 주세요.';
  return null;
}

/// §11.3 로그인용 비밀번호 존재 검사(강도는 회원가입에서만).
String? validateAuthPassword(String password) {
  if (password.isEmpty) return '비밀번호를 입력해 주세요.';
  return null;
}

/// 인증 오류 스낵바(사과체 금지 · 원인 중심 — §11.17).
void showAuthError(BuildContext context, String message) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.ink900,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// §10.2 진입 stagger — 자식들을 40ms 간격으로 fadeIn + slideY. reduce-motion 시 정지.
class AuthStagger extends StatelessWidget {
  const AuthStagger({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    // §10.2 요소별 40ms 간격 stagger — 각 자식을 지연을 늘려가며 fadeIn + slideY.
    const interval = Duration(milliseconds: 40);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate()
              .fadeIn(
                delay: interval * i,
                duration: AppMotion.base,
                curve: AppMotion.enter,
              )
              .slideY(
                begin: 0.04,
                end: 0,
                delay: interval * i,
                duration: AppMotion.base,
                curve: AppMotion.enter,
              ),
      ],
    );
  }
}

/// §11.3 상단 로고(작게). DESIGN v2 §7.6.2 — 스플래시와 동일한 [InkDropLogo] 브랜드
/// 마크를 [InkHaloIcon] 안에 담아 로고를 통일한다.
class AuthLogo extends StatelessWidget {
  const AuthLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return InkHaloIcon(
      size: size,
      child: InkDropLogo(size: size * 0.6),
    );
  }
}

/// "또는" 구분선(§11.3).
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: colors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
          child: Text(
            '또는',
            style: context.texts.caption.copyWith(color: colors.ink500),
          ),
        ),
        Expanded(child: Divider(height: 1, thickness: 1, color: colors.line)),
      ],
    );
  }
}

/// accent 텍스트 링크(비밀번호 찾기 · 회원가입 등).
class AuthLinkText extends StatelessWidget {
  const AuthLinkText({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.tap();
              onTap!.call();
            },
      child: Text(
        label,
        style: context.texts.caption.copyWith(
          color: onTap == null ? colors.ink300 : colors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// §11.3 소셜 버튼(Apple/Google). 높이 52 · r.sm · 보더형(line.strong) — Ghost 규격을
/// 따르되 좌측 브랜드 글리프를 위해 [leading] 슬롯을 둔다. 로딩 시 라벨→스피너 크로스페이드.
class SocialButton extends StatelessWidget {
  const SocialButton({
    required this.label,
    required this.leading,
    super.key,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null && !loading;
    final foreground = enabled ? colors.ink700 : colors.ink300;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 52,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            splashColor: colors.accentWash,
            highlightColor: Colors.transparent,
            onTap: enabled
                ? () {
                    AppHaptics.tap();
                    onPressed!.call();
                  }
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.brSm,
                border: Border.all(
                  color: enabled ? colors.lineStrong : colors.line,
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: loading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.ink700,
                            ),
                          ),
                        )
                      : Row(
                          key: const ValueKey('label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            leading,
                            const SizedBox(width: AppSpacing.iconTextGap),
                            Text(
                              label,
                              style: context.texts.label.copyWith(
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google "G" 글리프. DESIGN v2 §7.6.4 — 원형 배지(28, `paperRaised` + `line` 보더)
/// 안에 "G"로 정돈(실제 구글 로고 에셋 도입 금지 — 라이선스, 단색 ink 톤 유지).
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 28});

  /// 원형 배지의 지름(dp). 기본 28(§7.6.4).
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.paperRaised,
        shape: BoxShape.circle,
        border: Border.all(color: colors.line),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontFamily: AppFontFamily.display,
          fontFamilyFallback: AppFontFamily.displayFallback,
          // 주아체는 한 가지 굵기(§3.3) — w700을 주면 가짜 볼드가 생긴다.
          fontWeight: FontWeight.w400,
          fontSize: size * 0.5,
          height: 1,
          color: colors.ink900,
        ),
      ),
    );
  }
}
