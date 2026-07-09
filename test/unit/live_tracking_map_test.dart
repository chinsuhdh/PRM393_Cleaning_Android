import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/ui/booking/widgets/live_tracking_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onTheWayDistanceMeters', () {
    test('[UT-FE-LIVEMAP-01] computes a real distance when both the worker and destination have coordinates', () {
      const booking = Booking(
        id: 'b1', serviceName: 'Home Cleaning', date: '', time: '', price: 0,
        status: BookingStatusName.onTheWay,
        latitude: 10.7769, longitude: 106.7009,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8, latitude: 10.7731, longitude: 106.6980),
      );

      final distance = onTheWayDistanceMeters(booking);

      expect(distance, isNotNull);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(1000)); // these two points are a few hundred meters apart
    });

    test('[UT-FE-LIVEMAP-02] returns null when the worker has no reported position yet', () {
      const booking = Booking(
        id: 'b1', serviceName: 'Home Cleaning', date: '', time: '', price: 0,
        status: BookingStatusName.onTheWay,
        latitude: 10.7769, longitude: 106.7009,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );

      expect(onTheWayDistanceMeters(booking), isNull);
    });

    test('[UT-FE-LIVEMAP-03] returns null when the job address has no coordinates', () {
      const booking = Booking(
        id: 'b1', serviceName: 'Home Cleaning', date: '', time: '', price: 0,
        status: BookingStatusName.onTheWay,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8, latitude: 10.7731, longitude: 106.6980),
      );

      expect(onTheWayDistanceMeters(booking), isNull);
    });
  });

  group('formatDistance', () {
    test('[UT-FE-LIVEMAP-04] renders sub-kilometer distances in meters', () {
      expect(formatDistance(450), '450 m');
    });

    test('[UT-FE-LIVEMAP-05] renders 1km+ distances in kilometers with one decimal', () {
      expect(formatDistance(1500), '1.5 km');
    });
  });
}
