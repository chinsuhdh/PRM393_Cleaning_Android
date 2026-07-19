part of '../booking_detail_screen.dart';

extension _BookingDetailPaymentHandlers on _BookingDetailScreenState {
  Future<void> _payNow(BuildContext context, WidgetRef ref) async {
    try {
      final paymentRepository = ref.read(paymentRepositoryProvider);
      final result = await paymentRepository.payNow(widget.bookingId);
      if (!context.mounted) return;
      final returnUrl = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => VnpayCheckoutScreen(paymentUrl: result.paymentUrl)),
      );
      if (returnUrl == null) return;
      final success = await paymentRepository.confirmVnpayReturn(returnUrl);
      ref.invalidate(bookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Thanh toán thành công!'
                : 'Thanh toán chưa thành công, vui lòng thử lại.',
          ),
        ),
      );
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] payNow failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _switchToCash(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingRepositoryProvider).switchToCash(widget.bookingId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã chuyển sang thanh toán tiền mặt.')));
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] switchToCash failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }
}
