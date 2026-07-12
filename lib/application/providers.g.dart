// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱 전역 의존성 배선 (§5.2 레이어, §5.3 데이터 소스 원칙).
///
/// 모든 프로바이더는 `riverpod_annotation` 코드젠 스타일(function provider)이며
/// `keepAlive`로 앱 수명 동안 유지된다. **미구성 가드**: [SupabaseBootstrap]이 초기화되지
/// 않았으면(`supabaseUrl` 비어있음/오프라인) 원격 데이터소스 프로바이더가 `null`을 내고,
/// 리포지토리는 마스터 데이터를 픽스처로, 개인기록을 로컬 전용으로 처리한다.
///
/// 통합 단계 주의:
///   - `main()`은 `runApp` 이전에 `SupabaseBootstrap.ensureInitialized()`를 await 해야
///     [supabaseClientProvider]가 올바른 값을 캐시한다(프로바이더는 최초 build 시 정적
///     `isInitialized`를 읽는다).
///   - 동기화를 확실히 기동하려면 시작 시 [syncServiceProvider]를 한 번 read 한다(개인기록
///     리포지토리 프로바이더가 이미 이를 watch 하므로, 해당 리포지토리를 쓰면 자동 기동됨).
// ── 인프라 ────────────────────────────────────────────────────────────
/// 로컬 우선 저장소(Drift) 단일 인스턴스.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// 앱 전역 의존성 배선 (§5.2 레이어, §5.3 데이터 소스 원칙).
///
/// 모든 프로바이더는 `riverpod_annotation` 코드젠 스타일(function provider)이며
/// `keepAlive`로 앱 수명 동안 유지된다. **미구성 가드**: [SupabaseBootstrap]이 초기화되지
/// 않았으면(`supabaseUrl` 비어있음/오프라인) 원격 데이터소스 프로바이더가 `null`을 내고,
/// 리포지토리는 마스터 데이터를 픽스처로, 개인기록을 로컬 전용으로 처리한다.
///
/// 통합 단계 주의:
///   - `main()`은 `runApp` 이전에 `SupabaseBootstrap.ensureInitialized()`를 await 해야
///     [supabaseClientProvider]가 올바른 값을 캐시한다(프로바이더는 최초 build 시 정적
///     `isInitialized`를 읽는다).
///   - 동기화를 확실히 기동하려면 시작 시 [syncServiceProvider]를 한 번 read 한다(개인기록
///     리포지토리 프로바이더가 이미 이를 watch 하므로, 해당 리포지토리를 쓰면 자동 기동됨).
// ── 인프라 ────────────────────────────────────────────────────────────
/// 로컬 우선 저장소(Drift) 단일 인스턴스.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// 앱 전역 의존성 배선 (§5.2 레이어, §5.3 데이터 소스 원칙).
  ///
  /// 모든 프로바이더는 `riverpod_annotation` 코드젠 스타일(function provider)이며
  /// `keepAlive`로 앱 수명 동안 유지된다. **미구성 가드**: [SupabaseBootstrap]이 초기화되지
  /// 않았으면(`supabaseUrl` 비어있음/오프라인) 원격 데이터소스 프로바이더가 `null`을 내고,
  /// 리포지토리는 마스터 데이터를 픽스처로, 개인기록을 로컬 전용으로 처리한다.
  ///
  /// 통합 단계 주의:
  ///   - `main()`은 `runApp` 이전에 `SupabaseBootstrap.ensureInitialized()`를 await 해야
  ///     [supabaseClientProvider]가 올바른 값을 캐시한다(프로바이더는 최초 build 시 정적
  ///     `isInitialized`를 읽는다).
  ///   - 동기화를 확실히 기동하려면 시작 시 [syncServiceProvider]를 한 번 read 한다(개인기록
  ///     리포지토리 프로바이더가 이미 이를 watch 하므로, 해당 리포지토리를 쓰면 자동 기동됨).
  // ── 인프라 ────────────────────────────────────────────────────────────
  /// 로컬 우선 저장소(Drift) 단일 인스턴스.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// 초기화된 Supabase 클라이언트. 미구성/미초기화면 null(원격 접근 금지 신호).

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// 초기화된 Supabase 클라이언트. 미구성/미초기화면 null(원격 접근 금지 신호).

final class SupabaseClientProvider
    extends
        $FunctionalProvider<SupabaseClient?, SupabaseClient?, SupabaseClient?>
    with $Provider<SupabaseClient?> {
  /// 초기화된 Supabase 클라이언트. 미구성/미초기화면 null(원격 접근 금지 신호).
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient? create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient?>(value),
    );
  }
}

String _$supabaseClientHash() => r'46b6bd7f7a4dd1b85389fba79e69db62eda936fd';

@ProviderFor(trackingLogsDao)
final trackingLogsDaoProvider = TrackingLogsDaoProvider._();

final class TrackingLogsDaoProvider
    extends
        $FunctionalProvider<TrackingLogsDao, TrackingLogsDao, TrackingLogsDao>
    with $Provider<TrackingLogsDao> {
  TrackingLogsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingLogsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingLogsDaoHash();

  @$internal
  @override
  $ProviderElement<TrackingLogsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrackingLogsDao create(Ref ref) {
    return trackingLogsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackingLogsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackingLogsDao>(value),
    );
  }
}

String _$trackingLogsDaoHash() => r'22e304d2210674ef4db7483d4fe20c08dd918a4a';

@ProviderFor(babiesDao)
final babiesDaoProvider = BabiesDaoProvider._();

final class BabiesDaoProvider
    extends $FunctionalProvider<BabiesDao, BabiesDao, BabiesDao>
    with $Provider<BabiesDao> {
  BabiesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babiesDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babiesDaoHash();

  @$internal
  @override
  $ProviderElement<BabiesDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BabiesDao create(Ref ref) {
    return babiesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BabiesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BabiesDao>(value),
    );
  }
}

String _$babiesDaoHash() => r'68a1ba05f305dbf2a384a8d38dccb482409c3490';

@ProviderFor(favoritesDao)
final favoritesDaoProvider = FavoritesDaoProvider._();

final class FavoritesDaoProvider
    extends $FunctionalProvider<FavoritesDao, FavoritesDao, FavoritesDao>
    with $Provider<FavoritesDao> {
  FavoritesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesDaoHash();

  @$internal
  @override
  $ProviderElement<FavoritesDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FavoritesDao create(Ref ref) {
    return favoritesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesDao>(value),
    );
  }
}

String _$favoritesDaoHash() => r'309e9ef1596e1300d9c1efdb6adc7e42c701a25b';

@ProviderFor(recentSearchesDao)
final recentSearchesDaoProvider = RecentSearchesDaoProvider._();

final class RecentSearchesDaoProvider
    extends
        $FunctionalProvider<
          RecentSearchesDao,
          RecentSearchesDao,
          RecentSearchesDao
        >
    with $Provider<RecentSearchesDao> {
  RecentSearchesDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchesDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchesDaoHash();

  @$internal
  @override
  $ProviderElement<RecentSearchesDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentSearchesDao create(Ref ref) {
    return recentSearchesDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentSearchesDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentSearchesDao>(value),
    );
  }
}

String _$recentSearchesDaoHash() => r'50ee6c99d29f876ee69618d1599af4bfcb3769a7';

@ProviderFor(pendingOpsDao)
final pendingOpsDaoProvider = PendingOpsDaoProvider._();

final class PendingOpsDaoProvider
    extends $FunctionalProvider<PendingOpsDao, PendingOpsDao, PendingOpsDao>
    with $Provider<PendingOpsDao> {
  PendingOpsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingOpsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingOpsDaoHash();

  @$internal
  @override
  $ProviderElement<PendingOpsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PendingOpsDao create(Ref ref) {
    return pendingOpsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingOpsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingOpsDao>(value),
    );
  }
}

String _$pendingOpsDaoHash() => r'160a005c53297141feea5f683201173644ba7e12';

/// 로컬 우선 개인기록의 안정적 소유자 식별자(§5.3, 세션 독립).

@ProviderFor(localIdentityStore)
final localIdentityStoreProvider = LocalIdentityStoreProvider._();

/// 로컬 우선 개인기록의 안정적 소유자 식별자(§5.3, 세션 독립).

final class LocalIdentityStoreProvider
    extends
        $FunctionalProvider<
          LocalIdentityStore,
          LocalIdentityStore,
          LocalIdentityStore
        >
    with $Provider<LocalIdentityStore> {
  /// 로컬 우선 개인기록의 안정적 소유자 식별자(§5.3, 세션 독립).
  LocalIdentityStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localIdentityStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localIdentityStoreHash();

  @$internal
  @override
  $ProviderElement<LocalIdentityStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalIdentityStore create(Ref ref) {
    return localIdentityStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalIdentityStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalIdentityStore>(value),
    );
  }
}

String _$localIdentityStoreHash() =>
    r'fd20b6d2465682ce1e1c27224fa448dac5cc7d7d';

@ProviderFor(authDataSource)
final authDataSourceProvider = AuthDataSourceProvider._();

final class AuthDataSourceProvider
    extends
        $FunctionalProvider<AuthDataSource?, AuthDataSource?, AuthDataSource?>
    with $Provider<AuthDataSource?> {
  AuthDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthDataSource?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthDataSource? create(Ref ref) {
    return authDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthDataSource?>(value),
    );
  }
}

String _$authDataSourceHash() => r'7241ad2e8e1ef436a270de39c7a42fd2527fcab0';

@ProviderFor(symptomRemoteDataSource)
final symptomRemoteDataSourceProvider = SymptomRemoteDataSourceProvider._();

final class SymptomRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          SymptomRemoteDataSource?,
          SymptomRemoteDataSource?,
          SymptomRemoteDataSource?
        >
    with $Provider<SymptomRemoteDataSource?> {
  SymptomRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<SymptomRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomRemoteDataSource? create(Ref ref) {
    return symptomRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomRemoteDataSource?>(value),
    );
  }
}

String _$symptomRemoteDataSourceHash() =>
    r'f118ccf8cffaa7c81b32c50b53f88c8d4854c2fa';

@ProviderFor(symptomInfoRemoteDataSource)
final symptomInfoRemoteDataSourceProvider =
    SymptomInfoRemoteDataSourceProvider._();

final class SymptomInfoRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          SymptomInfoRemoteDataSource?,
          SymptomInfoRemoteDataSource?,
          SymptomInfoRemoteDataSource?
        >
    with $Provider<SymptomInfoRemoteDataSource?> {
  SymptomInfoRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomInfoRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomInfoRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<SymptomInfoRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomInfoRemoteDataSource? create(Ref ref) {
    return symptomInfoRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomInfoRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomInfoRemoteDataSource?>(value),
    );
  }
}

String _$symptomInfoRemoteDataSourceHash() =>
    r'fbae57d39c60a7d01cfbd6f56be7ff51f9b2f84c';

@ProviderFor(productRemoteDataSource)
final productRemoteDataSourceProvider = ProductRemoteDataSourceProvider._();

final class ProductRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ProductRemoteDataSource?,
          ProductRemoteDataSource?,
          ProductRemoteDataSource?
        >
    with $Provider<ProductRemoteDataSource?> {
  ProductRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProductRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRemoteDataSource? create(Ref ref) {
    return productRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRemoteDataSource?>(value),
    );
  }
}

String _$productRemoteDataSourceHash() =>
    r'cd0141bf131a8ff37b5cbd761e2e548b8a07285c';

@ProviderFor(contentVersionRemoteDataSource)
final contentVersionRemoteDataSourceProvider =
    ContentVersionRemoteDataSourceProvider._();

final class ContentVersionRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ContentVersionRemoteDataSource?,
          ContentVersionRemoteDataSource?,
          ContentVersionRemoteDataSource?
        >
    with $Provider<ContentVersionRemoteDataSource?> {
  ContentVersionRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentVersionRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentVersionRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ContentVersionRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentVersionRemoteDataSource? create(Ref ref) {
    return contentVersionRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentVersionRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentVersionRemoteDataSource?>(
        value,
      ),
    );
  }
}

String _$contentVersionRemoteDataSourceHash() =>
    r'a1cada273b5c0e9eaec997868ad616f23812a4e2';

@ProviderFor(appConfigRemoteDataSource)
final appConfigRemoteDataSourceProvider = AppConfigRemoteDataSourceProvider._();

final class AppConfigRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AppConfigRemoteDataSource?,
          AppConfigRemoteDataSource?,
          AppConfigRemoteDataSource?
        >
    with $Provider<AppConfigRemoteDataSource?> {
  AppConfigRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AppConfigRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppConfigRemoteDataSource? create(Ref ref) {
    return appConfigRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfigRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfigRemoteDataSource?>(value),
    );
  }
}

String _$appConfigRemoteDataSourceHash() =>
    r'8ab2a83bde96852f9e765fb14813e0ee5832f330';

@ProviderFor(babyRemoteDataSource)
final babyRemoteDataSourceProvider = BabyRemoteDataSourceProvider._();

final class BabyRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          BabyRemoteDataSource?,
          BabyRemoteDataSource?,
          BabyRemoteDataSource?
        >
    with $Provider<BabyRemoteDataSource?> {
  BabyRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babyRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babyRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<BabyRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BabyRemoteDataSource? create(Ref ref) {
    return babyRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BabyRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BabyRemoteDataSource?>(value),
    );
  }
}

String _$babyRemoteDataSourceHash() =>
    r'36df4e055f638b228d3cc2ef9cb2570eee738644';

@ProviderFor(trackingRemoteDataSource)
final trackingRemoteDataSourceProvider = TrackingRemoteDataSourceProvider._();

final class TrackingRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          TrackingRemoteDataSource?,
          TrackingRemoteDataSource?,
          TrackingRemoteDataSource?
        >
    with $Provider<TrackingRemoteDataSource?> {
  TrackingRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<TrackingRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrackingRemoteDataSource? create(Ref ref) {
    return trackingRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackingRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackingRemoteDataSource?>(value),
    );
  }
}

String _$trackingRemoteDataSourceHash() =>
    r'e1a4ccaf6852cdf2177aed921c9d0ddd5d295312';

@ProviderFor(favoriteRemoteDataSource)
final favoriteRemoteDataSourceProvider = FavoriteRemoteDataSourceProvider._();

final class FavoriteRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          FavoriteRemoteDataSource?,
          FavoriteRemoteDataSource?,
          FavoriteRemoteDataSource?
        >
    with $Provider<FavoriteRemoteDataSource?> {
  FavoriteRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<FavoriteRemoteDataSource?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRemoteDataSource? create(Ref ref) {
    return favoriteRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRemoteDataSource? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRemoteDataSource?>(value),
    );
  }
}

String _$favoriteRemoteDataSourceHash() =>
    r'7736e4ec146a065bdfd66bea929cf1d31fa99a73';

@ProviderFor(masterCacheDao)
final masterCacheDaoProvider = MasterCacheDaoProvider._();

final class MasterCacheDaoProvider
    extends $FunctionalProvider<MasterCacheDao, MasterCacheDao, MasterCacheDao>
    with $Provider<MasterCacheDao> {
  MasterCacheDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'masterCacheDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$masterCacheDaoHash();

  @$internal
  @override
  $ProviderElement<MasterCacheDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MasterCacheDao create(Ref ref) {
    return masterCacheDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MasterCacheDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MasterCacheDao>(value),
    );
  }
}

String _$masterCacheDaoHash() => r'43bda9a323c3d402e86e55cb66675773719a0e80';

@ProviderFor(symptomRepository)
final symptomRepositoryProvider = SymptomRepositoryProvider._();

final class SymptomRepositoryProvider
    extends
        $FunctionalProvider<
          SymptomRepository,
          SymptomRepository,
          SymptomRepository
        >
    with $Provider<SymptomRepository> {
  SymptomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomRepositoryHash();

  @$internal
  @override
  $ProviderElement<SymptomRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomRepository create(Ref ref) {
    return symptomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomRepository>(value),
    );
  }
}

String _$symptomRepositoryHash() => r'cdce9f6bf22de3aa75561f2dd8423a4634485a7b';

@ProviderFor(symptomInfoRepository)
final symptomInfoRepositoryProvider = SymptomInfoRepositoryProvider._();

final class SymptomInfoRepositoryProvider
    extends
        $FunctionalProvider<
          SymptomInfoRepository,
          SymptomInfoRepository,
          SymptomInfoRepository
        >
    with $Provider<SymptomInfoRepository> {
  SymptomInfoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomInfoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomInfoRepositoryHash();

  @$internal
  @override
  $ProviderElement<SymptomInfoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomInfoRepository create(Ref ref) {
    return symptomInfoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomInfoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomInfoRepository>(value),
    );
  }
}

String _$symptomInfoRepositoryHash() =>
    r'998d18744ef2c71e13345ea2b69095fc8a7ee10a';

@ProviderFor(productRepository)
final productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'25f7d2db57424f7b85a69885b8c3b256ba92aae5';

@ProviderFor(appConfigRepository)
final appConfigRepositoryProvider = AppConfigRepositoryProvider._();

final class AppConfigRepositoryProvider
    extends
        $FunctionalProvider<
          AppConfigRepository,
          AppConfigRepository,
          AppConfigRepository
        >
    with $Provider<AppConfigRepository> {
  AppConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppConfigRepository create(Ref ref) {
    return appConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfigRepository>(value),
    );
  }
}

String _$appConfigRepositoryHash() =>
    r'8a23caff9e4845be0d9d005d72a5d7e87d7e218a';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'73cb988e6eb0434482c19a41941ae3c4ead9abad';

@ProviderFor(recentSearchRepository)
final recentSearchRepositoryProvider = RecentSearchRepositoryProvider._();

final class RecentSearchRepositoryProvider
    extends
        $FunctionalProvider<
          RecentSearchRepository,
          RecentSearchRepository,
          RecentSearchRepository
        >
    with $Provider<RecentSearchRepository> {
  RecentSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSearchRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecentSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentSearchRepository create(Ref ref) {
    return recentSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentSearchRepository>(value),
    );
  }
}

String _$recentSearchRepositoryHash() =>
    r'bbde8fa66120e40ce7ed58d935784e41d12e5193';

@ProviderFor(trackingRepository)
final trackingRepositoryProvider = TrackingRepositoryProvider._();

final class TrackingRepositoryProvider
    extends
        $FunctionalProvider<
          TrackingRepository,
          TrackingRepository,
          TrackingRepository
        >
    with $Provider<TrackingRepository> {
  TrackingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackingRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrackingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrackingRepository create(Ref ref) {
    return trackingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackingRepository>(value),
    );
  }
}

String _$trackingRepositoryHash() =>
    r'0ea30cfcb03339df88a0fd310f2046874471307d';

@ProviderFor(babyRepository)
final babyRepositoryProvider = BabyRepositoryProvider._();

final class BabyRepositoryProvider
    extends $FunctionalProvider<BabyRepository, BabyRepository, BabyRepository>
    with $Provider<BabyRepository> {
  BabyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babyRepositoryHash();

  @$internal
  @override
  $ProviderElement<BabyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BabyRepository create(Ref ref) {
    return babyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BabyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BabyRepository>(value),
    );
  }
}

String _$babyRepositoryHash() => r'034b2e43e8195f27c08d65f36533809c5ffea48e';

@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider = FavoriteRepositoryProvider._();

final class FavoriteRepositoryProvider
    extends
        $FunctionalProvider<
          FavoriteRepository,
          FavoriteRepository,
          FavoriteRepository
        >
    with $Provider<FavoriteRepository> {
  FavoriteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoriteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoriteRepository create(Ref ref) {
    return favoriteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteRepository>(value),
    );
  }
}

String _$favoriteRepositoryHash() =>
    r'1b805e434773a917ddb2c86a6e794307d5fde5d7';

/// 온라인 전환/큐 변화에 따라 `pending_ops`를 Supabase로 push 한다(§5.3).
/// 미구성 시에는 리스너를 걸지 않고 로컬 전용으로 동작한다.

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

/// 온라인 전환/큐 변화에 따라 `pending_ops`를 Supabase로 push 한다(§5.3).
/// 미구성 시에는 리스너를 걸지 않고 로컬 전용으로 동작한다.

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  /// 온라인 전환/큐 변화에 따라 `pending_ops`를 Supabase로 push 한다(§5.3).
  /// 미구성 시에는 리스너를 걸지 않고 로컬 전용으로 동작한다.
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'ca9deada969118251575aacb8c29dfe764f3dd6d';

@ProviderFor(masterDataCacheService)
final masterDataCacheServiceProvider = MasterDataCacheServiceProvider._();

final class MasterDataCacheServiceProvider
    extends
        $FunctionalProvider<
          MasterDataCacheService,
          MasterDataCacheService,
          MasterDataCacheService
        >
    with $Provider<MasterDataCacheService> {
  MasterDataCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'masterDataCacheServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$masterDataCacheServiceHash();

  @$internal
  @override
  $ProviderElement<MasterDataCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MasterDataCacheService create(Ref ref) {
    return masterDataCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MasterDataCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MasterDataCacheService>(value),
    );
  }
}

String _$masterDataCacheServiceHash() =>
    r'add64a217d8f1d07a0444c7cb23ab6ba9479acf3';
