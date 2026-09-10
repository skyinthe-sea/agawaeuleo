import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../admin_api.dart';
import '../models.dart';

/// 제품 추가([product]==null) / 수정 폼. 썸네일은 갤러리에서 골라 Storage에
/// 업로드하고 공개 URL을 image_url 로 저장한다. 딥링크는 쿠팡 파트너스 링크.
class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({
    required this.api,
    required this.symptom,
    required this.nextRank,
    this.product,
    super.key,
  });

  final AdminApi api;
  final Symptom symptom;
  final int nextRank;
  final Product? product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _deeplink;
  late final TextEditingController _blurb;
  late final TextEditingController _pid;
  late bool _isActive;

  /// 기존 이미지 URL(수정 시). 새로 고른 이미지가 있으면 [_pickedBytes] 우선.
  String? _imageUrl;
  Uint8List? _pickedBytes;
  String _pickedExt = 'jpg';
  bool _busy = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _deeplink = TextEditingController(text: p?.deeplink ?? '');
    _blurb = TextEditingController(text: p?.blurb ?? '');
    _pid = TextEditingController(text: p?.coupangPid ?? '');
    _isActive = p?.isActive ?? true;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _deeplink.dispose();
    _blurb.dispose();
    _pid.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dot = file.name.lastIndexOf('.');
      final ext = dot >= 0 ? file.name.substring(dot + 1) : 'jpg';
      setState(() {
        _pickedBytes = bytes;
        _pickedExt = ext;
      });
    } catch (e) {
      _snack('이미지 선택 실패: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      var imageUrl = _imageUrl;
      if (_pickedBytes != null) {
        imageUrl = await widget.api.uploadThumbnail(
          symptomSlug: widget.symptom.slug.isEmpty
              ? widget.symptom.id
              : widget.symptom.slug,
          bytes: _pickedBytes!,
          extension: _pickedExt,
          stamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
      final pid = _pid.text.trim().isEmpty
          ? 'manual-${DateTime.now().millisecondsSinceEpoch}'
          : _pid.text.trim();
      final blurb = _blurb.text.trim();
      await widget.api.saveProduct(
        id: widget.product?.id,
        symptomId: widget.symptom.id,
        coupangPid: pid,
        title: _title.text.trim(),
        deeplink: _deeplink.text.trim(),
        imageUrl: imageUrl,
        blurb: blurb.isEmpty ? null : blurb,
        // 순서는 목록 화면의 드래그 재배열이 유일한 소스 — 신규만 맨 뒤로 붙인다.
        rankIndex: widget.product?.rankIndex ?? widget.nextRank,
        isActive: _isActive,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('완전 삭제'),
        content: const Text(
          '이 제품 행을 DB에서 영구 삭제합니다.\n'
          '보통은 목록에서 노출 스위치를 꺼 “숨김(소프트 삭제)”하는 것을 권장합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await widget.api.deleteProduct(widget.product!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('삭제 실패: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '제품 수정' : '제품 추가'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: '완전 삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ThumbPicker(
                imageUrl: _imageUrl,
                pickedBytes: _pickedBytes,
                onPick: _pickImage,
                onClear: (_pickedBytes != null || _imageUrl != null)
                    ? () => setState(() {
                        _pickedBytes = null;
                        _imageUrl = null;
                      })
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: '제품명 *'),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '제품명을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deeplink,
                decoration: const InputDecoration(
                  labelText: '쿠팡 파트너스 링크 *',
                  hintText: 'https://link.coupang.com/a/XXXXX',
                ),
                keyboardType: TextInputType.url,
                validator: _validateUrl,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _blurb,
                decoration: const InputDecoration(
                  labelText: '한 줄 설명',
                  helperText: '제품 카드에 제목 아래 한 줄로 보입니다',
                ),
                maxLength: 30,
                maxLines: 1,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pid,
                decoration: const InputDecoration(
                  labelText: '쿠팡 상품ID',
                  helperText: '비우면 자동 생성',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('노출(활성)'),
                subtitle: const Text('끄면 앱에 보이지 않음(소프트 삭제)'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? '저장' : '추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateUrl(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return '쿠팡 링크를 입력하세요';
    final uri = Uri.tryParse(s);
    if (uri == null || !uri.hasScheme || !uri.host.contains('.')) {
      return '올바른 URL이 아닙니다';
    }
    if (!uri.host.contains('coupang')) {
      return '쿠팡 도메인(coupang) 링크인지 확인하세요';
    }
    return null;
  }
}

class _ThumbPicker extends StatelessWidget {
  const _ThumbPicker({
    required this.imageUrl,
    required this.pickedBytes,
    required this.onPick,
    required this.onClear,
  });

  final String? imageUrl;
  final Uint8List? pickedBytes;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (pickedBytes != null) {
      preview = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      preview = Image.network(imageUrl!, fit: BoxFit.cover);
    } else {
      preview = const Icon(
        Icons.add_a_photo_outlined,
        size: 40,
        color: Colors.black38,
      );
    }
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 120,
              height: 120,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(child: preview),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('썸네일 선택'),
              ),
              if (onClear != null)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  label: const Text('제거'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
