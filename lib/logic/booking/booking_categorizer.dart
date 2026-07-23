import '../../core/constants/booking_enums.dart';
import '../../data/models/booking.dart';

const _activeStatuses = [
  BookingStatusName.awaitingWorker,
  BookingStatusName.accepted,
  BookingStatusName.onTheWay,
  BookingStatusName.inProgress,
  BookingStatusName.pendingPayment,
  BookingStatusName.rescheduleRequested,
];

const _historyStatuses = [BookingStatusName.completed, BookingStatusName.cancelled];

const _workerActiveStatuses = [
  BookingStatusName.accepted,
  BookingStatusName.onTheWay,
  BookingStatusName.inProgress,
  BookingStatusName.pendingPayment,
];

List<Booking> activeBookings(List<Booking> all) {
  return all.where((b) => _activeStatuses.contains(b.status)).toList()
    ..sort((a, b) =>
        (a.scheduledStartTime ?? DateTime(9999)).compareTo(b.scheduledStartTime ?? DateTime(9999)));
}

List<Booking> historyBookings(List<Booking> all) {
  return all.where((b) => _historyStatuses.contains(b.status)).toList()
    ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
}

List<Booking> workerActiveJobs(List<Booking> all) =>
    all.where((b) => _workerActiveStatuses.contains(b.status)).toList();

List<Booking> workerCompletedJobs(List<Booking> all) =>
    all.where((b) => b.status == BookingStatusName.completed).toList();

List<Booking> immediateAvailable(List<Booking> all) => all.where((b) => b.isImmediate).toList();

List<Booking> scheduledAvailable(List<Booking> all) => all.where((b) => !b.isImmediate).toList();

List<Booking> todaysCompletedJobs(List<Booking> all, DateTime now) {
  return all.where((b) {
    final updatedAt = b.updatedAt;
    return b.status == BookingStatusName.completed &&
        updatedAt != null &&
        updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
  }).toList();
}

double sumBookingPrices(Iterable<Booking> bookings) =>
    bookings.fold<double>(0, (sum, b) => sum + b.price);

Booking? newestByCreatedAt(List<Booking> all) {
  if (all.isEmpty) return null;
  return (all.toList()..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))))
      .first;
}
