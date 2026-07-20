import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/directions_service.dart' show formatDuration;
import '../booking/widgets/booking_info_cards.dart' show bookingQuestionRows;
import 'popup_menu_action_item.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

/// Which screen a [BookingCard] renders for — controls which role-specific sections show.
enum BookingCardRole { customer, worker }

Color statusColor(String status) {
  switch (status) {
    case BookingStatusName.awaitingWorker:
    case BookingStatusName.accepted:
    case BookingStatusName.onTheWay:
    case BookingStatusName.inProgress:
    case BookingStatusName.pendingPayment:
    case BookingStatusName.rescheduleRequested:
      return kPrimary;
    case BookingStatusName.completed:
      return kSecondary;
    case BookingStatusName.cancelled:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Color statusBgColor(String status) {
  switch (status) {
    case BookingStatusName.awaitingWorker:
    case BookingStatusName.accepted:
    case BookingStatusName.onTheWay:
    case BookingStatusName.inProgress:
    case BookingStatusName.pendingPayment:
    case BookingStatusName.rescheduleRequested:
      return kPrimaryContainer;
    case BookingStatusName.completed:
      return kSecondaryContainer;
    case BookingStatusName.cancelled:
      return kErrorContainer;
    default:
      return Colors.grey.shade200;
  }
}

/// Icon + centered message empty state shared by the customer and worker booking lists.
Widget bookingListEmptyState(BuildContext context, String message) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(message, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }
}

/// A single booking list card shared by the customer's "Đơn của tôi" screen and the worker's
/// "Việc của tôi" screen, so both stay visually consistent. [role] controls which extra sections
/// render: the customer's assigned-worker footer vs. the worker's distance/duration/photo chips,
/// question-answer chips, address+map row, and accept/status action.
class BookingCard extends ConsumerWidget {
  final Booking booking;
  final BookingCardRole role;
  final bool isAvailableJob;
  final VoidCallback? onHide;

  const BookingCard({
    super.key,
    required this.booking,
    required this.role,
    this.isAvailableJob = false,
    this.onHide,
  });

  bool get _needsVnpayPayment =>
      role == BookingCardRole.customer &&
      booking.status == BookingStatusName.pendingPayment &&
      PaymentMethodApi.fromApiName(booking.paymentMethod) == PaymentMethod.vnpay;

  Future<void> _openGoogleMaps(BuildContext context, double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ. Vui lòng kiểm tra lại điện thoại.')),
        );
      }
    } catch (e) {
      debugPrint('[BookingCard] openGoogleMaps failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ.')));
      }
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(booking.id);
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhận đơn thành công!')));
      }
    } on BookingNoLongerAvailableException {
      debugPrint('[BookingCard] acceptBooking failed: booking no longer available');
      ref.invalidate(availableBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rất tiếc, đơn này vừa có người khác nhận mất rồi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('[BookingCard] acceptBooking failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isWorker = role == BookingCardRole.worker;

    return Card(
      elevation: 0,
      color: isWorker && isAvailableJob ? kPrimaryContainer : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/booking/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isWorker && isAvailableJob ? kOnPrimaryContainer : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor(booking.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bookingStatusLabel(booking.status),
                      style: TextStyle(color: statusColor(booking.status), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  if (isWorker && onHide != null)
                    PopupMenuButton<String>(
                      tooltip: 'Tuỳ chọn',
                      icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                      onSelected: (value) {
                        if (value == 'hide') onHide!();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'hide',
                          child: PopupMenuActionItem(icon: Icons.visibility_off_rounded, label: 'Ẩn công việc này'),
                        ),
                      ],
                    ),
                ],
              ),
              if (_needsVnpayPayment) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded, size: 14, color: Colors.orange.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'Cần thanh toán',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: kPrimary),
                  const SizedBox(width: 6),
                  Text(booking.date, style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time_rounded, size: 16, color: kPrimary),
                  const SizedBox(width: 6),
                  Text(booking.time, style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _vnd.format(booking.price),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary),
              ),
              if (!isWorker) ..._customerWorkerFooter(theme),
              if (isWorker) ..._workerDetails(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _customerWorkerFooter(ThemeData theme) {
    if (booking.worker == null) return const [];
    return [
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kTertiaryContainer,
                child: Text(
                  booking.worker!.initials,
                  style: const TextStyle(color: kOnTertiaryContainer, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhân viên phụ trách',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(booking.worker!.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          Text(
            _vnd.format(booking.price),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: kPrimary),
          ),
        ],
      ),
    ];
  }

  List<Widget> _workerDetails(BuildContext context, ThemeData theme) {
    return [
      const SizedBox(height: 10),
      Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          if (booking.distanceKm != null)
            _MetaChip(icon: Icons.social_distance_rounded, label: '${booking.distanceKm!.toStringAsFixed(1)} km'),
          if (booking.estimatedMinutes != null)
            _MetaChip(
              icon: Icons.directions_run_rounded,
              label: formatDuration(Duration(minutes: booking.estimatedMinutes!.round())),
            ),
          _MetaChip(icon: Icons.timelapse_rounded, label: '${booking.durationHours.toStringAsFixed(1)} giờ'),
          if (booking.photos.isNotEmpty)
            _MetaChip(icon: Icons.photo_camera_rounded, label: '${booking.photos.length} ảnh'),
        ],
      ),
      if (booking.bookingQuestions.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: bookingQuestionRows(booking).take(2).map((row) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${row.$1}: ${row.$2}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                booking.addressText ?? 'Chưa xác định địa chỉ',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (booking.latitude != null && booking.longitude != null)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.map_rounded, color: kPrimary),
                  tooltip: 'Chỉ đường',
                  onPressed: () => _openGoogleMaps(context, booking.latitude, booking.longitude),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (isAvailableJob)
        Consumer(
          builder: (context, ref, _) => FilledButton(
            onPressed: () => _accept(context, ref),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('Nhận việc'),
          ),
        )
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: booking.status == BookingStatusName.completed
                ? Colors.green.withValues(alpha: 0.1)
                : kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bookingStatusLabel(booking.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: booking.status == BookingStatusName.completed ? Colors.green : kPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ];
  }
}
