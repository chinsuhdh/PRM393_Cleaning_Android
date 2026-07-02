import 'package:flutter/material.dart';

/// Payment methods offered to the client. Selection is captured now for a smoother flow, but payment
/// is not processed yet — the actual charge (Cash on completion / VNPay redirect / e-wallets) is a
/// later feature (see PAY-001). Values mirror the backend `PaymentMethod` enum.
enum PaymentMethod { cash, vnpay, momo, zalopay, bankTransfer }

class PaymentMethodOption {
  final PaymentMethod method;
  final String label;
  final IconData icon;

  const PaymentMethodOption(this.method, this.label, this.icon);
}

const List<PaymentMethodOption> kPaymentMethods = [
  PaymentMethodOption(PaymentMethod.cash, 'Tiền mặt', Icons.payments_rounded),
  PaymentMethodOption(PaymentMethod.vnpay, 'VNPay', Icons.account_balance_wallet_rounded),
  PaymentMethodOption(PaymentMethod.momo, 'MoMo', Icons.account_balance_wallet_rounded),
  PaymentMethodOption(PaymentMethod.zalopay, 'ZaloPay', Icons.account_balance_wallet_rounded),
  PaymentMethodOption(PaymentMethod.bankTransfer, 'Chuyển khoản ngân hàng', Icons.account_balance_rounded),
];
