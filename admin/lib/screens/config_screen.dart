import 'package:flutter/material.dart';

import '../admin_api.dart';
import '../config_store.dart';

/// 최초 실행 접속 설정: Supabase URL + service_role 키를 입력받아 저장한다.
///
/// service_role 키는 RLS를 우회하는 강력한 키이므로 **이 기기에만** 저장되며
/// APK/깃에는 포함되지 않는다. 대시보드 → Project Settings → API → `service_role`
/// (secret) 값을 붙여넣는다.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({
    required this.store,
    required this.onConnected,
    super.key,
  });

  final ConfigStore store;
  final VoidCallback onConnected;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _url = TextEditingController(text: ConfigStore.defaultUrl);
  final _key = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _url.text.trim();
    final key = _key.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() => _error = 'URL과 service_role 키를 모두 입력하세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 키/URL 유효성 검증 — 실제 조회를 1회 시도.
      await AdminApi(url: url, serviceKey: key).ping();
      await widget.store.save(AdminConfig(url: url, serviceKey: key));
      widget.onConnected();
    } catch (e) {
      setState(() => _error = '연결 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('접속 설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '쿠팡 제품 관리 어드민',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supabase 대시보드 → Project Settings → API 에서\n'
              'Project URL 과 service_role (secret) 키를 붙여넣으세요.\n'
              '입력값은 이 기기에만 저장됩니다.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Supabase URL',
                hintText: 'https://xxxx.supabase.co',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _key,
              obscureText: _obscure,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'service_role 키 (secret)',
                helperText: 'eyJ... 로 시작하는 JWT',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _connect,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('연결'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
