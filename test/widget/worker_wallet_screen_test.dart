import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/models/worker_earning.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/ui/worker/worker_wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_test_app.dart';

class _FakeWorkerRepository implements WorkerRepository {
  _FakeWorkerRepository({this.earnings = const []});

  final List<WorkerEarning> earnings;
  ({String bankBin, String accountNumber, String accountName})? lastPayoutAccountUpdate;

  @override
  Future<Worker?> getMyWorkerProfile() async => null;

  @override
  Future<WorkerOnlineStatus> getMyOnlineStatus() async => WorkerOnlineStatus.offline;

  @override
  Future<void> updateLocation(double lat, double lng) async {}

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {}

  @override
  Future<void> updateOnlineStatus(bool online) async {}

  @override
  Future<void> updatePayoutAccount({
    required String bankBin,
    required String accountNumber,
    required String accountName,
  }) async {
    lastPayoutAccountUpdate = (bankBin: bankBin, accountNumber: accountNumber, accountName: accountName);
  }

  @override
  Future<List<WorkerEarning>> getMyEarnings() async => earnings;
}

void main() {
  testWidgets('[WT-FE-WORKERWALLET-01] Shows paid/pending totals and the transaction list from real earnings',
      (tester) async {
    final repo = _FakeWorkerRepository(
      earnings: [
        const WorkerEarning(id: '1', bookingId: 'b1', amount: 200000, status: 'paid'),
        const WorkerEarning(id: '2', bookingId: 'b2', amount: 100000, status: 'pending'),
      ],
    );

    await pumpTestApp(
      tester,
      overrides: [workerRepositoryProvider.overrideWithValue(repo)],
      child: const WorkerWalletScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã nhận'), findsWidgets);
    expect(find.text('Đang chờ'), findsWidgets);
    expect(find.textContaining('200.000'), findsWidgets);
    expect(find.textContaining('100.000'), findsWidgets);
  });

  testWidgets('[WT-FE-WORKERWALLET-02] Updating the payout account submits trimmed bank details', (tester) async {
    final repo = _FakeWorkerRepository();

    await pumpTestApp(
      tester,
      overrides: [workerRepositoryProvider.overrideWithValue(repo)],
      child: const WorkerWalletScreen(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cập nhật tài khoản nhận tiền'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Mã ngân hàng (BIN)'), ' 970422 ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Số tài khoản'), ' 0123456789 ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tên chủ tài khoản'), ' Nguyen Van A ');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(
      repo.lastPayoutAccountUpdate,
      (bankBin: '970422', accountNumber: '0123456789', accountName: 'Nguyen Van A'),
    );
  });
}
