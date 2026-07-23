// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workerRepositoryHash() => r'c581a223ce7a54453e41e27372f967794f262bf2';

/// See also [workerRepository].
@ProviderFor(workerRepository)
final workerRepositoryProvider = Provider<WorkerRepository>.internal(
  workerRepository,
  name: r'workerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkerRepositoryRef = ProviderRef<WorkerRepository>;
String _$workerProfileHash() => r'8ad33ca9cd10ccc1c4fe7a79ec6966b5e437d4a0';

/// See also [workerProfile].
@ProviderFor(workerProfile)
final workerProfileProvider = FutureProvider<Worker?>.internal(
  workerProfile,
  name: r'workerProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workerProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkerProfileRef = FutureProviderRef<Worker?>;
String _$workerEarningsHash() => r'734588b81f38a764a7e21e6207923625500d80c8';

/// See also [workerEarnings].
@ProviderFor(workerEarnings)
final workerEarningsProvider =
    AutoDisposeFutureProvider<List<WorkerEarning>>.internal(
      workerEarnings,
      name: r'workerEarningsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workerEarningsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkerEarningsRef = AutoDisposeFutureProviderRef<List<WorkerEarning>>;
String _$workerOnlineStatusNotifierHash() =>
    r'abc84af771813c1e4cf76b7dd3e739a97acdb638';

/// See also [WorkerOnlineStatusNotifier].
@ProviderFor(WorkerOnlineStatusNotifier)
final workerOnlineStatusNotifierProvider =
    AsyncNotifierProvider<
      WorkerOnlineStatusNotifier,
      WorkerOnlineStatus
    >.internal(
      WorkerOnlineStatusNotifier.new,
      name: r'workerOnlineStatusNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workerOnlineStatusNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WorkerOnlineStatusNotifier = AsyncNotifier<WorkerOnlineStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
