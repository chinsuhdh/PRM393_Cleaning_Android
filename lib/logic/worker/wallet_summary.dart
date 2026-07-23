import '../../data/models/worker_earning.dart';

class WalletSummary {
  const WalletSummary({required this.paidTotal, required this.pendingTotal, required this.monthTotal});

  final double paidTotal;
  final double pendingTotal;
  final double monthTotal;
}

bool _isThisMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

WalletSummary computeWalletSummary(List<WorkerEarning> earnings) {
  final paidTotal = earnings.where((e) => e.isPaid).fold<double>(0, (sum, e) => sum + e.amount);
  final pendingTotal = earnings.where((e) => !e.isPaid).fold<double>(0, (sum, e) => sum + e.amount);
  final monthTotal = earnings
      .where((e) => e.isPaid && e.paidAt != null && _isThisMonth(e.paidAt!))
      .fold<double>(0, (sum, e) => sum + e.amount);
  return WalletSummary(paidTotal: paidTotal, pendingTotal: pendingTotal, monthTotal: monthTotal);
}
