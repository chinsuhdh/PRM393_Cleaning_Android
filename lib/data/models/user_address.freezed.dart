// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserAddress {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get addressText => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;

  /// Create a copy of UserAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAddressCopyWith<UserAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAddressCopyWith<$Res> {
  factory $UserAddressCopyWith(
    UserAddress value,
    $Res Function(UserAddress) then,
  ) = _$UserAddressCopyWithImpl<$Res, UserAddress>;
  @useResult
  $Res call({
    String id,
    String label,
    String addressText,
    double? latitude,
    double? longitude,
    bool isDefault,
  });
}

/// @nodoc
class _$UserAddressCopyWithImpl<$Res, $Val extends UserAddress>
    implements $UserAddressCopyWith<$Res> {
  _$UserAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? addressText = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? isDefault = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            addressText: null == addressText
                ? _value.addressText
                : addressText // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserAddressImplCopyWith<$Res>
    implements $UserAddressCopyWith<$Res> {
  factory _$$UserAddressImplCopyWith(
    _$UserAddressImpl value,
    $Res Function(_$UserAddressImpl) then,
  ) = __$$UserAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String label,
    String addressText,
    double? latitude,
    double? longitude,
    bool isDefault,
  });
}

/// @nodoc
class __$$UserAddressImplCopyWithImpl<$Res>
    extends _$UserAddressCopyWithImpl<$Res, _$UserAddressImpl>
    implements _$$UserAddressImplCopyWith<$Res> {
  __$$UserAddressImplCopyWithImpl(
    _$UserAddressImpl _value,
    $Res Function(_$UserAddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? addressText = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? isDefault = null,
  }) {
    return _then(
      _$UserAddressImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        addressText: null == addressText
            ? _value.addressText
            : addressText // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UserAddressImpl extends _UserAddress {
  const _$UserAddressImpl({
    required this.id,
    required this.label,
    required this.addressText,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  }) : super._();

  @override
  final String id;
  @override
  final String label;
  @override
  final String addressText;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final bool isDefault;

  @override
  String toString() {
    return 'UserAddress(id: $id, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAddressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.addressText, addressText) ||
                other.addressText == addressText) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    addressText,
    latitude,
    longitude,
    isDefault,
  );

  /// Create a copy of UserAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAddressImplCopyWith<_$UserAddressImpl> get copyWith =>
      __$$UserAddressImplCopyWithImpl<_$UserAddressImpl>(this, _$identity);
}

abstract class _UserAddress extends UserAddress {
  const factory _UserAddress({
    required final String id,
    required final String label,
    required final String addressText,
    final double? latitude,
    final double? longitude,
    final bool isDefault,
  }) = _$UserAddressImpl;
  const _UserAddress._() : super._();

  @override
  String get id;
  @override
  String get label;
  @override
  String get addressText;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  bool get isDefault;

  /// Create a copy of UserAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAddressImplCopyWith<_$UserAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
