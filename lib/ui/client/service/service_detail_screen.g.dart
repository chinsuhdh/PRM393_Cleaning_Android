// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$servicesByCategoryHash() =>
    r'ac42bc6a6403b9c4652d901de20026dc82c0402c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [servicesByCategory].
@ProviderFor(servicesByCategory)
const servicesByCategoryProvider = ServicesByCategoryFamily();

/// See also [servicesByCategory].
class ServicesByCategoryFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [servicesByCategory].
  const ServicesByCategoryFamily();

  /// See also [servicesByCategory].
  ServicesByCategoryProvider call(String categoryId) {
    return ServicesByCategoryProvider(categoryId);
  }

  @override
  ServicesByCategoryProvider getProviderOverride(
    covariant ServicesByCategoryProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'servicesByCategoryProvider';
}

/// See also [servicesByCategory].
class ServicesByCategoryProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [servicesByCategory].
  ServicesByCategoryProvider(String categoryId)
    : this._internal(
        (ref) => servicesByCategory(ref as ServicesByCategoryRef, categoryId),
        from: servicesByCategoryProvider,
        name: r'servicesByCategoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$servicesByCategoryHash,
        dependencies: ServicesByCategoryFamily._dependencies,
        allTransitiveDependencies:
            ServicesByCategoryFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  ServicesByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      ServicesByCategoryRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ServicesByCategoryProvider._internal(
        (ref) => create(ref as ServicesByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _ServicesByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ServicesByCategoryProvider &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ServicesByCategoryRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _ServicesByCategoryProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with ServicesByCategoryRef {
  _ServicesByCategoryProviderElement(super.provider);

  @override
  String get categoryId => (origin as ServicesByCategoryProvider).categoryId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
