import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/theme/app_colors.dart';

class BookingSummaryStep extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> serviceAsync;
  final Map<String, dynamic>? selectedAddress;
  final int bookingType;
  final DateTime? availableStart;
  final DateTime selectedDate;
  final PaymentMethod selectedPaymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onRetry;

  const BookingSummaryStep({
    super.key,
    required this.serviceAsync,
    required this.selectedAddress,
    required this.bookingType,
    required this.availableStart,
    required this.selectedDate,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return serviceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không thể tải thông tin xác nhận: $e'),
            TextButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (service) {
        final addressText = selectedAddress?['addressText'] ?? 'Chưa chọn địa chỉ';
        final price = service['basePrice'] ?? service['price'] ?? 0.0;
        final tax = (price * 0.05);
        final total = price + tax;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xác nhận',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service['name'] ?? 'Dịch vụ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Thời gian',
                        value: bookingType == 1
                            ? 'Ngay bây giờ'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                .format(availableStart ?? selectedDate),
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Địa chỉ', value: addressText),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _SummaryRow(label: 'Phí dịch vụ', value: '$price VND'),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Thuế (5%)', value: '$tax VND'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('$total VND',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Phương thức thanh toán',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _PaymentMethodPicker(
                selected: selectedPaymentMethod,
                onChanged: onPaymentMethodChanged,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Thanh toán sẽ được xử lý sau khi có nhân viên nhận đơn.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodPicker({required this.selected, required this.onChanged});

  PaymentMethodOption get _current =>
      kPaymentMethods.firstWhere((option) => option.method == selected);

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<PaymentMethod>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('Chọn phương thức thanh toán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            ...kPaymentMethods.map((option) {
              final isSelected = option.method == selected;
              return ListTile(
                leading: Icon(option.icon, color: isSelected ? kPrimary : Colors.grey.shade600),
                title: Text(option.label,
                    style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: kPrimary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option.method),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final option = _current;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
          color: kPrimary.withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            Icon(option.icon, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const Text('Thay đổi',
                style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more_rounded, color: kPrimary),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
