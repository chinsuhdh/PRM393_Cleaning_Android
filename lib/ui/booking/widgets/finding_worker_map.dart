import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import 'nearby_workers_google_map.dart';

/// Immediate-booking "finding a worker" view: a map centred on the job address, a countdown
/// progress bar (the search time limit), and a Grab-style draggable sheet that reveals the request
/// details when pulled up. Dispatch is broadcast — candidate workers are not shown to the client.
class FindingWorkerMap extends StatelessWidget {
  final Booking booking;
  final Animation<double> progress; // 0.0 -> 1.0 across the search window
  final bool cancelling;
  final VoidCallback onCancel;

  const FindingWorkerMap({
    super.key,
    required this.booking,
    required this.progress,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NearbyWorkersGoogleMap(booking: booking),
        ),
        _SearchProgressBanner(progress: progress),
        _RequestDetailsSheet(booking: booking, cancelling: cancelling, onCancel: onCancel),
      ],
    );
  }
}

class _SearchProgressBanner extends StatelessWidget {
  final Animation<double> progress;

  const _SearchProgressBanner({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đang tìm nhân viên phù hợp…',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.value,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đang gửi yêu cầu tới các nhân viên ở gần bạn.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  final Booking booking;
  final bool cancelling;
  final VoidCallback onCancel;

  const _RequestDetailsSheet({
    required this.booking,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.16,
      maxChildSize: 0.72,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, -4)),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Chi tiết yêu cầu',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Kéo lên để xem đầy đủ thông tin đơn của bạn.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.cleaning_services_rounded, label: 'Dịch vụ', value: booking.serviceName),
              if (booking.date.isNotEmpty || booking.time.isNotEmpty)
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Thời gian',
                  value: booking.isImmediate
                      ? 'Ngay bây giờ'
                      : [booking.date, booking.time].where((v) => v.isNotEmpty).join(' • '),
                ),
              if (booking.addressText != null && booking.addressText!.isNotEmpty)
                _DetailRow(icon: Icons.location_on_rounded, label: 'Địa chỉ', value: booking.addressText!),
              _DetailRow(
                icon: Icons.payments_rounded,
                label: 'Tổng tiền',
                value: '${booking.price.toStringAsFixed(0)} ₫',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: cancelling ? null : onCancel,
                icon: cancelling
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.close_rounded),
                label: const Text('Hủy yêu cầu'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        );
      },
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
