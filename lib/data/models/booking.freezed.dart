// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RescheduleProposal {
  String get id => throw _privateConstructorUsedError;
  String get requestedBy => throw _privateConstructorUsedError;
  DateTime get oldStartTime => throw _privateConstructorUsedError;
  DateTime get oldEndTime => throw _privateConstructorUsedError;
  DateTime get newStartTime => throw _privateConstructorUsedError;
  DateTime get newEndTime => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get respondedAt => throw _privateConstructorUsedError;

  /// Create a copy of RescheduleProposal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RescheduleProposalCopyWith<RescheduleProposal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RescheduleProposalCopyWith<$Res> {
  factory $RescheduleProposalCopyWith(
    RescheduleProposal value,
    $Res Function(RescheduleProposal) then,
  ) = _$RescheduleProposalCopyWithImpl<$Res, RescheduleProposal>;
  @useResult
  $Res call({
    String id,
    String requestedBy,
    DateTime oldStartTime,
    DateTime oldEndTime,
    DateTime newStartTime,
    DateTime newEndTime,
    String status,
    String? reason,
    DateTime? createdAt,
    DateTime? respondedAt,
  });
}

/// @nodoc
class _$RescheduleProposalCopyWithImpl<$Res, $Val extends RescheduleProposal>
    implements $RescheduleProposalCopyWith<$Res> {
  _$RescheduleProposalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RescheduleProposal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestedBy = null,
    Object? oldStartTime = null,
    Object? oldEndTime = null,
    Object? newStartTime = null,
    Object? newEndTime = null,
    Object? status = null,
    Object? reason = freezed,
    Object? createdAt = freezed,
    Object? respondedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            requestedBy: null == requestedBy
                ? _value.requestedBy
                : requestedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            oldStartTime: null == oldStartTime
                ? _value.oldStartTime
                : oldStartTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            oldEndTime: null == oldEndTime
                ? _value.oldEndTime
                : oldEndTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            newStartTime: null == newStartTime
                ? _value.newStartTime
                : newStartTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            newEndTime: null == newEndTime
                ? _value.newEndTime
                : newEndTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            respondedAt: freezed == respondedAt
                ? _value.respondedAt
                : respondedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RescheduleProposalImplCopyWith<$Res>
    implements $RescheduleProposalCopyWith<$Res> {
  factory _$$RescheduleProposalImplCopyWith(
    _$RescheduleProposalImpl value,
    $Res Function(_$RescheduleProposalImpl) then,
  ) = __$$RescheduleProposalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String requestedBy,
    DateTime oldStartTime,
    DateTime oldEndTime,
    DateTime newStartTime,
    DateTime newEndTime,
    String status,
    String? reason,
    DateTime? createdAt,
    DateTime? respondedAt,
  });
}

/// @nodoc
class __$$RescheduleProposalImplCopyWithImpl<$Res>
    extends _$RescheduleProposalCopyWithImpl<$Res, _$RescheduleProposalImpl>
    implements _$$RescheduleProposalImplCopyWith<$Res> {
  __$$RescheduleProposalImplCopyWithImpl(
    _$RescheduleProposalImpl _value,
    $Res Function(_$RescheduleProposalImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RescheduleProposal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestedBy = null,
    Object? oldStartTime = null,
    Object? oldEndTime = null,
    Object? newStartTime = null,
    Object? newEndTime = null,
    Object? status = null,
    Object? reason = freezed,
    Object? createdAt = freezed,
    Object? respondedAt = freezed,
  }) {
    return _then(
      _$RescheduleProposalImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        requestedBy: null == requestedBy
            ? _value.requestedBy
            : requestedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        oldStartTime: null == oldStartTime
            ? _value.oldStartTime
            : oldStartTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        oldEndTime: null == oldEndTime
            ? _value.oldEndTime
            : oldEndTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        newStartTime: null == newStartTime
            ? _value.newStartTime
            : newStartTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        newEndTime: null == newEndTime
            ? _value.newEndTime
            : newEndTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        respondedAt: freezed == respondedAt
            ? _value.respondedAt
            : respondedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$RescheduleProposalImpl extends _RescheduleProposal {
  const _$RescheduleProposalImpl({
    required this.id,
    required this.requestedBy,
    required this.oldStartTime,
    required this.oldEndTime,
    required this.newStartTime,
    required this.newEndTime,
    required this.status,
    this.reason,
    this.createdAt,
    this.respondedAt,
  }) : super._();

  @override
  final String id;
  @override
  final String requestedBy;
  @override
  final DateTime oldStartTime;
  @override
  final DateTime oldEndTime;
  @override
  final DateTime newStartTime;
  @override
  final DateTime newEndTime;
  @override
  final String status;
  @override
  final String? reason;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? respondedAt;

  @override
  String toString() {
    return 'RescheduleProposal(id: $id, requestedBy: $requestedBy, oldStartTime: $oldStartTime, oldEndTime: $oldEndTime, newStartTime: $newStartTime, newEndTime: $newEndTime, status: $status, reason: $reason, createdAt: $createdAt, respondedAt: $respondedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RescheduleProposalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requestedBy, requestedBy) ||
                other.requestedBy == requestedBy) &&
            (identical(other.oldStartTime, oldStartTime) ||
                other.oldStartTime == oldStartTime) &&
            (identical(other.oldEndTime, oldEndTime) ||
                other.oldEndTime == oldEndTime) &&
            (identical(other.newStartTime, newStartTime) ||
                other.newStartTime == newStartTime) &&
            (identical(other.newEndTime, newEndTime) ||
                other.newEndTime == newEndTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    requestedBy,
    oldStartTime,
    oldEndTime,
    newStartTime,
    newEndTime,
    status,
    reason,
    createdAt,
    respondedAt,
  );

  /// Create a copy of RescheduleProposal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RescheduleProposalImplCopyWith<_$RescheduleProposalImpl> get copyWith =>
      __$$RescheduleProposalImplCopyWithImpl<_$RescheduleProposalImpl>(
        this,
        _$identity,
      );
}

abstract class _RescheduleProposal extends RescheduleProposal {
  const factory _RescheduleProposal({
    required final String id,
    required final String requestedBy,
    required final DateTime oldStartTime,
    required final DateTime oldEndTime,
    required final DateTime newStartTime,
    required final DateTime newEndTime,
    required final String status,
    final String? reason,
    final DateTime? createdAt,
    final DateTime? respondedAt,
  }) = _$RescheduleProposalImpl;
  const _RescheduleProposal._() : super._();

  @override
  String get id;
  @override
  String get requestedBy;
  @override
  DateTime get oldStartTime;
  @override
  DateTime get oldEndTime;
  @override
  DateTime get newStartTime;
  @override
  DateTime get newEndTime;
  @override
  String get status;
  @override
  String? get reason;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get respondedAt;

  /// Create a copy of RescheduleProposal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RescheduleProposalImplCopyWith<_$RescheduleProposalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Booking {
  String get id => throw _privateConstructorUsedError;
  String get serviceId => throw _privateConstructorUsedError;
  String get serviceName => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get time => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String get bookingType => throw _privateConstructorUsedError;
  Worker? get worker => throw _privateConstructorUsedError;
  DateTime? get scheduledStartTime => throw _privateConstructorUsedError;
  DateTime? get actualStartTime => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get statusTimeline =>
      throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get photos => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get pricingBreakdown =>
      throw _privateConstructorUsedError;
  double get durationHours => throw _privateConstructorUsedError;
  double get unitPrice => throw _privateConstructorUsedError;
  double get extraFee => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  Map<String, dynamic> get optionAnswers => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get bookingQuestions =>
      throw _privateConstructorUsedError;
  String? get addressText => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  double? get distanceKm => throw _privateConstructorUsedError;
  double? get estimatedMinutes => throw _privateConstructorUsedError;
  RescheduleProposal? get pendingReschedule =>
      throw _privateConstructorUsedError;
  List<RescheduleProposal> get rescheduleHistory =>
      throw _privateConstructorUsedError;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingCopyWith<Booking> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingCopyWith<$Res> {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) then) =
      _$BookingCopyWithImpl<$Res, Booking>;
  @useResult
  $Res call({
    String id,
    String serviceId,
    String serviceName,
    String date,
    String time,
    double price,
    String status,
    String paymentMethod,
    String bookingType,
    Worker? worker,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? updatedAt,
    DateTime? createdAt,
    List<Map<String, dynamic>> statusTimeline,
    List<Map<String, dynamic>> photos,
    List<Map<String, dynamic>> pricingBreakdown,
    double durationHours,
    double unitPrice,
    double extraFee,
    double discountAmount,
    String notes,
    Map<String, dynamic> optionAnswers,
    List<Map<String, dynamic>> bookingQuestions,
    String? addressText,
    double? latitude,
    double? longitude,
    double? distanceKm,
    double? estimatedMinutes,
    RescheduleProposal? pendingReschedule,
    List<RescheduleProposal> rescheduleHistory,
  });

  $WorkerCopyWith<$Res>? get worker;
  $RescheduleProposalCopyWith<$Res>? get pendingReschedule;
}

/// @nodoc
class _$BookingCopyWithImpl<$Res, $Val extends Booking>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serviceId = null,
    Object? serviceName = null,
    Object? date = null,
    Object? time = null,
    Object? price = null,
    Object? status = null,
    Object? paymentMethod = null,
    Object? bookingType = null,
    Object? worker = freezed,
    Object? scheduledStartTime = freezed,
    Object? actualStartTime = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
    Object? statusTimeline = null,
    Object? photos = null,
    Object? pricingBreakdown = null,
    Object? durationHours = null,
    Object? unitPrice = null,
    Object? extraFee = null,
    Object? discountAmount = null,
    Object? notes = null,
    Object? optionAnswers = null,
    Object? bookingQuestions = null,
    Object? addressText = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? distanceKm = freezed,
    Object? estimatedMinutes = freezed,
    Object? pendingReschedule = freezed,
    Object? rescheduleHistory = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            serviceId: null == serviceId
                ? _value.serviceId
                : serviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            serviceName: null == serviceName
                ? _value.serviceName
                : serviceName // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            bookingType: null == bookingType
                ? _value.bookingType
                : bookingType // ignore: cast_nullable_to_non_nullable
                      as String,
            worker: freezed == worker
                ? _value.worker
                : worker // ignore: cast_nullable_to_non_nullable
                      as Worker?,
            scheduledStartTime: freezed == scheduledStartTime
                ? _value.scheduledStartTime
                : scheduledStartTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            actualStartTime: freezed == actualStartTime
                ? _value.actualStartTime
                : actualStartTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            statusTimeline: null == statusTimeline
                ? _value.statusTimeline
                : statusTimeline // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            photos: null == photos
                ? _value.photos
                : photos // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            pricingBreakdown: null == pricingBreakdown
                ? _value.pricingBreakdown
                : pricingBreakdown // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            durationHours: null == durationHours
                ? _value.durationHours
                : durationHours // ignore: cast_nullable_to_non_nullable
                      as double,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            extraFee: null == extraFee
                ? _value.extraFee
                : extraFee // ignore: cast_nullable_to_non_nullable
                      as double,
            discountAmount: null == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
            optionAnswers: null == optionAnswers
                ? _value.optionAnswers
                : optionAnswers // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            bookingQuestions: null == bookingQuestions
                ? _value.bookingQuestions
                : bookingQuestions // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            addressText: freezed == addressText
                ? _value.addressText
                : addressText // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            distanceKm: freezed == distanceKm
                ? _value.distanceKm
                : distanceKm // ignore: cast_nullable_to_non_nullable
                      as double?,
            estimatedMinutes: freezed == estimatedMinutes
                ? _value.estimatedMinutes
                : estimatedMinutes // ignore: cast_nullable_to_non_nullable
                      as double?,
            pendingReschedule: freezed == pendingReschedule
                ? _value.pendingReschedule
                : pendingReschedule // ignore: cast_nullable_to_non_nullable
                      as RescheduleProposal?,
            rescheduleHistory: null == rescheduleHistory
                ? _value.rescheduleHistory
                : rescheduleHistory // ignore: cast_nullable_to_non_nullable
                      as List<RescheduleProposal>,
          )
          as $Val,
    );
  }

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WorkerCopyWith<$Res>? get worker {
    if (_value.worker == null) {
      return null;
    }

    return $WorkerCopyWith<$Res>(_value.worker!, (value) {
      return _then(_value.copyWith(worker: value) as $Val);
    });
  }

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RescheduleProposalCopyWith<$Res>? get pendingReschedule {
    if (_value.pendingReschedule == null) {
      return null;
    }

    return $RescheduleProposalCopyWith<$Res>(_value.pendingReschedule!, (
      value,
    ) {
      return _then(_value.copyWith(pendingReschedule: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingImplCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$$BookingImplCopyWith(
    _$BookingImpl value,
    $Res Function(_$BookingImpl) then,
  ) = __$$BookingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String serviceId,
    String serviceName,
    String date,
    String time,
    double price,
    String status,
    String paymentMethod,
    String bookingType,
    Worker? worker,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? updatedAt,
    DateTime? createdAt,
    List<Map<String, dynamic>> statusTimeline,
    List<Map<String, dynamic>> photos,
    List<Map<String, dynamic>> pricingBreakdown,
    double durationHours,
    double unitPrice,
    double extraFee,
    double discountAmount,
    String notes,
    Map<String, dynamic> optionAnswers,
    List<Map<String, dynamic>> bookingQuestions,
    String? addressText,
    double? latitude,
    double? longitude,
    double? distanceKm,
    double? estimatedMinutes,
    RescheduleProposal? pendingReschedule,
    List<RescheduleProposal> rescheduleHistory,
  });

  @override
  $WorkerCopyWith<$Res>? get worker;
  @override
  $RescheduleProposalCopyWith<$Res>? get pendingReschedule;
}

/// @nodoc
class __$$BookingImplCopyWithImpl<$Res>
    extends _$BookingCopyWithImpl<$Res, _$BookingImpl>
    implements _$$BookingImplCopyWith<$Res> {
  __$$BookingImplCopyWithImpl(
    _$BookingImpl _value,
    $Res Function(_$BookingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serviceId = null,
    Object? serviceName = null,
    Object? date = null,
    Object? time = null,
    Object? price = null,
    Object? status = null,
    Object? paymentMethod = null,
    Object? bookingType = null,
    Object? worker = freezed,
    Object? scheduledStartTime = freezed,
    Object? actualStartTime = freezed,
    Object? updatedAt = freezed,
    Object? createdAt = freezed,
    Object? statusTimeline = null,
    Object? photos = null,
    Object? pricingBreakdown = null,
    Object? durationHours = null,
    Object? unitPrice = null,
    Object? extraFee = null,
    Object? discountAmount = null,
    Object? notes = null,
    Object? optionAnswers = null,
    Object? bookingQuestions = null,
    Object? addressText = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? distanceKm = freezed,
    Object? estimatedMinutes = freezed,
    Object? pendingReschedule = freezed,
    Object? rescheduleHistory = null,
  }) {
    return _then(
      _$BookingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        serviceId: null == serviceId
            ? _value.serviceId
            : serviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        serviceName: null == serviceName
            ? _value.serviceName
            : serviceName // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        bookingType: null == bookingType
            ? _value.bookingType
            : bookingType // ignore: cast_nullable_to_non_nullable
                  as String,
        worker: freezed == worker
            ? _value.worker
            : worker // ignore: cast_nullable_to_non_nullable
                  as Worker?,
        scheduledStartTime: freezed == scheduledStartTime
            ? _value.scheduledStartTime
            : scheduledStartTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        actualStartTime: freezed == actualStartTime
            ? _value.actualStartTime
            : actualStartTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        statusTimeline: null == statusTimeline
            ? _value._statusTimeline
            : statusTimeline // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        photos: null == photos
            ? _value._photos
            : photos // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        pricingBreakdown: null == pricingBreakdown
            ? _value._pricingBreakdown
            : pricingBreakdown // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        durationHours: null == durationHours
            ? _value.durationHours
            : durationHours // ignore: cast_nullable_to_non_nullable
                  as double,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        extraFee: null == extraFee
            ? _value.extraFee
            : extraFee // ignore: cast_nullable_to_non_nullable
                  as double,
        discountAmount: null == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        optionAnswers: null == optionAnswers
            ? _value._optionAnswers
            : optionAnswers // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        bookingQuestions: null == bookingQuestions
            ? _value._bookingQuestions
            : bookingQuestions // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        addressText: freezed == addressText
            ? _value.addressText
            : addressText // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        distanceKm: freezed == distanceKm
            ? _value.distanceKm
            : distanceKm // ignore: cast_nullable_to_non_nullable
                  as double?,
        estimatedMinutes: freezed == estimatedMinutes
            ? _value.estimatedMinutes
            : estimatedMinutes // ignore: cast_nullable_to_non_nullable
                  as double?,
        pendingReschedule: freezed == pendingReschedule
            ? _value.pendingReschedule
            : pendingReschedule // ignore: cast_nullable_to_non_nullable
                  as RescheduleProposal?,
        rescheduleHistory: null == rescheduleHistory
            ? _value._rescheduleHistory
            : rescheduleHistory // ignore: cast_nullable_to_non_nullable
                  as List<RescheduleProposal>,
      ),
    );
  }
}

/// @nodoc

class _$BookingImpl extends _Booking {
  const _$BookingImpl({
    required this.id,
    this.serviceId = '',
    required this.serviceName,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.paymentMethod = 'Cash',
    this.bookingType = '',
    this.worker,
    this.scheduledStartTime,
    this.actualStartTime,
    this.updatedAt,
    this.createdAt,
    final List<Map<String, dynamic>> statusTimeline = _emptyMapList,
    final List<Map<String, dynamic>> photos = _emptyMapList,
    final List<Map<String, dynamic>> pricingBreakdown = _emptyMapList,
    this.durationHours = 0,
    this.unitPrice = 0,
    this.extraFee = 0,
    this.discountAmount = 0,
    this.notes = '',
    final Map<String, dynamic> optionAnswers = _emptyJsonMap,
    final List<Map<String, dynamic>> bookingQuestions = _emptyMapList,
    this.addressText,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.estimatedMinutes,
    this.pendingReschedule,
    final List<RescheduleProposal> rescheduleHistory = _emptyRescheduleList,
  }) : _statusTimeline = statusTimeline,
       _photos = photos,
       _pricingBreakdown = pricingBreakdown,
       _optionAnswers = optionAnswers,
       _bookingQuestions = bookingQuestions,
       _rescheduleHistory = rescheduleHistory,
       super._();

  @override
  final String id;
  @override
  @JsonKey()
  final String serviceId;
  @override
  final String serviceName;
  @override
  final String date;
  @override
  final String time;
  @override
  final double price;
  @override
  final String status;
  @override
  @JsonKey()
  final String paymentMethod;
  @override
  @JsonKey()
  final String bookingType;
  @override
  final Worker? worker;
  @override
  final DateTime? scheduledStartTime;
  @override
  final DateTime? actualStartTime;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? createdAt;
  final List<Map<String, dynamic>> _statusTimeline;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get statusTimeline {
    if (_statusTimeline is EqualUnmodifiableListView) return _statusTimeline;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statusTimeline);
  }

  final List<Map<String, dynamic>> _photos;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  final List<Map<String, dynamic>> _pricingBreakdown;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get pricingBreakdown {
    if (_pricingBreakdown is EqualUnmodifiableListView)
      return _pricingBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pricingBreakdown);
  }

  @override
  @JsonKey()
  final double durationHours;
  @override
  @JsonKey()
  final double unitPrice;
  @override
  @JsonKey()
  final double extraFee;
  @override
  @JsonKey()
  final double discountAmount;
  @override
  @JsonKey()
  final String notes;
  final Map<String, dynamic> _optionAnswers;
  @override
  @JsonKey()
  Map<String, dynamic> get optionAnswers {
    if (_optionAnswers is EqualUnmodifiableMapView) return _optionAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_optionAnswers);
  }

  final List<Map<String, dynamic>> _bookingQuestions;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get bookingQuestions {
    if (_bookingQuestions is EqualUnmodifiableListView)
      return _bookingQuestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookingQuestions);
  }

  @override
  final String? addressText;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final double? distanceKm;
  @override
  final double? estimatedMinutes;
  @override
  final RescheduleProposal? pendingReschedule;
  final List<RescheduleProposal> _rescheduleHistory;
  @override
  @JsonKey()
  List<RescheduleProposal> get rescheduleHistory {
    if (_rescheduleHistory is EqualUnmodifiableListView)
      return _rescheduleHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rescheduleHistory);
  }

  @override
  String toString() {
    return 'Booking(id: $id, serviceId: $serviceId, serviceName: $serviceName, date: $date, time: $time, price: $price, status: $status, paymentMethod: $paymentMethod, bookingType: $bookingType, worker: $worker, scheduledStartTime: $scheduledStartTime, actualStartTime: $actualStartTime, updatedAt: $updatedAt, createdAt: $createdAt, statusTimeline: $statusTimeline, photos: $photos, pricingBreakdown: $pricingBreakdown, durationHours: $durationHours, unitPrice: $unitPrice, extraFee: $extraFee, discountAmount: $discountAmount, notes: $notes, optionAnswers: $optionAnswers, bookingQuestions: $bookingQuestions, addressText: $addressText, latitude: $latitude, longitude: $longitude, distanceKm: $distanceKm, estimatedMinutes: $estimatedMinutes, pendingReschedule: $pendingReschedule, rescheduleHistory: $rescheduleHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.bookingType, bookingType) ||
                other.bookingType == bookingType) &&
            (identical(other.worker, worker) || other.worker == worker) &&
            (identical(other.scheduledStartTime, scheduledStartTime) ||
                other.scheduledStartTime == scheduledStartTime) &&
            (identical(other.actualStartTime, actualStartTime) ||
                other.actualStartTime == actualStartTime) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
              other._statusTimeline,
              _statusTimeline,
            ) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality().equals(
              other._pricingBreakdown,
              _pricingBreakdown,
            ) &&
            (identical(other.durationHours, durationHours) ||
                other.durationHours == durationHours) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.extraFee, extraFee) ||
                other.extraFee == extraFee) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(
              other._optionAnswers,
              _optionAnswers,
            ) &&
            const DeepCollectionEquality().equals(
              other._bookingQuestions,
              _bookingQuestions,
            ) &&
            (identical(other.addressText, addressText) ||
                other.addressText == addressText) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.estimatedMinutes, estimatedMinutes) ||
                other.estimatedMinutes == estimatedMinutes) &&
            (identical(other.pendingReschedule, pendingReschedule) ||
                other.pendingReschedule == pendingReschedule) &&
            const DeepCollectionEquality().equals(
              other._rescheduleHistory,
              _rescheduleHistory,
            ));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    serviceId,
    serviceName,
    date,
    time,
    price,
    status,
    paymentMethod,
    bookingType,
    worker,
    scheduledStartTime,
    actualStartTime,
    updatedAt,
    createdAt,
    const DeepCollectionEquality().hash(_statusTimeline),
    const DeepCollectionEquality().hash(_photos),
    const DeepCollectionEquality().hash(_pricingBreakdown),
    durationHours,
    unitPrice,
    extraFee,
    discountAmount,
    notes,
    const DeepCollectionEquality().hash(_optionAnswers),
    const DeepCollectionEquality().hash(_bookingQuestions),
    addressText,
    latitude,
    longitude,
    distanceKm,
    estimatedMinutes,
    pendingReschedule,
    const DeepCollectionEquality().hash(_rescheduleHistory),
  ]);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      __$$BookingImplCopyWithImpl<_$BookingImpl>(this, _$identity);
}

abstract class _Booking extends Booking {
  const factory _Booking({
    required final String id,
    final String serviceId,
    required final String serviceName,
    required final String date,
    required final String time,
    required final double price,
    required final String status,
    final String paymentMethod,
    final String bookingType,
    final Worker? worker,
    final DateTime? scheduledStartTime,
    final DateTime? actualStartTime,
    final DateTime? updatedAt,
    final DateTime? createdAt,
    final List<Map<String, dynamic>> statusTimeline,
    final List<Map<String, dynamic>> photos,
    final List<Map<String, dynamic>> pricingBreakdown,
    final double durationHours,
    final double unitPrice,
    final double extraFee,
    final double discountAmount,
    final String notes,
    final Map<String, dynamic> optionAnswers,
    final List<Map<String, dynamic>> bookingQuestions,
    final String? addressText,
    final double? latitude,
    final double? longitude,
    final double? distanceKm,
    final double? estimatedMinutes,
    final RescheduleProposal? pendingReschedule,
    final List<RescheduleProposal> rescheduleHistory,
  }) = _$BookingImpl;
  const _Booking._() : super._();

  @override
  String get id;
  @override
  String get serviceId;
  @override
  String get serviceName;
  @override
  String get date;
  @override
  String get time;
  @override
  double get price;
  @override
  String get status;
  @override
  String get paymentMethod;
  @override
  String get bookingType;
  @override
  Worker? get worker;
  @override
  DateTime? get scheduledStartTime;
  @override
  DateTime? get actualStartTime;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get createdAt;
  @override
  List<Map<String, dynamic>> get statusTimeline;
  @override
  List<Map<String, dynamic>> get photos;
  @override
  List<Map<String, dynamic>> get pricingBreakdown;
  @override
  double get durationHours;
  @override
  double get unitPrice;
  @override
  double get extraFee;
  @override
  double get discountAmount;
  @override
  String get notes;
  @override
  Map<String, dynamic> get optionAnswers;
  @override
  List<Map<String, dynamic>> get bookingQuestions;
  @override
  String? get addressText;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  double? get distanceKm;
  @override
  double? get estimatedMinutes;
  @override
  RescheduleProposal? get pendingReschedule;
  @override
  List<RescheduleProposal> get rescheduleHistory;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
