import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../domain/entities/baby.dart';
import '../../widgets/buttons/ghost_button.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/navigation/app_app_bar.dart';
import 'baby_format.dart';
import 'widgets/baby_gender_segment.dart';

/// §11.14 아기 프로필 편집 화면(신규 추가/기존 편집 겸용).
///
/// 라우트가 아니라 [Navigator.push]로 여는 화면이다 — 도메인 라우트 트리
/// (§4.1)에는 "아기 편집"이 별도 등록돼 있지 않아, 목록 화면(피처 소유
/// 범위)에서 직접 push 한다. 통합 단계에서 딥링크가 필요해지면
/// `RoutePaths.babyProfileSegment` 하위에 `edit`/`new` 세그먼트를 추가할 것.
class BabyEditScreen extends ConsumerStatefulWidget {
  const BabyEditScreen({super.key, this.baby});

  /// null이면 신규 추가.
  final Baby? baby;

  @override
  ConsumerState<BabyEditScreen> createState() => _BabyEditScreenState();
}

class _BabyEditScreenState extends ConsumerState<BabyEditScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.baby?.name ?? '',
  );
  late DateTime? _birthDate = widget.baby?.birthDate;
  late BabyGender _gender = widget.baby?.gender ?? BabyGender.na;

  bool _saving = false;
  String? _nameError;

  bool get _isEdit => widget.baby != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: '생년월일 선택',
    );
    if (picked == null) return;
    AppHaptics.toggle();
    setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '이름을 입력해 주세요');
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _nameError = null;
    });

    final draft = (widget.baby ?? _blankBaby()).copyWith(
      name: name,
      birthDate: _birthDate,
      gender: _gender,
    );

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(babyRepositoryProvider);
      if (_isEdit) {
        await repo.update(draft);
      } else {
        await repo.add(draft);
      }
      AppHaptics.complete();
      if (mounted) nav.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Baby _blankBaby() =>
      Baby(id: '', userId: '', name: '', createdAt: DateTime.now());

  Future<void> _confirmDelete() async {
    final baby = widget.baby;
    if (baby == null) return;
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.paperRaised,
        title: Text(
          '${baby.name} 프로필을 삭제할까요?',
          style: context.texts.heading.copyWith(color: colors.ink900),
        ),
        content: Text(
          '이 아기의 수유·수면·기저귀 기록도 함께 삭제되고 되돌릴 수 없어요.',
          style: context.texts.body.copyWith(color: colors.ink500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('삭제', style: TextStyle(color: colors.coral)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(babyRepositoryProvider).delete(baby.id);
      if (mounted) nav.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppAppBar(title: _isEdit ? '아기 프로필 편집' : '아기 추가'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('이름', style: texts.caption.copyWith(color: colors.ink500)),
              const SizedBox(height: AppSpacing.x8),
              AppTextField(
                controller: _nameController,
                hintText: '예: 콩콩이',
                errorText: _nameError,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: AppSpacing.x20),
              Text('생년월일', style: texts.caption.copyWith(color: colors.ink500)),
              const SizedBox(height: AppSpacing.x8),
              _BirthDateField(date: _birthDate, onTap: _pickBirthDate),
              const SizedBox(height: AppSpacing.x20),
              Text('성별', style: texts.caption.copyWith(color: colors.ink500)),
              const SizedBox(height: AppSpacing.x8),
              BabyGenderSegment(
                value: _gender,
                onChanged: (g) => setState(() => _gender = g),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              PrimaryButton(label: '저장', loading: _saving, onPressed: _save),
              if (_isEdit) ...[
                const SizedBox(height: AppSpacing.x12),
                GhostButton(
                  label: '아기 프로필 삭제',
                  icon: Icons.delete_outline_rounded,
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({required this.date, required this.onTap});

  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        decoration: BoxDecoration(
          color: colors.paperCard,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: colors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: colors.ink500),
            const SizedBox(width: AppSpacing.x8),
            Text(
              date == null ? '선택 안 함' : formatBirthDate(date!),
              style: context.texts.bodyL.copyWith(
                color: date == null ? colors.ink300 : colors.ink900,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.ink300),
          ],
        ),
      ),
    );
  }
}
