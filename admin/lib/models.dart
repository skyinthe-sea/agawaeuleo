/// 증상 카드(마스터). 어드민은 읽기만 한다 — 제품을 연결할 대상 선택용.
class Symptom {
  const Symptom({
    required this.id,
    required this.slug,
    required this.name,
    required this.orderIndex,
    this.productKeywords = const [],
  });

  final String id;
  final String slug;
  final String name;
  final int orderIndex;

  /// 추천 제품 키워드(§7.1). 샘플 시딩 시 제품명/검색 딥링크 생성에 사용.
  final List<String> productKeywords;

  factory Symptom.fromJson(Map<String, dynamic> json) => Symptom(
    id: json['id'] as String,
    slug: (json['slug'] as String?) ?? '',
    name: (json['name'] as String?) ?? '(이름 없음)',
    orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    productKeywords: ((json['product_keywords'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

/// 쿠팡 추천 제품(§7.1 products). 어드민 CRUD 대상.
class Product {
  const Product({
    required this.id,
    required this.symptomId,
    required this.coupangPid,
    required this.title,
    required this.deeplink,
    this.imageUrl,
    this.blurb,
    this.price,
    this.rating,
    this.rankIndex = 0,
    this.isActive = true,
  });

  final String id;
  final String symptomId;
  final String coupangPid;
  final String title;
  final String deeplink;
  final String? imageUrl;

  /// 제품 카드 제목 아래 한 줄 설명(0011). 어드민 수동 입력 — 비면 앱에서 미표시.
  final String? blurb;
  final int? price;
  final double? rating;
  final int rankIndex;
  final bool isActive;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    symptomId: json['symptom_id'] as String,
    coupangPid: (json['coupang_pid'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    deeplink: (json['deeplink'] as String?) ?? '',
    imageUrl: json['image_url'] as String?,
    blurb: json['blurb'] as String?,
    price: (json['price'] as num?)?.toInt(),
    rating: (json['rating'] as num?)?.toDouble(),
    rankIndex: (json['rank_index'] as num?)?.toInt() ?? 0,
    isActive: (json['is_active'] as bool?) ?? true,
  );
}
