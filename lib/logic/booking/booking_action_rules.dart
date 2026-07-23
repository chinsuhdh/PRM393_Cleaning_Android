import '../../core/constants/booking_enums.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/constants/user_role.dart';
import '../../data/models/booking.dart';

enum BookingPrimaryAction {
  accept,
  goingThere,
  start,
  finish,
  confirmCash,
  payNow,
}

enum BookingSecondaryAction {
  cancelByClient,
  cancelAndRetry,
  payCashHint,
  switchToCashLink,
  waitingForClientHint,
  viewEarning,
  viewReason,
}

enum BookingOverflowAction {
  hideJob,
  workerCancel,
  clientCancel,
  adjustDuration,
  report,
}

class BookingActionPlan {
  const BookingActionPlan({
    this.showChat = false,
    this.showReschedule = false,
    this.primary,
    this.secondary,
    this.overflow = const [],
  });

  final bool showChat;
  final bool showReschedule;
  final BookingPrimaryAction? primary;
  final BookingSecondaryAction? secondary;
  final List<BookingOverflowAction> overflow;
}

BookingActionPlan computeBookingActionPlan({
  required String status,
  required UserRole viewerRole,
  required bool isScheduled,
  required PaymentMethod paymentMethod,
  required bool hasAcceptHandler,
  required bool hasHideJobHandler,
}) {
  final isClient = viewerRole == UserRole.client;
  final isWorker = viewerRole == UserRole.worker;
  var showChat = false;
  var showReschedule = false;
  BookingPrimaryAction? primary;
  BookingSecondaryAction? secondary;
  final overflow = <BookingOverflowAction>[];

  switch (status) {
    case BookingStatusName.awaitingWorker:
      if (isClient) {
        secondary = isScheduled ? BookingSecondaryAction.cancelByClient : BookingSecondaryAction.cancelAndRetry;
      }
      if (isWorker && hasAcceptHandler) primary = BookingPrimaryAction.accept;
      if (isWorker && hasHideJobHandler) overflow.add(BookingOverflowAction.hideJob);

    case BookingStatusName.accepted:
      showChat = true;
      showReschedule = isScheduled;
      if (isWorker) {
        primary = BookingPrimaryAction.goingThere;
        overflow.add(BookingOverflowAction.workerCancel);
      }
      if (isClient) {
        overflow.add(BookingOverflowAction.adjustDuration);
        overflow.add(BookingOverflowAction.clientCancel);
      }
      overflow.add(BookingOverflowAction.report);

    case BookingStatusName.rescheduleRequested:
      showChat = true;

    case BookingStatusName.onTheWay:
      showChat = true;
      if (isWorker) primary = BookingPrimaryAction.start;
      if (isClient) overflow.add(BookingOverflowAction.adjustDuration);
      overflow.add(BookingOverflowAction.report);

    case BookingStatusName.inProgress:
      showChat = true;
      if (isWorker) primary = BookingPrimaryAction.finish;
      if (isClient) overflow.add(BookingOverflowAction.adjustDuration);
      overflow.add(BookingOverflowAction.report);

    case BookingStatusName.pendingPayment:
      showChat = true;
      final isCash = paymentMethod == PaymentMethod.cash;
      if (isCash) {
        if (isWorker) {
          primary = BookingPrimaryAction.confirmCash;
        } else {
          secondary = BookingSecondaryAction.payCashHint;
        }
      } else if (isClient) {
        primary = BookingPrimaryAction.payNow;
        secondary = BookingSecondaryAction.switchToCashLink;
      } else {
        secondary = BookingSecondaryAction.waitingForClientHint;
      }
      overflow.add(BookingOverflowAction.report);

    case BookingStatusName.completed:
      showChat = true;
      if (isWorker) secondary = BookingSecondaryAction.viewEarning;

    case BookingStatusName.cancelled:
      showChat = true;
      secondary = BookingSecondaryAction.viewReason;
  }

  return BookingActionPlan(
    showChat: showChat,
    showReschedule: showReschedule,
    primary: primary,
    secondary: secondary,
    overflow: overflow,
  );
}

bool needsVnpayPayment(Booking booking, {required bool isCustomer}) =>
    isCustomer &&
    booking.status == BookingStatusName.pendingPayment &&
    PaymentMethodApi.fromApiName(booking.paymentMethod) == PaymentMethod.vnpay;
