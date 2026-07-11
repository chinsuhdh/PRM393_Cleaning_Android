part of '../booking_detail_screen.dart';

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
    } on RescheduleAlreadyPendingException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã có một yêu cầu dời lịch đang chờ phản hồi.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('[BookingDetailScreen] proposeReschedule failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
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
    } catch (e) {
      debugPrint('[BookingDetailScreen] respondReschedule failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }
}
