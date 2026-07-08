import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/booking_enums.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import 'booking_review_section.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

List<Widget> buildBookingDetailContent(ThemeData theme, Booking booking, UserRole role) {
  final isCompleted = booking.status == BookingStatusName.completed;
  return [
    _summaryCard(theme, booking),
    const SizedBox(height: 20),
    if (isCompleted && booking.latitude != null && booking.longitude != null) ...[
      CompletedJobLocationCard(booking: booking),
      const SizedBox(height: 16),
    ],
    BookingInfoCard(title: 'Thông tin đặt lịch', rows: bookingTripInfoRows(booking)),
    const SizedBox(height: 16),
    BookingPriceCard(booking: booking),
    if (booking.bookingQuestions.isNotEmpty) ...[
      const SizedBox(height: 16),
      BookingInfoCard(title: 'Yêu cầu dịch vụ', rows: bookingQuestionRows(booking)),
    ],
    if (booking.photos.isNotEmpty) ...[const SizedBox(height: 16), _photosRow(booking)],
    if (booking.worker != null) ...[const SizedBox(height: 16), _WorkerCard(theme: theme, booking: booking)],
    if (isCompleted && booking.worker != null) ...[
      const SizedBox(height: 16),
      BookingReviewSection(booking: booking, viewerRole: role),
    ],
  ];
}

Widget _summaryCard(ThemeData theme, Booking booking) => Card(
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
                  Text(booking.serviceName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800, color: kOnPrimaryContainer)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                    child: Text(booking.status,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

List<(String, String)> bookingTripInfoRows(Booking booking) => [
      (
        'Ngày & Giờ',
        booking.isImmediate
            ? 'Ngay bây giờ'
            : [booking.date, booking.time].where((v) => v.isNotEmpty).join(' • '),
      ),
      ('Thời lượng', '${booking.durationHours.toStringAsFixed(1)} giờ'),
      if (booking.addressText?.isNotEmpty == true) ('Địa chỉ', booking.addressText!),
      if (booking.notes.isNotEmpty) ('Ghi chú', booking.notes),
    ];

List<(String, String)> bookingQuestionRows(Booking booking) => booking.bookingQuestions.map((question) {
      final id = question['id']?.toString() ?? question['key']?.toString() ?? '';
      final label = question['label']?.toString() ?? question['title']?.toString() ?? id;
      final answer = booking.optionAnswers[id];
      return (label, answer == null ? 'Chưa có thông tin' : _formatAnswer(answer));
    }).toList();

String _formatAnswer(Object answer) {
  if (answer is bool) return answer ? 'Có' : 'Không';
  if (answer is List) return answer.join(', ');
  return answer.toString();
}

Widget _photosRow(Booking booking) => SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: booking.photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(booking.photos[index]['photoUrl'].toString(), width: 96, fit: BoxFit.cover),
        ),
      ),
    );

class _WorkerCard extends StatelessWidget {
  final ThemeData theme;
  final Booking booking;
  const _WorkerCard({required this.theme, required this.booking});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: (booking.worker!.avatarUrl?.isNotEmpty ?? false)
              ? CircleAvatar(backgroundImage: NetworkImage(booking.worker!.avatarUrl!))
              : CircleAvatar(
                  backgroundColor: kPrimaryContainer,
                  child: Text(booking.worker!.initials,
                      style: const TextStyle(color: kOnPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
          title: Text(booking.worker!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: kTertiary),
              const SizedBox(width: 4),
              Text('${booking.worker!.rating} · ${booking.worker!.reviews} đánh giá'),
            ],
          ),
        ),
      );
}

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

class CompletedJobLocationCard extends StatelessWidget {
  const CompletedJobLocationCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final location = LatLng(booking.latitude!, booking.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          key: const ValueKey('completed-job-location-map'),
          options: MapOptions(
            initialCenter: location,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: _osmTileUrlTemplate,
              userAgentPackageName: _osmUserAgentPackageName,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  key: const ValueKey('job-location'),
                  point: location,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_pin, color: kPrimary, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingInfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const BookingInfoCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(rows[i].$1,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rows[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class BookingPriceCard extends StatelessWidget {
  final Booking booking;
  const BookingPriceCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giá', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _line(theme, 'Đơn giá', booking.unitPrice),
            if (booking.extraFee != 0) _line(theme, 'Phụ phí', booking.extraFee),
            if (booking.discountAmount != 0) _line(theme, 'Giảm giá', -booking.discountAmount),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng cộng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(_vnd.format(booking.price),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, String label, double amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            Text('${amount < 0 ? '-' : ''}${_vnd.format(amount.abs())}'),
          ],
        ),
      );
}
