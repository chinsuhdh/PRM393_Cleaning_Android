
class ErrorCodes {
  const ErrorCodes._();

  static const String network = 'NETWORK_ERROR';

  static const String workerSuspended = 'WORKER_SUSPENDED';
  static const String workerInvalidOnlineStatusTransition =
      'WORKER_INVALID_ONLINE_STATUS_TRANSITION';

  static const String quoteStale = 'QUOTE_STALE';
  static const String bookingAcceptFailed = 'BOOKING_ACCEPT_FAILED';
  static const String bookingNotFound = 'BOOKING_NOT_FOUND';
  static const String rescheduleAlreadyPending = 'RESCHEDULE_ALREADY_PENDING';

  static const String authAccountNotActive = 'AUTH_ACCOUNT_NOT_ACTIVE';

  static const String reviewSelfNotAllowed = 'REVIEW_SELF_NOT_ALLOWED';
  static const String reviewBookingNotCompleted = 'REVIEW_BOOKING_NOT_COMPLETED';
  static const String reviewAlreadyExists = 'REVIEW_ALREADY_EXISTS';
}
