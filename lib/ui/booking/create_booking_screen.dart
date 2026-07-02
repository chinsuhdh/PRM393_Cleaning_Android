import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/booking_repository.dart';
import 'widgets/booking_step_indicator.dart';
import 'widgets/booking_address_step.dart';
import 'widgets/booking_date_time_step.dart';
import 'widgets/booking_summary_step.dart';

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

  Future<void> _navigateAndRefresh() async {
    await context.push('/address');
    ref.invalidate(userAddressesProvider);
  }

  Future<void> _submitBooking() async {
    setState(() => _isBooking = true);
    try {
      final payload = {
        'serviceId': widget.serviceId,
        'addressId': _selectedAddress?['id'],
        if (_bookingType == 0)
          'scheduledStartTime': _scheduledStart?.toUtc().toIso8601String(),
        'bookingType': _bookingType,
        'durationHours': 2,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : 'Không có ghi chú',
      };

      final newBooking = await ref
          .read(bookingRepositoryProvider)
          .createBooking(payload, idempotencyKey: _idempotencyKey);

      ref.invalidate(bookingsProvider);
      if (mounted) {
        // Both Immediate and Scheduled now go to the finding-worker screen, which watches the
        // booking until an eligible worker accepts.
        context.push('/finding-worker/${newBooking.id}');
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

    if (_selectedAddress == null && addressesAsync.hasValue && addressesAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _selectedAddress = addressesAsync.value!.first));
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
                    onPaymentMethodChanged: (method) => setState(() => _paymentMethod = method),
                    onRetry: () => ref.invalidate(bookingServiceDetailProvider(widget.serviceId)),
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
                        if (_currentStep == 0 && _selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Vui lòng chọn địa chỉ!'),
                                backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
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
                    : Text(_currentStep == 2 ? 'Xác nhận' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
