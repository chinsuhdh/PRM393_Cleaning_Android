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

/// Short Vietnamese label for a status badge/pill — distinct from the longer descriptive
/// sentences used elsewhere (e.g. active_booking_bar.dart's "Nhân viên đang trên đường đến").
String bookingStatusLabel(String status) {
  switch (status) {
    case BookingStatusName.awaitingWorker:
      return 'Chờ nhận đơn';
    case BookingStatusName.accepted:
      return 'Đã nhận đơn';
    case BookingStatusName.onTheWay:
      return 'Đang đến';
    case BookingStatusName.inProgress:
      return 'Đang thực hiện';
    case BookingStatusName.pendingPayment:
      return 'Chờ thanh toán';
    case BookingStatusName.completed:
      return 'Hoàn thành';
    case BookingStatusName.rescheduleRequested:
      return 'Yêu cầu đổi lịch';
    case BookingStatusName.cancelled:
      return 'Đã huỷ';
    default:
      return status;
  }
}

const Map<String, int> kCoreActiveBookingRank = {
  BookingStatusName.inProgress: 0,
  BookingStatusName.onTheWay: 1,
  BookingStatusName.pendingPayment: 2,
  BookingStatusName.accepted: 3,
  BookingStatusName.rescheduleRequested: 4,
};
