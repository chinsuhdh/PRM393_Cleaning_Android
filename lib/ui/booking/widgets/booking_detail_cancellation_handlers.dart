part of '../booking_detail_screen.dart';

extension _BookingDetailCancellationHandlers on _BookingDetailScreenState {
  Future<void> _cancelByClient(BuildContext context, WidgetRef ref) async {
    _selfCancelling = true;
    try {
      await ref.read(bookingRepositoryProvider).cancelBookingByClient(widget.bookingId);
      ref.invalidate(bookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn đặt lịch.')));
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] cancelByClient failed: $e');
      _selfCancelling = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _workerCancelWithReason(
    BuildContext context,
    WidgetRef ref,
    String reasonCode,
    String? freeText,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).workerCancelBooking(
            widget.bookingId,
            reasonCode,
            freeText: freeText,
          );
      ref.invalidate(workerBookingsProvider);
      ref.invalidate(availableBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã hủy nhận việc và trả đơn về danh sách chờ.')));
      await _reloadFresh(ref);
    } on WorkerSuspendedException {
      ref.invalidate(workerProfileProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản của bạn đã bị tạm khóa do hủy việc quá nhiều lần.'),
          backgroundColor: Colors.red,
        ),
      );
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] workerCancelWithReason failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reportBooking(
    BuildContext context,
    WidgetRef ref,
    String reasonCode,
    String freeText,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).reportBooking(widget.bookingId, reasonCode, freeText);
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo, đơn đã được hủy.')));
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] reportBooking failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi báo cáo: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
