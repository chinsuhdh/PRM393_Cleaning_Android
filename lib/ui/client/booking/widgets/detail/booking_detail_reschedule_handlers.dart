part of '../../booking_detail_screen.dart';

extension _BookingDetailRescheduleHandlers on _BookingDetailScreenState {
  Future<void> _proposeReschedule(
    BuildContext context,
    WidgetRef ref,
    DateTime newStartTime,
    String? message,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).proposeReschedule(widget.bookingId, newStartTime, message: message);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã gửi đề nghị dời lịch.')));
      await _reloadFresh(ref);
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] proposeReschedule failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
    }
  }

  Future<void> _respondReschedule(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String action,
  ) async {
    try {
      await ref.read(bookingRepositoryProvider).respondReschedule(widget.bookingId, requestId, action);
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      await _reloadFresh(ref);
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] respondReschedule failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
    }
  }
}
