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
}
