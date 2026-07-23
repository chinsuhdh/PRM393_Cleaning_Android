part of '../../booking_detail_screen.dart';

extension _BookingDetailCancellationHandlers on _BookingDetailScreenState {
  Future<void> _cancelByClient(BuildContext context, WidgetRef ref) async {
    _selfCancelling = true;
    try {
      await ref.read(bookingRepositoryProvider).cancelBookingByClient(widget.bookingId);
      ref.invalidate(bookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn đặt lịch.')));
      await _reloadFresh(ref);
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] cancelByClient failed: ${e.code}');
      _selfCancelling = false;
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
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
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] workerCancelWithReason failed: ${e.code}');
      if (e.code == ErrorCodes.workerSuspended) {
        ref.invalidate(workerProfileProvider);
        if (!context.mounted) return;
        showAppErrorSnackBar(context, e);
        await _reloadFresh(ref);
        return;
      }
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
    }
  }

  Future<void> _clientCancelWithReason(
    BuildContext context,
    WidgetRef ref,
    String reasonCode,
    String? freeText,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).clientCancelBooking(
            widget.bookingId,
            reasonCode,
            freeText: freeText,
          );
      ref.invalidate(bookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã hủy đơn, đang tìm nhân viên khác.')));
      await _reloadFresh(ref);
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] clientCancelWithReason failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
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
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] reportBooking failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
    }
  }
}
