import 'package:cleanai/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-PROFILE-01] getMyProfile parses the profile payload',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Profiles/me',
        (server) => server.reply(200, {
          'id': 'p1',
          'fullName': 'Nguyễn Văn A',
          'email': 'a@b.com',
          'phoneNumber': '0900000000',
          'isPhoneVerified': true,
        }),
        data: null,
      );
      final repository = ProfileRepository(harness.dio);

      final profile = await repository.getMyProfile();

      expect(profile.fullName, 'Nguyễn Văn A');
      expect(profile.email, 'a@b.com');
    },
  );

  test(
    '[UT-FE-PROFILE-02] getMyProfile throws the backend message on an error response',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Profiles/me',
        (server) => server.reply(404, {'message': 'Không tìm thấy hồ sơ.'}),
        data: null,
      );
      final repository = ProfileRepository(harness.dio);

      expect(
        () => repository.getMyProfile(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Không tìm thấy hồ sơ.'),
          ),
        ),
      );
    },
  );

  test(
    '[UT-FE-PROFILE-03] updateProfile sends the payload and completes successfully',
        () async {
      final harness = DioTestHarness();

      // Giả lập backend trả về object thông báo thành công giống C#
      harness.adapter.onPut(
        '/Profiles/me',
            (server) => server.reply(200, {
          'success': true,
          'message': 'Profile updated successfully',
        }),
        data: {'fullName': 'Tên Mới'},
      );

      final repository = ProfileRepository(harness.dio);

      // Vì hàm trả về void, chúng ta kiểm tra xem nó có hoàn thành (completes)
      // một cách êm đẹp mà không văng ra Exception hay không.
      await expectLater(
        repository.updateProfile(fullName: 'Tên Mới'),
        completes,
      );
    },
  );
}
