import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Supabase 마스터 데이터에 대한 어드민 CRUD 래퍼.
///
/// [SupabaseClient]를 **service_role 키**로 직접 생성해 RLS를 우회한다(§4-B).
/// products 변경은 DB 트리거(bump_content_version)가 자동으로 매니페스트를 올려
/// 사용자 앱 캐시를 무효화하므로(0010), 어드민에는 무효화 로직이 없다.
class AdminApi {
  AdminApi({required String url, required String serviceKey})
    : _client = SupabaseClient(url, serviceKey);

  final SupabaseClient _client;

  static const bucket = 'product-thumbnails';

  /// 샘플 시딩용 한 줄 설명 자리표시 문구(어드민에서 교체 전제).
  static const _sampleBlurbs = <String>[
    '첫 구매로 무난한 기본형',
    '휴대하기 좋은 소용량',
    '재구매 많은 스테디셀러',
  ];

  // --- 읽기 -----------------------------------------------------------------

  /// 증상 카드 전체(order_index 순). 제품을 연결할 대상 선택용.
  Future<List<Symptom>> listSymptoms() async {
    final rows = await _client
        .from('symptoms')
        .select('id, slug, name, order_index, product_keywords')
        .order('order_index');
    return (rows as List)
        .map((e) => Symptom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 증상별 (활성 수, 전체 수). 목록 화면 배지용 — 1회 조회로 계산.
  Future<Map<String, ({int active, int total})>> productCounts() async {
    final rows = await _client.from('products').select('symptom_id, is_active');
    final map = <String, ({int active, int total})>{};
    for (final r in rows as List) {
      final m = r as Map<String, dynamic>;
      final sid = m['symptom_id'] as String?;
      if (sid == null) continue;
      final cur = map[sid] ?? (active: 0, total: 0);
      final isActive = (m['is_active'] as bool?) ?? true;
      map[sid] = (
        active: cur.active + (isActive ? 1 : 0),
        total: cur.total + 1,
      );
    }
    return map;
  }

  /// 특정 증상의 제품 전체(비활성 포함, rank_index 순).
  Future<List<Product>> listProducts(String symptomId) async {
    final rows = await _client
        .from('products')
        .select()
        .eq('symptom_id', symptomId)
        .order('rank_index')
        .order('title');
    return (rows as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- 쓰기 -----------------------------------------------------------------

  /// 제품 추가([id]==null) 또는 수정.
  ///
  /// price/rating 은 **의도적으로 다루지 않는다**(0011). 파트너스 API 승인 전까지
  /// 앱·어드민에서 가격/평점 표시를 걷어내고 [blurb](한 줄 설명)를 쓰기 때문에,
  /// payload 에서 두 컬럼을 아예 빼 수정 시 기존 값이 null 로 덮이지 않게 한다
  /// (둘 다 nullable 이라 신규 insert 도 문제없음).
  Future<Product> saveProduct({
    String? id,
    required String symptomId,
    required String coupangPid,
    required String title,
    required String deeplink,
    String? imageUrl,
    String? blurb,
    required int rankIndex,
    required bool isActive,
  }) async {
    final data = <String, dynamic>{
      'symptom_id': symptomId,
      'coupang_pid': coupangPid,
      'title': title,
      'deeplink': deeplink,
      'image_url': imageUrl,
      'blurb': blurb,
      'rank_index': rankIndex,
      'is_active': isActive,
    };
    final Map<String, dynamic> row;
    if (id == null) {
      row = await _client.from('products').insert(data).select().single();
    } else {
      row = await _client
          .from('products')
          .update(data)
          .eq('id', id)
          .select()
          .single();
    }
    return Product.fromJson(row);
  }

  /// 소프트 삭제/복원 토글(is_active).
  Future<void> setActive(String id, bool active) =>
      _client.from('products').update({'is_active': active}).eq('id', id);

  /// 하드 삭제(행 제거). 소프트 삭제를 권장하나 필요 시 사용.
  Future<void> deleteProduct(String id) =>
      _client.from('products').delete().eq('id', id);

  /// 드래그로 재배열된 순서를 rank_index 0..n 으로 일괄 반영.
  Future<void> saveOrder(List<Product> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].rankIndex == i) continue;
      await _client
          .from('products')
          .update({'rank_index': i})
          .eq('id', ordered[i].id);
    }
  }

  // --- 스토리지(썸네일) -----------------------------------------------------

  /// 공개 썸네일 버킷이 없으면 생성한다(멱등). service_role 필요.
  Future<void> ensureBucket() async {
    try {
      await _client.storage.createBucket(
        bucket,
        const BucketOptions(public: true),
      );
    } on StorageException catch (e) {
      // 이미 존재하면 무시(Duplicate). 그 외는 재전파.
      final msg = e.message.toLowerCase();
      if (!msg.contains('exist') && !msg.contains('duplicate')) rethrow;
    }
  }

  /// 이미지 바이트를 업로드하고 공개 URL을 반환한다.
  Future<String> uploadThumbnail({
    required String symptomSlug,
    required Uint8List bytes,
    required String extension,
    required int stamp,
  }) async {
    await ensureBucket();
    final ext = extension.isEmpty ? 'jpg' : extension.toLowerCase();
    final path = '$symptomSlug/$stamp.$ext';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(ext),
            upsert: true,
          ),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// 연결 확인용 — 증상 1건 조회 시도(키/URL 검증).
  Future<void> ping() async {
    await _client.from('symptoms').select('id').limit(1);
  }

  // --- 샘플 데이터 시딩 -----------------------------------------------------

  /// 각 증상 카드에 샘플 쿠팡 제품 2~3개를 upsert 한다(멱등: coupang_pid 충돌 시 갱신).
  ///
  /// - 제목/검색 딥링크는 product_keywords 로 생성(실제 파트너스 링크 아님 — 쿠팡
  ///   검색 URL. 발주자가 어드민에서 실제 파트너스 링크로 교체).
  /// - 썸네일은 임의 플레이스홀더 이미지(picsum). 어드민 업로드로 교체 가능.
  /// - 한 줄 설명(blurb)도 자리표시용 문구 — 어드민 수정 화면에서 교체한다.
  /// - coupang_pid 접두 SAMPLE- 로만 upsert 하므로 실데이터를 건드리지 않는다.
  ///
  /// 반환: upsert 시도한 제품 행 수.
  Future<int> seedSampleProducts(List<Symptom> symptoms) async {
    final rows = <Map<String, dynamic>>[];
    for (final s in symptoms) {
      final keywords = s.productKeywords.isNotEmpty
          ? s.productKeywords.take(3).toList()
          : [s.name];
      for (var i = 0; i < keywords.length; i++) {
        final kw = keywords[i];
        rows.add({
          'symptom_id': s.id,
          'coupang_pid': 'SAMPLE-${s.slug.toUpperCase()}-${i + 1}',
          'title': '[샘플] $kw',
          'deeplink':
              'https://www.coupang.com/np/search?q=${Uri.encodeComponent(kw)}',
          'image_url': 'https://picsum.photos/seed/${s.slug}$i/300/300',
          'blurb': _sampleBlurbs[i % _sampleBlurbs.length],
          'rank_index': i,
          'is_active': true,
        });
      }
    }
    if (rows.isEmpty) return 0;
    await _client
        .from('products')
        .upsert(rows, onConflict: 'symptom_id,coupang_pid');
    return rows.length;
  }
}
