// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ServiceCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get iconName => throw _privateConstructorUsedError;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceCategoryCopyWith<ServiceCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCategoryCopyWith<$Res> {
  factory $ServiceCategoryCopyWith(
    ServiceCategory value,
    $Res Function(ServiceCategory) then,
  ) = _$ServiceCategoryCopyWithImpl<$Res, ServiceCategory>;
  @useResult
  $Res call({String id, String name, String? iconName});
}

/// @nodoc
class _$ServiceCategoryCopyWithImpl<$Res, $Val extends ServiceCategory>
    implements $ServiceCategoryCopyWith<$Res> {
  _$ServiceCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            iconName: freezed == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceCategoryImplCopyWith<$Res>
    implements $ServiceCategoryCopyWith<$Res> {
  factory _$$ServiceCategoryImplCopyWith(
    _$ServiceCategoryImpl value,
    $Res Function(_$ServiceCategoryImpl) then,
  ) = __$$ServiceCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? iconName});
}

/// @nodoc
class __$$ServiceCategoryImplCopyWithImpl<$Res>
    extends _$ServiceCategoryCopyWithImpl<$Res, _$ServiceCategoryImpl>
    implements _$$ServiceCategoryImplCopyWith<$Res> {
  __$$ServiceCategoryImplCopyWithImpl(
    _$ServiceCategoryImpl _value,
    $Res Function(_$ServiceCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconName = freezed,
  }) {
    return _then(
      _$ServiceCategoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        iconName: freezed == iconName
            ? _value.iconName
            : iconName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ServiceCategoryImpl extends _ServiceCategory {
  const _$ServiceCategoryImpl({
    required this.id,
    required this.name,
    this.iconName,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String? iconName;

  @override
  String toString() {
    return 'ServiceCategory(id: $id, name: $name, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, iconName);

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceCategoryImplCopyWith<_$ServiceCategoryImpl> get copyWith =>
      __$$ServiceCategoryImplCopyWithImpl<_$ServiceCategoryImpl>(
        this,
        _$identity,
      );
}

abstract class _ServiceCategory extends ServiceCategory {
  const factory _ServiceCategory({
    required final String id,
    required final String name,
    final String? iconName,
  }) = _$ServiceCategoryImpl;
  const _ServiceCategory._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String? get iconName;

  /// Create a copy of ServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceCategoryImplCopyWith<_$ServiceCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
