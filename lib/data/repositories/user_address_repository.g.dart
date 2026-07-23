// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_address_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userAddressRepositoryHash() =>
    r'399d0863f6120da1c59524154441f3d0f04a2342';

/// See also [userAddressRepository].
@ProviderFor(userAddressRepository)
final userAddressRepositoryProvider = Provider<UserAddressRepository>.internal(
  userAddressRepository,
  name: r'userAddressRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userAddressRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserAddressRepositoryRef = ProviderRef<UserAddressRepository>;
String _$savedAddressesHash() => r'7698f6a993077381d8afb8bcc67c9d41dabd073d';

/// See also [savedAddresses].
@ProviderFor(savedAddresses)
final savedAddressesProvider =
    AutoDisposeFutureProvider<List<UserAddress>>.internal(
      savedAddresses,
      name: r'savedAddressesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$savedAddressesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SavedAddressesRef = AutoDisposeFutureProviderRef<List<UserAddress>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
