import 'package:cleanai/data/models/worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '[UT-FE-WORKERMODEL-01] parses all fields including coordinates',
    () {
      final worker = Worker.fromJson({
        'id': 'w1',
        'name': 'Anh Ba',
        'rating': 4.5,
        'distance': '1.2 km',
        'experience': '3 năm',
        'avatarUrl': 'http://img/a.png',
        'matchPercentage': 92,
        'reviews': 120,
        'latitude': 10.77,
        'longitude': 106.70,
      });

      expect(worker.id, 'w1');
      expect(worker.name, 'Anh Ba');
      expect(worker.rating, 4.5);
      expect(worker.matchPercentage, 92);
      expect(worker.latitude, 10.77);
      expect(worker.longitude, 106.70);
      expect(worker.initials, 'A');
    },
  );

  test(
    '[UT-FE-WORKERMODEL-02] applies defaults for optional fields',
    () {
      final worker = Worker.fromJson({'id': 'w1', 'name': 'Anh Ba', 'rating': 4});

      expect(worker.distance, '');
      expect(worker.experience, '');
      expect(worker.matchPercentage, 0);
      expect(worker.reviews, 0);
      expect(worker.avatarUrl, isNull);
      expect(worker.latitude, isNull);
      expect(worker.longitude, isNull);
    },
  );

  test(
    '[UT-FE-WORKERMODEL-03] a missing rating defaults to 0 instead of throwing',
    () {
      final worker = Worker.fromJson({'id': 'w1', 'name': 'Anh Ba'});

      expect(worker.rating, 0);
    },
  );

  test(
    '[UT-FE-WORKERMODEL-04] parses the WorkerProfileDto shape from GET /Workers/me '
    '(userId/averageRating/suspendedAt, no name) without throwing (H.2)',
    () {
      final worker = Worker.fromJson({
        'userId': 'w1',
        'averageRating': 4.8,
        'onlineStatus': 'Online',
        'currentLat': 10.77,
        'currentLng': 106.70,
        'suspendedAt': '2026-07-10T08:00:00Z',
      });

      expect(worker.id, 'w1');
      expect(worker.name, '');
      expect(worker.rating, 4.8);
      expect(worker.latitude, 10.77);
      expect(worker.longitude, 106.70);
      expect(worker.isSuspended, isTrue);
      expect(worker.suspendedAt, DateTime.parse('2026-07-10T08:00:00Z').toLocal());
    },
  );

  test(
    '[UT-FE-WORKERMODEL-05] a null suspendedAt means isSuspended is false',
    () {
      final worker = Worker.fromJson({'userId': 'w1', 'averageRating': 4.8});

      expect(worker.suspendedAt, isNull);
      expect(worker.isSuspended, isFalse);
    },
  );
}
