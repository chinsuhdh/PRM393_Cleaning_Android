import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/booking.dart';
// ĐÃ FIX: Thêm import Repository để dùng các provider
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/booking_enums.dart';
import 'widgets/booking_action_bar.dart';

// API Gọi chi tiết Booking bằng ID
final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>((ref, id) async {
  final response = await DioClient.instance.get('/Bookings/$id');
  return Booking.fromJson(response.data);
});

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Detail', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải dữ liệu: $e')),
        data: (booking) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  color: kPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.cleaning_services_rounded, size: 48, color: kPrimary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.serviceName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: kOnPrimaryContainer)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                                child: Text(booking.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Booking Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: booking.date),
                _DetailRow(icon: Icons.access_time_rounded, label: 'Time', value: booking.time),
                // ĐÃ FIX: Dùng `booking.price` theo chuẩn model cũ của bạn
                _DetailRow(icon: Icons.attach_money_rounded, label: 'Total', value: '${booking.price} VND'),
                if (booking.statusTimeline.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Status timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ...booking.statusTimeline.map((entry) => ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: kPrimary),
                    title: Text(entry['newStatus']?.toString() ?? ''),
                    subtitle: Text(entry['reason']?.toString() ?? ''),
                  )),
                ],
                if (booking.photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: booking.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => Image.network(
                        booking.photos[index]['photoUrl'].toString(),
                        width: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                if (booking.worker != null) ...[
                  Text('Assigned Worker', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryContainer,
                        child: Text(booking.worker!.initials, style: const TextStyle(color: kOnPrimaryContainer, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(booking.worker!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: kTertiary),
                          const SizedBox(width: 4),
                          Text('${booking.worker!.rating} · ${booking.worker!.reviews} reviews'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: kPrimary),
                        onPressed: () => context.push('/chat'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Đang chờ AI điều phối nhân viên...', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ),
                  )
                ],

                BookingActionBar(
                  status: booking.status,
                  viewerRole: ref.watch(authProvider).role,
                  isScheduled: booking.bookingType == BookingTypeName.scheduled,
                  onChat: () => context.push('/chat'),
                  onGoingThere: () => _advance(context, ref, BookingStatusName.onTheWay),
                  onStart: () => _advance(context, ref, BookingStatusName.inProgress),
                  onFinish: () => _advance(context, ref, BookingStatusName.pendingPayment),
                  onConfirmCash: () => _advance(context, ref, BookingStatusName.completed),
                  onReleaseJob: () => _advance(context, ref, BookingStatusName.awaitingWorker),
                  onReport: (reason) => _cancel(context, ref, reason),
                  onRequestReschedule: () => _advance(context, ref, BookingStatusName.rescheduleRequested),
                  onApproveReschedule: () => _advance(context, ref, BookingStatusName.accepted),
                  onPayNow: () => context.push('/payment/${booking.id}'),
                  onReview: () => context.push('/review/${booking.id}'),
                  onViewEarning: () => context.push('/worker/wallet'),
                  onViewReason: () => _showCancellationReason(context, booking),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(bookingId, newStatus);
      ref.invalidate(bookingDetailProvider(bookingId));
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String reason) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            bookingId,
            BookingStatusName.cancelled,
            reason: reason.isEmpty ? null : reason,
          );
      ref.invalidate(bookingDetailProvider(bookingId));
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy Booking thành công!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kPrimaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
