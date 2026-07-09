part of '../booking_detail_screen.dart';

extension _BookingDetailActionHandlers on _BookingDetailScreenState {
  Future<void> _retryAsNewBooking(BuildContext context, WidgetRef ref, Booking booking) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            BookingStatusName.cancelled,
            reason: 'Khách hàng muốn đặt lại yêu cầu mới.',
          );
      ref.invalidate(bookingsProvider);
    } catch (e) {
      debugPrint('[BookingDetailScreen] retry pre-cancel failed: $e');
    }
    if (!context.mounted) return;
    context.pushReplacement('/booking/create/${booking.serviceId}');
  }

  Future<void> _showCancelledByOtherPartyPopup() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đơn đã bị hủy'),
        content: const Text('Đơn đặt lịch này đã bị hủy.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đã hiểu')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _reloadFresh(WidgetRef ref) async {
    ref.invalidate(bookingDetailProvider(widget.bookingId));
    if (!mounted) return;
    if (_showingMapLayout && !_mapTornDown) {
      _markMapTornDown();
      await WidgetsBinding.instance.endOfFrame;
      for (var i = 0; i < 8; i++) {
        if (!mounted) return;
        _rebuild();
        await WidgetsBinding.instance.endOfFrame;
      }
    }
    if (!mounted) return;
    context.pushReplacement('/booking/${widget.bookingId}', extra: kBookingDetailSkipTransitionExtra);
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(widget.bookingId, newStatus);
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] advance to $newStatus failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(widget.bookingId);
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhận đơn thành công!')),
        );
      }
      await _reloadFresh(ref);
    } catch (error) {
      debugPrint('[BookingDetailScreen] accept failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String reason) async {
    _selfCancelling = true;
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            BookingStatusName.cancelled,
            reason: reason.isEmpty ? null : reason,
          );
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy Booking thành công!')));
      await _reloadFresh(ref);
    } catch (e) {
      debugPrint('[BookingDetailScreen] cancel failed: $e');
      _selfCancelling = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _hideJob(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dispatchRepositoryProvider).hideBooking(widget.bookingId);
      ref.invalidate(availableBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ẩn công việc này.')),
      );
      context.pop();
    } catch (error) {
      debugPrint('[BookingDetailScreen] hideJob failed: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCancellationReason(BuildContext context, Booking booking) {
    final cancelEntry = booking.statusTimeline.lastWhere(
      (entry) => entry['newStatus']?.toString() == BookingStatusName.cancelled,
      orElse: () => const {},
    );
    final reason = (cancelEntry['reason'] as String?)?.trim();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lý do hủy đơn'),
        content: Text(reason == null || reason.isEmpty ? 'Không có lý do được cung cấp.' : reason),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
