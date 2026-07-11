import 'package:cleanai/data/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '[UT-FE-BOOKMODEL-01] parses scheduledStartTime into formatted date and time',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'Accepted',
        'scheduledStartTime': '2026-07-06T09:30:00',
      });

      expect(booking.date, '06/07/2026');
      expect(booking.time, '09:30');
    },
  );

  test(
    '[UT-FE-BOOKMODEL-02] falls back to the scheduledTime key when scheduledStartTime is absent',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'Accepted',
        'scheduledTime': '2026-01-02T18:05:00',
      });

      expect(booking.date, '02/01/2026');
      expect(booking.time, '18:05');
    },
  );

  test(
    '[UT-FE-BOOKMODEL-03] parses a nested worker object',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'Accepted',
        'worker': {'id': 'w1', 'name': 'Anh Ba', 'rating': 4.5},
      });

      expect(booking.worker, isNotNull);
      expect(booking.worker!.name, 'Anh Ba');
    },
  );

  test(
    '[UT-FE-BOOKMODEL-04] derives serviceName from the nested service object',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'status': 'Accepted',
        'service': {'name': 'Vệ sinh máy lạnh'},
      });

      expect(booking.serviceName, 'Vệ sinh máy lạnh');
    },
  );

  test(
    '[UT-FE-BOOKMODEL-05] falls back to a serviceId-based name when no name is present',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'status': 'Accepted',
        'serviceId': 'abcdef1234567890',
      });

      expect(booking.serviceName, 'Dịch vụ #abcdef12');
    },
  );

  test(
    '[UT-FE-BOOKMODEL-06] parses address text, coordinates, price and type getters',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'AwaitingWorker',
        'bookingType': 'Immediate',
        'totalPrice': 250000,
        'addressText': 'Quận 1, TP.HCM',
        'latitude': 10.7769,
        'longitude': 106.7009,
      });

      expect(booking.addressText, 'Quận 1, TP.HCM');
      expect(booking.latitude, 10.7769);
      expect(booking.longitude, 106.7009);
      expect(booking.price, 250000);
      expect(booking.isImmediate, isTrue);
      expect(booking.isAwaitingWorker, isTrue);
      expect(booking.hasWorkerAssigned, isFalse);
    },
  );

  test(
    '[UT-FE-BOOKMODEL-08] parses createdAt so the newest posted job can be identified',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'AwaitingWorker',
        'createdAt': '2026-07-06T10:15:00Z',
      });

      expect(booking.createdAt, DateTime.parse('2026-07-06T10:15:00Z').toLocal());
    },
  );

  test(
    '[UT-FE-BOOKMODEL-07] hasWorkerAssigned is true for Accepted/InProgress/Completed',
    () {
      Booking withStatus(String status) => Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': status,
      });

      expect(withStatus('Accepted').hasWorkerAssigned, isTrue);
      expect(withStatus('InProgress').hasWorkerAssigned, isTrue);
      expect(withStatus('Completed').hasWorkerAssigned, isTrue);
      expect(withStatus('AwaitingWorker').hasWorkerAssigned, isFalse);
    },
  );

  test(
    '[UT-FE-BOOKMODEL-09] parses pendingReschedule and rescheduleHistory (H.3)',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'RescheduleRequested',
        'pendingReschedule': {
          'id': 'r1',
          'requestedBy': 'client-1',
          'oldStartTime': '2026-07-10T09:00:00Z',
          'oldEndTime': '2026-07-10T11:00:00Z',
          'newStartTime': '2026-07-12T09:00:00Z',
          'newEndTime': '2026-07-12T11:00:00Z',
          'status': 'Pending',
          'reason': 'Bận việc đột xuất',
          'createdAt': '2026-07-09T08:00:00Z',
        },
        'rescheduleHistory': [
          {
            'id': 'r0',
            'requestedBy': 'client-1',
            'oldStartTime': '2026-07-08T09:00:00Z',
            'oldEndTime': '2026-07-08T11:00:00Z',
            'newStartTime': '2026-07-09T09:00:00Z',
            'newEndTime': '2026-07-09T11:00:00Z',
            'status': 'Rejected',
          },
        ],
      });

      expect(booking.pendingReschedule, isNotNull);
      expect(booking.pendingReschedule!.id, 'r1');
      expect(booking.pendingReschedule!.isPending, isTrue);
      expect(booking.pendingReschedule!.reason, 'Bận việc đột xuất');
      expect(booking.rescheduleHistory, hasLength(1));
      expect(booking.rescheduleHistory.first.status, 'Rejected');
      expect(booking.rescheduleHistory.first.isPending, isFalse);
    },
  );

  test(
    '[UT-FE-BOOKMODEL-10] pendingReschedule and rescheduleHistory default to null/empty when absent',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': 'Accepted',
      });

      expect(booking.pendingReschedule, isNull);
      expect(booking.rescheduleHistory, isEmpty);
    },
  );
}
