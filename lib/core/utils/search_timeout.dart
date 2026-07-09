import '../../data/models/booking.dart';

DateTime? searchStartedAt(Booking booking) {
  final created = booking.createdAt;
  final updated = booking.updatedAt;
  if (created == null) return updated;
  if (updated == null) return created;
  return updated.isAfter(created) ? updated : created;
}

Duration searchElapsed(Booking booking) {
  final startedAt = searchStartedAt(booking);
  if (startedAt == null) return Duration.zero;
  final elapsed = DateTime.now().difference(startedAt);
  return elapsed.isNegative ? Duration.zero : elapsed;
}

String formatSearchElapsed(Booking booking) {
  final elapsed = searchElapsed(booking);
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes % 60;
  final seconds = elapsed.inSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
