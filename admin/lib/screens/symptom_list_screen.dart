import 'package:flutter/material.dart';

import '../admin_api.dart';
import '../models.dart';
import 'product_list_screen.dart';

/// 증상 카드 목록. 카드를 고르면 해당 카드의 쿠팡 제품 리스트를 편집한다.
class SymptomListScreen extends StatefulWidget {
  const SymptomListScreen({
    required this.api,
    required this.onSignedOut,
    super.key,
  });

  final AdminApi api;
  final Future<void> Function() onSignedOut;

  @override
  State<SymptomListScreen> createState() => _SymptomListScreenState();
}

class _SymptomListScreenState extends State<SymptomListScreen> {
  late Future<_Data> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Data> _load() async {
    final symptoms = await widget.api.listSymptoms();
    final counts = await widget.api.productCounts();
    return _Data(symptoms, counts);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('접속 설정 초기화'),
        content: const Text('저장된 URL·키를 지우고 설정 화면으로 돌아갑니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onSignedOut();
  }

  Future<void> _seedSamples() async {
    final data = await _future;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('샘플 데이터 넣기'),
        content: Text(
          '증상 카드 ${data.symptoms.length}개 각각에 샘플 쿠팡 제품 2~3개를 넣습니다.\n'
          '· 딥링크는 쿠팡 검색 URL(임시), 썸네일은 임의 이미지입니다.\n'
          '· 여러 번 눌러도 중복되지 않습니다(덮어쓰기).\n'
          '· 이후 각 제품을 실제 파트너스 링크/이미지로 교체하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('넣기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('샘플 데이터 넣는 중…')));
    try {
      final n = await widget.api.seedSampleProducts(data.symptoms);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('샘플 제품 $n개 반영 완료')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('시딩 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('증상 카드'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'seed') _seedSamples();
              if (v == 'signout') _confirmSignOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'seed', child: Text('샘플 데이터 넣기')),
              PopupMenuItem(value: 'signout', child: Text('접속 설정 초기화')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(error: snap.error!, onRetry: _refresh);
          }
          final data = snap.data!;
          final q = _query.trim().toLowerCase();
          final items = q.isEmpty
              ? data.symptoms
              : data.symptoms
                    .where(
                      (s) =>
                          s.name.toLowerCase().contains(q) ||
                          s.slug.toLowerCase().contains(q),
                    )
                    .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '증상 이름/슬러그 검색',
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = items[i];
                    final c = data.counts[s.id];
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.slug),
                      trailing: _CountBadge(
                        active: c?.active ?? 0,
                        total: c?.total ?? 0,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProductListScreen(api: widget.api, symptom: s),
                          ),
                        );
                        _refresh();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.active, required this.total});

  final int active;
  final int total;

  @override
  Widget build(BuildContext context) {
    final hidden = total - active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: total == 0
                ? Colors.grey.shade200
                : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            total == 0 ? '없음' : '$active/$total',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '숨김 $hidden',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _Data {
  _Data(this.symptoms, this.counts);

  final List<Symptom> symptoms;
  final Map<String, ({int active, int total})> counts;
}
