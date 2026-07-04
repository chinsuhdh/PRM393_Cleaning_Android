class BookingStatusName {
  const BookingStatusName._();

  static const String pendingPayment = 'PendingPayment';
  static const String paidPendingWorker = 'PaidPendingWorker';
  static const String accepted = 'Accepted';
  static const String rescheduleRequested = 'RescheduleRequested';
  static const String inProgress = 'InProgress';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String refunded = 'Refunded';
  static const String awaitingWorker = 'AwaitingWorker';

  static const List<String> ordered = [
    pendingPayment,
    paidPendingWorker,
    accepted,
    rescheduleRequested,
    inProgress,
    completed,
    cancelled,
    refunded,
    awaitingWorker,
  ];
}

class BookingTypeName {
  const BookingTypeName._();

  static const String scheduled = 'Scheduled';
  static const String immediate = 'Immediate';
}
