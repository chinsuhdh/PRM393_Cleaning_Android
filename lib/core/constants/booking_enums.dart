/// Backend `BookingStatus` values, serialized by name. Pay-after-job lifecycle:
/// AwaitingWorker -> Accepted -> OnTheWay -> InProgress -> PendingPayment -> Completed.
class BookingStatusName {
  const BookingStatusName._();

  static const String awaitingWorker = 'AwaitingWorker';
  static const String accepted = 'Accepted';
  static const String onTheWay = 'OnTheWay';
  static const String inProgress = 'InProgress';
  static const String pendingPayment = 'PendingPayment';
  static const String completed = 'Completed';
  static const String rescheduleRequested = 'RescheduleRequested';
  static const String cancelled = 'Cancelled';
}

class BookingTypeName {
  const BookingTypeName._();

  static const String scheduled = 'Scheduled';
  static const String immediate = 'Immediate';
}

const Map<String, int> kCoreActiveBookingRank = {
  BookingStatusName.inProgress: 0,
  BookingStatusName.onTheWay: 1,
  BookingStatusName.pendingPayment: 2,
  BookingStatusName.accepted: 3,
  BookingStatusName.rescheduleRequested: 4,
};
