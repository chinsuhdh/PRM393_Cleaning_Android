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
}
