import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../widgets/animated/check_draw.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'login_screen.dart';

/// §11.5 비밀번호 재설정.
///
/// 이메일 입력 → "재설정 링크 보내기". 전송 성공 시 버튼→성공 카드 크로스페이드,
/// 미가입 이메일 등 에러는 흔들기 + coral caption(AppTextField 내장 동작).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final emailError = validateAuthEmail(email);
    if (emailError != null) {
      AppHaptics.tap();
      setState(() => _emailError = emailError);
      return;
    }

    setState(() {
      _emailError = null;
      _loading = true;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(email: email);
      if (!mounted) return;
      AppHaptics.complete();
      setState(() {
        _loading = false;
        _sent = true;
      });
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
          child: AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: _sent ? _buildSuccess(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return AuthStagger(
      key: const ValueKey('form'),
      children: [
        const SizedBox(height: AppSpacing.x8),
        Text('비밀번호 재설정', style: texts.title.copyWith(color: colors.ink900)),
        const SizedBox(height: AppSpacing.x8),
        Text(
          '가입한 이메일 주소를 입력하시면 재설정 링크를 보내드려요.',
          style: texts.body.copyWith(color: colors.ink500),
        ),
        const SizedBox(height: AppSpacing.x24),
        AppTextField(
          controller: _emailController,
          hintText: '이메일',
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !_loading,
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: colors.ink500,
          ),
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: AppSpacing.x24),
        PrimaryButton(
          label: '재설정 링크 보내기',
          loading: _loading,
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.x48),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colors.sageWash,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CheckDraw(size: 48, color: colors.sage, trigger: _sent),
        ),
        const SizedBox(height: AppSpacing.x24),
        Text(
          '메일함을 확인하세요',
          style: texts.title.copyWith(color: colors.ink900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.x8),
        Text(
          '${_emailController.text.trim()}(으)로 재설정 링크를 보냈어요.\n메일이 보이지 않으면 스팸함도 확인해 주세요.',
          style: texts.body.copyWith(color: colors.ink500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.x32),
        PrimaryButton(
          label: '돌아가기',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
