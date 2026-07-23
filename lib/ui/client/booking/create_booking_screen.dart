import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/booking_enums.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/service_catalog_repository.dart';
import '../../../data/repositories/user_address_repository.dart';
import '../../../logic/booking/create_booking_notifier.dart';
import '../../shared/app_snackbar.dart';
import 'widgets/steps/booking_step_indicator.dart';
import 'widgets/steps/booking_address_step.dart';
import 'widgets/steps/booking_date_time_step.dart';
import 'widgets/steps/booking_summary_step.dart';
import 'widgets/steps/booking_questions_step.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const CreateBookingScreen({super.key, required this.serviceId});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  CreateBookingNotifier get _notifier =>
      ref.read(createBookingNotifierProvider(widget.serviceId).notifier);

  Future<void> _navigateAndRefresh() async {
    await context.push('/address');
    ref.invalidate(savedAddressesProvider);
  }

  Future<void> _handleNext(CreateBookingState state, Map<String, dynamic>? service) async {
    if (state.currentStep == 1 && state.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (state.currentStep == 0 && !_notifier.questionsAreValid(service)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời các câu hỏi bắt buộc.')),
      );
      return;
    }

    if (state.currentStep < 3) {
      if (state.currentStep == 2) {
        try {
          await _notifier.fetchQuote();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      } else {
        _notifier.goToNextStep();
      }
      return;
    }

    try {
      final booking = await _notifier.submit(_notesController.text);
      if (!mounted) return;
      if (state.bookingType == 1) {
        context.go('/bookings');
        context.push('/booking/${booking.id}');
      } else {
        context.go('/home');
      }
    } on AppException catch (e) {
      if (mounted) showAppErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBookingNotifierProvider(widget.serviceId));
    final notifier = _notifier;
    final addressesAsync = ref.watch(savedAddressesProvider);
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final bookingsAsync = ref.watch(bookingsProvider);
    final hasActiveImmediateBooking = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.any(
        (b) => b.isImmediate && b.status == BookingStatusName.awaitingWorker,
      ),
      orElse: () => false,
    );

    ref.listen(createBookingNotifierProvider(widget.serviceId), (previous, next) {
      if (previous != null && next.quoteStaleRetryCount > previous.quoteStaleRetryCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giá đã thay đổi, đang xác nhận lại.')),
        );
      }
    });

    if (addressesAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => notifier.defaultAddressIfNeeded(addressesAsync.value!));
    }
    if (serviceAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.seedNumericDefaults(serviceAsync.value));
    }
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => notifier.forceScheduledIfBlocked(hasActiveImmediateBooking));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt dịch vụ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          BookingStepIndicator(currentStep: state.currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: IndexedStack(
                index: state.currentStep,
                children: [
                  BookingQuestionsStep(
                    service: serviceAsync.value,
                    answers: state.answers,
                    onChanged: notifier.answerQuestion,
                    photoCount: state.photos.length,
                    onPhotosChanged: notifier.addPhotos,
                    durationOverrideHours: state.durationOverrideHours,
                    onDurationOverrideChanged: notifier.changeDurationOverride,
                  ),
                  BookingAddressStep(
                    addressesAsync: addressesAsync,
                    selectedAddress: state.selectedAddress,
                    onAddressSelected: notifier.selectAddress,
                    onAddAddressPressed: _navigateAndRefresh,
                    onRetryAddresses: () => ref.invalidate(savedAddressesProvider),
                  ),
                  BookingDateTimeStep(
                    bookingType: state.bookingType,
                    selectedDate: state.selectedDate,
                    selectedTime: state.selectedTime,
                    notesController: _notesController,
                    hasActiveImmediateBooking: hasActiveImmediateBooking,
                    onBookingTypeChanged: notifier.changeBookingType,
                    onDateChanged: notifier.changeDate,
                    onTimeChanged: notifier.changeTime,
                  ),
                  BookingSummaryStep(
                    serviceAsync: serviceAsync,
                    selectedAddress: state.selectedAddress,
                    bookingType: state.bookingType,
                    availableStart: state.scheduledStart,
                    selectedDate: state.selectedDate,
                    selectedPaymentMethod: state.paymentMethod,
                    onPaymentMethodChanged: notifier.changePaymentMethod,
                    onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId)),
                    quote: state.quote,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isSubmitting ? null : notifier.goToPreviousStep,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: state.isSubmitting ? null : () => _handleNext(state, serviceAsync.value),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(state.currentStep == 3 ? 'Xác nhận' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
