import 'package:flutter/material.dart';

import '../admin_api.dart';
import '../models.dart';
import 'product_edit_screen.dart';

/// 한 증상 카드의 쿠팡 제품 리스트: 순서(rank) 드래그 재배열, 노출(is_active)
/// 토글, 추가/수정/삭제.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    required this.api,
    required this.symptom,
    super.key,
  });

  final AdminApi api;
  final Symptom symptom;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product>? _items;
  Object? _error;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final list = await widget.api.listProducts(widget.symptom.id);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openEditor([Product? product]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ProductEditScreen(
          api: widget.api,
          symptom: widget.symptom,
          product: product,
          nextRank: _items?.length ?? 0,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleActive(Product p, bool value) async {
    setState(() {
      final i = _items!.indexWhere((e) => e.id == p.id);
      _items![i] = Product(
        id: p.id,
        symptomId: p.symptomId,
        coupangPid: p.coupangPid,
        title: p.title,
        deeplink: p.deeplink,
        imageUrl: p.imageUrl,
        blurb: p.blurb,
        price: p.price,
        rating: p.rating,
        rankIndex: p.rankIndex,
        isActive: value,
      );
    });
    try {
      await widget.api.setActive(p.id, value);
    } catch (e) {
      if (mounted) {
        _snack('노출 변경 실패: $e');
        await _load();
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // onReorderItem: newIndex 는 oldIndex 제거를 반영한 최종 위치로 이미 보정됨.
    setState(() {
      final item = _items!.removeAt(oldIndex);
      _items!.insert(newIndex, item);
      _savingOrder = true;
    });
    try {
      await widget.api.saveOrder(_items!);
    } catch (e) {
      if (mounted) _snack('순서 저장 실패: $e');
    } finally {
      if (mounted) setState(() => _savingOrder = false);
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
        title: Text(widget.symptom.name),
        bottom: _savingOrder
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('제품 추가'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '등록된 제품이 없습니다.\n오른쪽 아래 “제품 추가”로 시작하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return Column(
      children: [
        const _OrderHint(),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            onReorderItem: _onReorder,
            itemBuilder: (context, i) {
              final p = items[i];
              // 롱프레스 드래그(발견성) + 우측 핸들 즉시 드래그, 둘 다 동작.
              return ReorderableDelayedDragStartListener(
                key: ValueKey(p.id),
                index: i,
                child: _ProductTile(
                  index: i,
                  product: p,
                  onTap: () => _openEditor(p),
                  onToggle: (v) => _toggleActive(p, v),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 목록 상단 안내 — 리스트 순서가 곧 앱 노출 순서임을 알린다.
class _OrderHint extends StatelessWidget {
  const _OrderHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.swap_vert, size: 18, color: Colors.black54),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '위에서부터 앱에 보이는 순서입니다. 길게 눌러 끌어서 바꾸세요.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.index,
    required this.product,
    required this.onTap,
    required this.onToggle,
  });

  final int index;
  final Product product;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final dim = !product.isActive;
    final blurb = product.blurb?.trim() ?? '';
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: ListTile(
        onTap: onTap,
        leading: _Thumb(url: product.imageUrl),
        title: Row(
          children: [
            // 현재 위치 번호 = 앱 노출 순서.
            Text(
              '#${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          [
            if (blurb.isNotEmpty) blurb else '설명 없음',
            if (dim) '· 숨김',
          ].join('  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: blurb.isEmpty ? Colors.black26 : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: product.isActive, onChanged: onToggle),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade200,
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.black38),
    );
    final u = url;
    if (u == null || u.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        u,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }
}
