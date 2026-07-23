// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewRepositoryHash() => r'f7375eb4c2f53ec37bb366f2b87aea98c2a57213';

/// See also [reviewRepository].
@ProviderFor(reviewRepository)
final reviewRepositoryProvider = Provider<ReviewRepository>.internal(
  reviewRepository,
  name: r'reviewRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReviewRepositoryRef = ProviderRef<ReviewRepository>;
String _$bookingReviewHash() => r'76293abe550fddd86ecb06192551c94a52e83af7';

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

/// See also [bookingReview].
@ProviderFor(bookingReview)
const bookingReviewProvider = BookingReviewFamily();

/// See also [bookingReview].
class BookingReviewFamily extends Family<AsyncValue<Review?>> {
  /// See also [bookingReview].
  const BookingReviewFamily();

  /// See also [bookingReview].
  BookingReviewProvider call(({String bookingId, String workerUserId}) args) {
    return BookingReviewProvider(args);
  }

  @override
  BookingReviewProvider getProviderOverride(
    covariant BookingReviewProvider provider,
  ) {
    return call(provider.args);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookingReviewProvider';
}

/// See also [bookingReview].
class BookingReviewProvider extends AutoDisposeFutureProvider<Review?> {
  /// See also [bookingReview].
  BookingReviewProvider(({String bookingId, String workerUserId}) args)
    : this._internal(
        (ref) => bookingReview(ref as BookingReviewRef, args),
        from: bookingReviewProvider,
        name: r'bookingReviewProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookingReviewHash,
        dependencies: BookingReviewFamily._dependencies,
        allTransitiveDependencies:
            BookingReviewFamily._allTransitiveDependencies,
        args: args,
      );

  BookingReviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.args,
  }) : super.internal();

  final ({String bookingId, String workerUserId}) args;

  @override
  Override overrideWith(
    FutureOr<Review?> Function(BookingReviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingReviewProvider._internal(
        (ref) => create(ref as BookingReviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        args: args,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Review?> createElement() {
    return _BookingReviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingReviewProvider && other.args == args;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, args.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookingReviewRef on AutoDisposeFutureProviderRef<Review?> {
  /// The parameter `args` of this provider.
  ({String bookingId, String workerUserId}) get args;
}

class _BookingReviewProviderElement
    extends AutoDisposeFutureProviderElement<Review?>
    with BookingReviewRef {
  _BookingReviewProviderElement(super.provider);

  @override
  ({String bookingId, String workerUserId}) get args =>
      (origin as BookingReviewProvider).args;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
