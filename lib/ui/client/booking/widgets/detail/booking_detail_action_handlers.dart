part of '../../booking_detail_screen.dart';

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
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] advance to $newStatus failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
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
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] accept failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
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
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] hideJob failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
    }
  }

  Future<void> _adjustDuration(BuildContext context, WidgetRef ref, Booking booking) async {
    var hours = 1.0;
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Điều chỉnh thời lượng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Ước tính công việc này sẽ mất ${hours.toStringAsFixed(1)} giờ.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              Slider(
                value: hours,
                min: 0.5,
                max: 12,
                divisions: 23,
                label: '${hours.toStringAsFixed(1)} giờ',
                onChanged: (value) => setSheetState(() => hours = value),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, hours),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    try {
      await ref.read(bookingRepositoryProvider).updateDuration(widget.bookingId, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thời lượng công việc.')),
        );
      }
      await _reloadFresh(ref);
    } on AppException catch (e) {
      debugPrint('[BookingDetailScreen] adjustDuration failed: ${e.code}');
      if (!context.mounted) return;
      showAppErrorSnackBar(context, e);
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
