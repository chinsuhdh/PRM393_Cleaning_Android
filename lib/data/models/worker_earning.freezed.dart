// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'worker_earning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WorkerEarning {
  String get id => throw _privateConstructorUsedError;
  String get bookingId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get earnedAt => throw _privateConstructorUsedError;
  DateTime? get paidAt => throw _privateConstructorUsedError;
  String? get payoutFailureReason => throw _privateConstructorUsedError;

  /// Create a copy of WorkerEarning
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkerEarningCopyWith<WorkerEarning> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkerEarningCopyWith<$Res> {
  factory $WorkerEarningCopyWith(
    WorkerEarning value,
    $Res Function(WorkerEarning) then,
  ) = _$WorkerEarningCopyWithImpl<$Res, WorkerEarning>;
  @useResult
  $Res call({
    String id,
    String bookingId,
    double amount,
    String status,
    DateTime? earnedAt,
    DateTime? paidAt,
    String? payoutFailureReason,
  });
}

/// @nodoc
class _$WorkerEarningCopyWithImpl<$Res, $Val extends WorkerEarning>
    implements $WorkerEarningCopyWith<$Res> {
  _$WorkerEarningCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkerEarning
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? amount = null,
    Object? status = null,
    Object? earnedAt = freezed,
    Object? paidAt = freezed,
    Object? payoutFailureReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            bookingId: null == bookingId
                ? _value.bookingId
                : bookingId // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            earnedAt: freezed == earnedAt
                ? _value.earnedAt
                : earnedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            payoutFailureReason: freezed == payoutFailureReason
                ? _value.payoutFailureReason
                : payoutFailureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkerEarningImplCopyWith<$Res>
    implements $WorkerEarningCopyWith<$Res> {
  factory _$$WorkerEarningImplCopyWith(
    _$WorkerEarningImpl value,
    $Res Function(_$WorkerEarningImpl) then,
  ) = __$$WorkerEarningImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String bookingId,
    double amount,
    String status,
    DateTime? earnedAt,
    DateTime? paidAt,
    String? payoutFailureReason,
  });
}

/// @nodoc
class __$$WorkerEarningImplCopyWithImpl<$Res>
    extends _$WorkerEarningCopyWithImpl<$Res, _$WorkerEarningImpl>
    implements _$$WorkerEarningImplCopyWith<$Res> {
  __$$WorkerEarningImplCopyWithImpl(
    _$WorkerEarningImpl _value,
    $Res Function(_$WorkerEarningImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkerEarning
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookingId = null,
    Object? amount = null,
    Object? status = null,
    Object? earnedAt = freezed,
    Object? paidAt = freezed,
    Object? payoutFailureReason = freezed,
  }) {
    return _then(
      _$WorkerEarningImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        bookingId: null == bookingId
            ? _value.bookingId
            : bookingId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        earnedAt: freezed == earnedAt
            ? _value.earnedAt
            : earnedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        payoutFailureReason: freezed == payoutFailureReason
            ? _value.payoutFailureReason
            : payoutFailureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$WorkerEarningImpl extends _WorkerEarning {
  const _$WorkerEarningImpl({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    this.earnedAt,
    this.paidAt,
    this.payoutFailureReason,
  }) : super._();

  @override
  final String id;
  @override
  final String bookingId;
  @override
  final double amount;
  @override
  final String status;
  @override
  final DateTime? earnedAt;
  @override
  final DateTime? paidAt;
  @override
  final String? payoutFailureReason;

  @override
  String toString() {
    return 'WorkerEarning(id: $id, bookingId: $bookingId, amount: $amount, status: $status, earnedAt: $earnedAt, paidAt: $paidAt, payoutFailureReason: $payoutFailureReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkerEarningImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.earnedAt, earnedAt) ||
                other.earnedAt == earnedAt) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.payoutFailureReason, payoutFailureReason) ||
                other.payoutFailureReason == payoutFailureReason));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookingId,
    amount,
    status,
    earnedAt,
    paidAt,
    payoutFailureReason,
  );

  /// Create a copy of WorkerEarning
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkerEarningImplCopyWith<_$WorkerEarningImpl> get copyWith =>
      __$$WorkerEarningImplCopyWithImpl<_$WorkerEarningImpl>(this, _$identity);
}

abstract class _WorkerEarning extends WorkerEarning {
  const factory _WorkerEarning({
    required final String id,
    required final String bookingId,
    required final double amount,
    required final String status,
    final DateTime? earnedAt,
    final DateTime? paidAt,
    final String? payoutFailureReason,
  }) = _$WorkerEarningImpl;
  const _WorkerEarning._() : super._();

  @override
  String get id;
  @override
  String get bookingId;
  @override
  double get amount;
  @override
  String get status;
  @override
  DateTime? get earnedAt;
  @override
  DateTime? get paidAt;
  @override
  String? get payoutFailureReason;

  /// Create a copy of WorkerEarning
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkerEarningImplCopyWith<_$WorkerEarningImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
