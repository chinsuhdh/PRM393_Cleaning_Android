import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/worker_earning.dart';
import '../../data/repositories/worker_repository.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

String _statusLabel(String status) => switch (status) {
      'paid' || 'settled' => 'Đã nhận',
      'processing' => 'Đang xử lý',
      _ => 'Đang chờ',
    };

Color _statusColor(String status) => switch (status) {
      'paid' || 'settled' => kSecondary,
      'processing' => Colors.orange,
      _ => Colors.grey,
    };

class WorkerWalletScreen extends ConsumerWidget {
  const WorkerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final earningsAsync = ref.watch(workerEarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ví tiền',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: earningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải dữ liệu ví tiền.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
        data: (earnings) => _WalletBody(earnings: earnings),
      ),
    );
  }
}

class _WalletBody extends ConsumerWidget {
  const _WalletBody({required this.earnings});

  final List<WorkerEarning> earnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paidTotal = earnings.where((e) => e.isPaid).fold<double>(0, (sum, e) => sum + e.amount);
    final pendingTotal = earnings.where((e) => !e.isPaid).fold<double>(0, (sum, e) => sum + e.amount);
    final monthTotal = earnings
        .where((e) => e.isPaid && e.paidAt != null && _isThisMonth(e.paidAt!))
        .fold<double>(0, (sum, e) => sum + e.amount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kPrimaryGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã nhận',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _vnd.format(paidTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _BalanceStat(label: 'Tháng này', value: _vnd.format(monthTotal)),
                          const SizedBox(width: 24),
                          _BalanceStat(label: 'Đang chờ', value: _vnd.format(pendingTotal)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showPayoutAccountSheet(context, ref),
                  icon: const Icon(Icons.account_balance_rounded),
                  label: const Text('Cập nhật tài khoản nhận tiền'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kSecondary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Giao dịch',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (earnings.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Chưa có giao dịch nào.')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final earning = earnings[i];
                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kSecondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: kSecondary),
                    ),
                    title: Text(
                      _statusLabel(earning.status),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    subtitle: Text(
                      earning.earnedAt != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(earning.earnedAt!)
                          : '',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _vnd.format(earning.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kSecondary),
                        ),
                        Text(
                          _statusLabel(earning.status),
                          style: TextStyle(fontSize: 11, color: _statusColor(earning.status)),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: earnings.length),
            ),
          ),
      ],
    );
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
}

void _showPayoutAccountSheet(BuildContext context, WidgetRef ref) {
  final bankBinController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản nhận tiền',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bankBinController,
              decoration: const InputDecoration(labelText: 'Mã ngân hàng (BIN)'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: accountNumberController,
              decoration: const InputDecoration(labelText: 'Số tài khoản'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: accountNameController,
              decoration: const InputDecoration(labelText: 'Tên chủ tài khoản'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await ref.read(workerRepositoryProvider).updatePayoutAccount(
                        bankBin: bankBinController.text.trim(),
                        accountNumber: accountNumberController.text.trim(),
                        accountName: accountNameController.text.trim(),
                      );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật tài khoản nhận tiền.')),
                    );
                  }
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text('Không thể cập nhật: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
