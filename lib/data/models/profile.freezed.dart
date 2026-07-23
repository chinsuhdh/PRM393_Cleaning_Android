// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  bool get isPhoneVerified => throw _privateConstructorUsedError;
  int get bookingCount => throw _privateConstructorUsedError;
  int get savedCount => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call({
    String id,
    String fullName,
    String? avatarUrl,
    String? email,
    String? phoneNumber,
    bool isPhoneVerified,
    int bookingCount,
    int savedCount,
  });
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
    Object? email = freezed,
    Object? phoneNumber = freezed,
    Object? isPhoneVerified = null,
    Object? bookingCount = null,
    Object? savedCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fullName: null == fullName
                ? _value.fullName
                : fullName // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            isPhoneVerified: null == isPhoneVerified
                ? _value.isPhoneVerified
                : isPhoneVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            bookingCount: null == bookingCount
                ? _value.bookingCount
                : bookingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            savedCount: null == savedCount
                ? _value.savedCount
                : savedCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
    _$ProfileImpl value,
    $Res Function(_$ProfileImpl) then,
  ) = __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fullName,
    String? avatarUrl,
    String? email,
    String? phoneNumber,
    bool isPhoneVerified,
    int bookingCount,
    int savedCount,
  });
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
    _$ProfileImpl _value,
    $Res Function(_$ProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? avatarUrl = freezed,
    Object? email = freezed,
    Object? phoneNumber = freezed,
    Object? isPhoneVerified = null,
    Object? bookingCount = null,
    Object? savedCount = null,
  }) {
    return _then(
      _$ProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fullName: null == fullName
            ? _value.fullName
            : fullName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        isPhoneVerified: null == isPhoneVerified
            ? _value.isPhoneVerified
            : isPhoneVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        bookingCount: null == bookingCount
            ? _value.bookingCount
            : bookingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        savedCount: null == savedCount
            ? _value.savedCount
            : savedCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ProfileImpl extends _Profile {
  const _$ProfileImpl({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.email,
    this.phoneNumber,
    this.isPhoneVerified = false,
    this.bookingCount = 0,
    this.savedCount = 0,
  }) : super._();

  @override
  final String id;
  @override
  final String fullName;
  @override
  final String? avatarUrl;
  @override
  final String? email;
  @override
  final String? phoneNumber;
  @override
  @JsonKey()
  final bool isPhoneVerified;
  @override
  @JsonKey()
  final int bookingCount;
  @override
  @JsonKey()
  final int savedCount;

  @override
  String toString() {
    return 'Profile(id: $id, fullName: $fullName, avatarUrl: $avatarUrl, email: $email, phoneNumber: $phoneNumber, isPhoneVerified: $isPhoneVerified, bookingCount: $bookingCount, savedCount: $savedCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.isPhoneVerified, isPhoneVerified) ||
                other.isPhoneVerified == isPhoneVerified) &&
            (identical(other.bookingCount, bookingCount) ||
                other.bookingCount == bookingCount) &&
            (identical(other.savedCount, savedCount) ||
                other.savedCount == savedCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fullName,
    avatarUrl,
    email,
    phoneNumber,
    isPhoneVerified,
    bookingCount,
    savedCount,
  );

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);
}

abstract class _Profile extends Profile {
  const factory _Profile({
    required final String id,
    required final String fullName,
    final String? avatarUrl,
    final String? email,
    final String? phoneNumber,
    final bool isPhoneVerified,
    final int bookingCount,
    final int savedCount,
  }) = _$ProfileImpl;
  const _Profile._() : super._();

  @override
  String get id;
  @override
  String get fullName;
  @override
  String? get avatarUrl;
  @override
  String? get email;
  @override
  String? get phoneNumber;
  @override
  bool get isPhoneVerified;
  @override
  int get bookingCount;
  @override
  int get savedCount;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
