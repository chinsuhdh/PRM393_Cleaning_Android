// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_booking_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$createBookingNotifierHash() =>
    r'e53b5f3e0dffd032e11cf5e1346880a3538a8484';

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

abstract class _$CreateBookingNotifier
    extends BuildlessAutoDisposeNotifier<CreateBookingState> {
  late final String serviceId;

  CreateBookingState build(String serviceId);
}

/// See also [CreateBookingNotifier].
@ProviderFor(CreateBookingNotifier)
const createBookingNotifierProvider = CreateBookingNotifierFamily();

/// See also [CreateBookingNotifier].
class CreateBookingNotifierFamily extends Family<CreateBookingState> {
  /// See also [CreateBookingNotifier].
  const CreateBookingNotifierFamily();

  /// See also [CreateBookingNotifier].
  CreateBookingNotifierProvider call(String serviceId) {
    return CreateBookingNotifierProvider(serviceId);
  }

  @override
  CreateBookingNotifierProvider getProviderOverride(
    covariant CreateBookingNotifierProvider provider,
  ) {
    return call(provider.serviceId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createBookingNotifierProvider';
}

/// See also [CreateBookingNotifier].
class CreateBookingNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          CreateBookingNotifier,
          CreateBookingState
        > {
  /// See also [CreateBookingNotifier].
  CreateBookingNotifierProvider(String serviceId)
    : this._internal(
        () => CreateBookingNotifier()..serviceId = serviceId,
        from: createBookingNotifierProvider,
        name: r'createBookingNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$createBookingNotifierHash,
        dependencies: CreateBookingNotifierFamily._dependencies,
        allTransitiveDependencies:
            CreateBookingNotifierFamily._allTransitiveDependencies,
        serviceId: serviceId,
      );

  CreateBookingNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.serviceId,
  }) : super.internal();

  final String serviceId;

  @override
  CreateBookingState runNotifierBuild(
    covariant CreateBookingNotifier notifier,
  ) {
    return notifier.build(serviceId);
  }

  @override
  Override overrideWith(CreateBookingNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CreateBookingNotifierProvider._internal(
        () => create()..serviceId = serviceId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        serviceId: serviceId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CreateBookingNotifier, CreateBookingState>
  createElement() {
    return _CreateBookingNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateBookingNotifierProvider &&
        other.serviceId == serviceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, serviceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreateBookingNotifierRef
    on AutoDisposeNotifierProviderRef<CreateBookingState> {
  /// The parameter `serviceId` of this provider.
  String get serviceId;
}

class _CreateBookingNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          CreateBookingNotifier,
          CreateBookingState
        >
    with CreateBookingNotifierRef {
  _CreateBookingNotifierProviderElement(super.provider);

  @override
  String get serviceId => (origin as CreateBookingNotifierProvider).serviceId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
