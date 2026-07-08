import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants/booking_enums.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/payment_repository.dart';
import 'widgets/booking_step_indicator.dart';
import 'widgets/booking_address_step.dart';
import 'widgets/booking_date_time_step.dart';
import 'widgets/booking_summary_step.dart';
import 'widgets/booking_questions_step.dart';

final userAddressesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(dioProvider).get('/UserAddresses');
  final list = List<Map<String, dynamic>>.from(response.data);
  list.sort((a, b) => (b['isDefault'] == true ? 1 : 0).compareTo(a['isDefault'] == true ? 1 : 0));
  return list;
});

final bookingServiceDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
    (ref, id) async {
  try {
    final response = await ref.read(dioProvider).get('/ServiceCatalog/services/$id');
    return response.data;
  } catch (e) {
    final res = await ref.read(dioProvider).get('/ServiceCatalog/services');
    final list = List<Map<String, dynamic>>.from(res.data);
    return list.firstWhere((s) => s['id'] == id);
  }
});

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const CreateBookingScreen({super.key, required this.serviceId});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  int _currentStep = 0;
  bool _isBooking = false;
  int _bookingType = 0; // 1 = Immediate (Đặt ngay), 0 = Scheduled (Hẹn giờ)
  late String _idempotencyKey;

  Map<String, dynamic>? _selectedAddress;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final TextEditingController _notesController = TextEditingController();
  final Map<String, dynamic> _answers = {};
  Map<String, dynamic>? _quote;
  final List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    _regenerateKey();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _regenerateKey() {
    _idempotencyKey = '${DateTime.now().microsecondsSinceEpoch}-${widget.serviceId}';
  }

  /// The concrete start time chosen for a Scheduled booking (null for Immediate).
  DateTime? get _scheduledStart => _bookingType == 0
      ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedTime.hour, _selectedTime.minute)
      : null;

  Map<String, dynamic> get _quoteRequest => {
    'serviceId': widget.serviceId,
    'optionAnswers': _answers,
    if (_scheduledStart != null)
      'scheduledStartTime': _scheduledStart!.toUtc().toIso8601String(),
  };

  bool _questionsAreValid(Map<String, dynamic>? service) {
    final raw = service?['bookingFormSchema'];
    final schema = raw is String ? jsonDecode(raw) : raw;
    if (schema is! Map || schema['questions'] is! List) return true;
    for (final rawQuestion in schema['questions'] as List) {
      if (rawQuestion is! Map || rawQuestion['required'] != true) continue;
      final id = (rawQuestion['id'] ?? rawQuestion['key']).toString();
      final value = _answers[id];
      if (value == null || value == '' || (value is Iterable && value.isEmpty)) return false;
    }
    return true;
  }

  Future<void> _navigateAndRefresh() async {
    await context.push('/address');
    ref.invalidate(userAddressesProvider);
  }

  /// Switching to VNPay requires a linked account (simulated gateway): fetch the current link,
  /// prompt for one if missing, and only commit the selection once linking succeeds — otherwise
  /// the backend would reject the booking with VNPAY_NOT_LINKED at submit time.
  Future<void> _changePaymentMethod(PaymentMethod method) async {
    if (method != PaymentMethod.vnpay) {
      setState(() => _paymentMethod = method);
      return;
    }
    try {
      final linked = await ref.read(paymentRepositoryProvider).getVnpayAccount();
      if (!mounted) return;
      if (linked == null || linked.isEmpty) {
        final entered = await _promptVnpayAccount();
        if (entered == null || entered.trim().isEmpty) return; // user backed out — keep old method
        await ref.read(paymentRepositoryProvider).linkVnpayAccount(entered.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã liên kết tài khoản VNPay.')),
        );
      }
      setState(() => _paymentMethod = PaymentMethod.vnpay);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<String?> _promptVnpayAccount() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Liên kết VNPay'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại / tài khoản VNPay',
            hintText: 'VD: 0901234567',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Liên kết'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isBooking = true);
    try {
      final payload = {
        'serviceId': widget.serviceId,
        'addressId': _selectedAddress?['id'],
        if (_bookingType == 0)
          'scheduledStartTime': _scheduledStart?.toUtc().toIso8601String(),
        'bookingType': _bookingType == 1 ? BookingTypeName.immediate : BookingTypeName.scheduled,
        // Enum by NAME, matching the API convention ('Cash' | 'Vnpay').
        'paymentMethod': _paymentMethod == PaymentMethod.vnpay ? 'Vnpay' : 'Cash',
        'serviceVersion': _quote?['serviceVersion'],
        'optionAnswers': _answers,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : 'Không có ghi chú',
      };

      final newBooking = await ref
          .read(bookingRepositoryProvider)
          .createBooking(payload, idempotencyKey: _idempotencyKey);
      if (_photos.isNotEmpty) {
        await ref.read(bookingRepositoryProvider).uploadPhotos(
          newBooking.id,
          await Future.wait(_photos.map((photo) => MultipartFile.fromFile(photo.path, filename: photo.name))),
        );
      }

      ref.invalidate(bookingsProvider);
      if (mounted) {
        if (_bookingType == 1) {
          // Clears the multi-step creation flow off the stack first, so Back from Booking Detail
          // returns to the Bookings tab instead of back into the (now stale) creation form.
          context.go('/bookings');
          context.push('/booking/${newBooking.id}');
        } else {
          context.go('/home');
        }
      }
    } on QuoteStaleException {
      final refreshed = await ref.read(bookingRepositoryProvider).getQuote(_quoteRequest);
      if (mounted) {
        setState(() { _quote = refreshed; _isBooking = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giá đã thay đổi, đang xác nhận lại.')));
        return _submitBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(userAddressesProvider);
    final serviceAsync = ref.watch(bookingServiceDetailProvider(widget.serviceId));
    final bookingsAsync = ref.watch(bookingsProvider);
    final hasActiveImmediateBooking = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.any(
        (b) => b.isImmediate && b.status == BookingStatusName.awaitingWorker,
      ),
      orElse: () => false,
    );

    if (_selectedAddress == null && addressesAsync.hasValue && addressesAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _selectedAddress = addressesAsync.value!.first));
    }
    if (hasActiveImmediateBooking && _bookingType == 1) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _bookingType = 0));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt dịch vụ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          BookingStepIndicator(currentStep: _currentStep),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: IndexedStack(
                index: _currentStep,
                children: [
                  BookingQuestionsStep(
                    service: serviceAsync.value,
                    answers: _answers,
                    onChanged: (id, value) => setState(() {
                      _answers[id] = value;
                      _quote = null;
                    }),
                    photoCount: _photos.length,
                    onPhotosChanged: (photos) => setState(() => _photos.addAll(photos)),
                  ),
                  BookingAddressStep(
                    addressesAsync: addressesAsync,
                    selectedAddress: _selectedAddress,
                    onAddressSelected: (addr) => setState(() => _selectedAddress = addr),
                    onAddAddressPressed: _navigateAndRefresh,
                    onRetryAddresses: () => ref.invalidate(userAddressesProvider),
                  ),
                  BookingDateTimeStep(
                    bookingType: _bookingType,
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    notesController: _notesController,
                    hasActiveImmediateBooking: hasActiveImmediateBooking,
                    onBookingTypeChanged: (type) => setState(() {
                      _bookingType = type;
                      _regenerateKey();
                    }),
                    onDateChanged: (date) => setState(() => _selectedDate = date),
                    onTimeChanged: (time) => setState(() => _selectedTime = time),
                  ),
                  BookingSummaryStep(
                    serviceAsync: serviceAsync,
                    selectedAddress: _selectedAddress,
                    bookingType: _bookingType,
                    availableStart: _scheduledStart,
                    selectedDate: _selectedDate,
                    selectedPaymentMethod: _paymentMethod,
                    onPaymentMethodChanged: _changePaymentMethod,
                    onRetry: () => ref.invalidate(bookingServiceDetailProvider(widget.serviceId)),
                    quote: _quote,
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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isBooking ? null : () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: _isBooking
                    ? null
                    : () {
                        if (_currentStep == 1 && _selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Vui lòng chọn địa chỉ!'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (_currentStep == 0 && !_questionsAreValid(serviceAsync.value)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng trả lời các câu hỏi bắt buộc.')),
                          );
                          return;
                        }
                        if (_currentStep < 3) {
                          if (_currentStep == 2) {
                            setState(() => _isBooking = true);
                            ref.read(bookingRepositoryProvider).getQuote(_quoteRequest).then((quote) {
                              if (mounted) setState(() { _quote = quote; _currentStep++; _isBooking = false; });
                            }).catchError((error) {
                              if (mounted) {
                                setState(() => _isBooking = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
                              }
                            });
                          } else {
                            setState(() => _currentStep++);
                          }
                        } else {
                          _submitBooking();
                        }
                      },
                child: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_currentStep == 3 ? 'Xác nhận' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
