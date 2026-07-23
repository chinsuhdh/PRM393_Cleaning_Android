import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/error_codes.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/booking.dart';
import '../../data/models/user_address.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/user_address_repository.dart';
import 'booking_questions.dart';

part 'create_booking_notifier.g.dart';

class CreateBookingState {
  const CreateBookingState({
    required this.idempotencyKey,
    this.currentStep = 0,
    this.isSubmitting = false,
    this.bookingType = 0,
    this.selectedAddress,
    required this.selectedDate,
    this.selectedTime = const TimeOfDay(hour: 9, minute: 0),
    this.paymentMethod = PaymentMethod.cash,
    this.answers = const {},
    this.quote,
    this.photos = const [],
    this.durationOverrideHours,
    this.quoteStaleRetryCount = 0,
    this.currentLocationAddress,
  });

  final String idempotencyKey;
  final int currentStep;
  final bool isSubmitting;
  final int bookingType;
  final UserAddress? selectedAddress;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic> answers;
  final Map<String, dynamic>? quote;
  final List<XFile> photos;
  final double? durationOverrideHours;
  final int quoteStaleRetryCount;
  final UserAddress? currentLocationAddress;

  DateTime? get scheduledStart => bookingType == 0
      ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute)
      : null;

  CreateBookingState copyWith({
    String? idempotencyKey,
    int? currentStep,
    bool? isSubmitting,
    int? bookingType,
    UserAddress? selectedAddress,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? answers,
    Object? quote = _unset,
    List<XFile>? photos,
    Object? durationOverrideHours = _unset,
    int? quoteStaleRetryCount,
    Object? currentLocationAddress = _unset,
  }) {
    return CreateBookingState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      bookingType: bookingType ?? this.bookingType,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      answers: answers ?? this.answers,
      quote: identical(quote, _unset) ? this.quote : quote as Map<String, dynamic>?,
      photos: photos ?? this.photos,
      durationOverrideHours:
          identical(durationOverrideHours, _unset) ? this.durationOverrideHours : durationOverrideHours as double?,
      quoteStaleRetryCount: quoteStaleRetryCount ?? this.quoteStaleRetryCount,
      currentLocationAddress: identical(currentLocationAddress, _unset)
          ? this.currentLocationAddress
          : currentLocationAddress as UserAddress?,
    );
  }
}

const _unset = Object();

@riverpod
class CreateBookingNotifier extends _$CreateBookingNotifier {
  @override
  CreateBookingState build(String serviceId) {
    return CreateBookingState(
      idempotencyKey: _generateKey(serviceId),
      selectedDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  static String _generateKey(String serviceId) =>
      '${DateTime.now().microsecondsSinceEpoch}-$serviceId';

  void answerQuestion(String id, dynamic value) {
    state = state.copyWith(answers: {...state.answers, id: value}, quote: null);
  }

  void selectAddress(UserAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  void defaultAddressIfNeeded(List<UserAddress> addresses) {
    if (state.selectedAddress != null || addresses.isEmpty) return;
    state = state.copyWith(selectedAddress: addresses.first);
  }

  /// Silently attempts to read the device's current GPS position and reverse-geocode
  /// it into a display-only address. Any denial or failure (permission refused,
  /// GPS disabled, reverse-geocoding error) is swallowed — the current-location
  /// option simply doesn't appear, per the "don't show it if they don't allow access" rule.
  Future<void> loadCurrentLocation() async {
    if (state.currentLocationAddress != null) return;
    try {
      final result = await LocationHelper.getCurrentAddress();
      if (result == null) return;
      state = state.copyWith(
        currentLocationAddress: UserAddress(
          id: '',
          label: 'Vị trí hiện tại',
          addressText: result['addressText'] as String,
          latitude: result['latitude'] as double,
          longitude: result['longitude'] as double,
        ),
      );
    } catch (_) {
      // GPS off, permission denied, or reverse-geocoding failed — no current-location option.
    }
  }

  /// Persists the current-location pick as a real saved address (so it has a
  /// server-assigned id the booking can reference) and selects it.
  Future<void> selectCurrentLocationAddress() async {
    final candidate = state.currentLocationAddress;
    if (candidate == null) return;
    final saved = await ref.read(userAddressRepositoryProvider).createAddress(candidate);
    ref.invalidate(savedAddressesProvider);
    state = state.copyWith(selectedAddress: saved);
  }

  void changeBookingType(int type) {
    state = state.copyWith(bookingType: type, idempotencyKey: _generateKey(serviceId));
  }

  void forceScheduledIfBlocked(bool hasActiveImmediateBooking) {
    if (hasActiveImmediateBooking && state.bookingType == 1) {
      state = state.copyWith(bookingType: 0);
    }
  }

  void changeDate(DateTime date) => state = state.copyWith(selectedDate: date);

  void changeTime(TimeOfDay time) => state = state.copyWith(selectedTime: time);

  void changePaymentMethod(PaymentMethod method) => state = state.copyWith(paymentMethod: method);

  void addPhotos(List<XFile> photos) => state = state.copyWith(photos: [...state.photos, ...photos]);

  void changeDurationOverride(double hours) => state = state.copyWith(durationOverrideHours: hours);

  void goToNextStep() => state = state.copyWith(currentStep: state.currentStep + 1);

  void goToPreviousStep() => state = state.copyWith(currentStep: state.currentStep - 1);

  void seedNumericDefaults(Map<String, dynamic>? service) {
    final defaults = <String, dynamic>{};
    for (final question in parseBookingQuestions(service)) {
      final type = question['type']?.toString();
      if (type != 'stepper' && type != 'number') continue;
      final id = (question['id'] ?? question['key']).toString();
      if (state.answers.containsKey(id)) continue;
      defaults[id] = (question['min'] as num?)?.toInt() ?? 0;
    }
    if (defaults.isEmpty) return;
    state = state.copyWith(answers: {...state.answers, ...defaults});
  }

  bool questionsAreValid(Map<String, dynamic>? service) {
    for (final question in parseBookingQuestions(service)) {
      if (question['required'] != true) continue;
      final id = (question['id'] ?? question['key']).toString();
      if (!isQuestionAnswered(state.answers[id])) return false;
    }
    return true;
  }

  Map<String, dynamic> _quoteRequest() => {
        'serviceId': serviceId,
        'optionAnswers': state.answers,
        if (state.scheduledStart != null) 'scheduledStartTime': state.scheduledStart!.toUtc().toIso8601String(),
        if (state.durationOverrideHours != null) 'durationHours': state.durationOverrideHours,
      };

  Map<String, dynamic> _submitPayload(String notes) => {
        'serviceId': serviceId,
        'addressId': state.selectedAddress?.id,
        if (state.bookingType == 0) 'scheduledStartTime': state.scheduledStart?.toUtc().toIso8601String(),
        'bookingType': state.bookingType == 1 ? BookingTypeName.immediate : BookingTypeName.scheduled,
        'paymentMethod': state.paymentMethod == PaymentMethod.vnpay ? 'Vnpay' : 'Cash',
        'serviceVersion': state.quote?['serviceVersion'],
        'optionAnswers': state.answers,
        'notes': notes.isNotEmpty ? notes : 'Không có ghi chú',
        if (state.durationOverrideHours != null) 'durationHours': state.durationOverrideHours,
      };

  Future<void> fetchQuote() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final quote = await ref.read(bookingRepositoryProvider).getQuote(_quoteRequest());
      state = state.copyWith(quote: quote, currentStep: state.currentStep + 1, isSubmitting: false);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<Booking> submit(String notes) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final newBooking = await repo.createBooking(_submitPayload(notes), idempotencyKey: state.idempotencyKey);
      if (state.photos.isNotEmpty) {
        await repo.uploadPhotos(
          newBooking.id,
          await Future.wait(state.photos.map((p) => MultipartFile.fromFile(p.path, filename: p.name))),
        );
      }
      ref.invalidate(bookingsProvider);
      return newBooking;
    } on AppException catch (e) {
      if (e.code == ErrorCodes.quoteStale) {
        final refreshed = await ref.read(bookingRepositoryProvider).getQuote(_quoteRequest());
        state = state.copyWith(quote: refreshed, quoteStaleRetryCount: state.quoteStaleRetryCount + 1);
        return submit(notes);
      }
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
