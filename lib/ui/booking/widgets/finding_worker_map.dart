import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/worker.dart';
import 'nearby_workers_google_map.dart';

/// Immediate-booking "finding a worker" view: a stylized GPS map with the client at the centre and
/// nearby eligible workers around them, a countdown progress bar (the search time limit), and a
/// Grab-style draggable sheet that reveals the request details when pulled up.
class FindingWorkerMap extends StatelessWidget {
  final Booking booking;
  final List<Worker> nearbyWorkers;
  final Animation<double> progress; // 0.0 -> 1.0 across the search window
  final bool cancelling;
  final VoidCallback onCancel;

  const FindingWorkerMap({
    super.key,
    required this.booking,
    required this.nearbyWorkers,
    required this.progress,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NearbyWorkersGoogleMap(booking: booking, workers: nearbyWorkers),
        ),
        _SearchProgressBanner(progress: progress, workerCount: nearbyWorkers.length),
        _RequestDetailsSheet(booking: booking, cancelling: cancelling, onCancel: onCancel),
      ],
    );
  }
}

class _SearchProgressBanner extends StatelessWidget {
  final Animation<double> progress;
  final int workerCount;

  const _SearchProgressBanner({required this.progress, required this.workerCount});

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
                  workerCount > 0
                      ? 'Có $workerCount nhân viên ở gần đang được mời nhận đơn.'
                      : 'Đang gửi yêu cầu tới các nhân viên ở gần bạn.',
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

/// A lightweight, dependency-free map illustration: a tinted surface with faint "streets", an
/// animated radar pulse around the client, and worker markers scattered nearby.
class _MapCanvas extends StatefulWidget {
  final List<Worker> nearbyWorkers;
  const _MapCanvas({required this.nearbyWorkers});

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height * 0.42);
        return Container(
          color: const Color(0xFFEAF0F4),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _StreetsPainter())),
              // Radar pulse.
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final radius = 40 + _pulse.value * (size.shortestSide * 0.45);
                  return Positioned(
                    left: center.dx - radius,
                    top: center.dy - radius,
                    child: Container(
                      width: radius * 2,
                      height: radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimary.withValues(alpha: 0.12 * (1 - _pulse.value)),
                        border: Border.all(color: kPrimary.withValues(alpha: 0.25 * (1 - _pulse.value))),
                      ),
                    ),
                  );
                },
              ),
              // Worker markers.
              ..._workerMarkers(size, center),
              // Client marker.
              Positioned(
                left: center.dx - 22,
                top: center.dy - 22,
                child: _ClientMarker(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _workerMarkers(Size size, Offset center) {
    final workers = widget.nearbyWorkers.take(6).toList();
    if (workers.isEmpty) return const [];
    final spread = size.shortestSide * 0.32;
    return List.generate(workers.length, (i) {
      final angle = (i / workers.length) * 2 * math.pi + 0.4;
      final radius = spread * (0.55 + 0.45 * ((i % 3) / 2));
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      return Positioned(
        left: dx - 20,
        top: dy - 20,
        child: _WorkerMarker(worker: workers[i]),
      );
    });
  }
}

class _ClientMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _WorkerMarker extends StatelessWidget {
  final Worker worker;
  const _WorkerMarker({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: kPrimary, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
      ),
      child: Center(
        child: Text(
          worker.initials,
          style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6;
    const step = 72.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
