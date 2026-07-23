import '../../data/models/booking.dart';

Booking? selectActiveBooking(List<Booking> bookings, Map<String, int> statusRank) {
  final ranked = bookings.where((b) => statusRank.containsKey(b.status)).toList()
    ..sort((a, b) {
      final rank = statusRank[a.status]!.compareTo(statusRank[b.status]!);
      if (rank != 0) return rank;
      return (a.scheduledStartTime ?? DateTime(9999)).compareTo(b.scheduledStartTime ?? DateTime(9999));
    });
  return ranked.isEmpty ? null : ranked.first;
}
