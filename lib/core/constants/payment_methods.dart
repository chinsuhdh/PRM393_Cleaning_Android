import 'package:flutter/material.dart';

/// Payment methods offered to the client. Selection is captured now for a smoother flow, but payment
/// is not processed yet — the actual charge (Cash on completion / VNPay redirect) is a later feature
/// (see PAY-001). Values mirror the backend `PaymentMethod` enum: Cash | Vnpay only.
enum PaymentMethod { cash, vnpay }

class PaymentMethodOption {
  final PaymentMethod method;
  final String label;
  final IconData icon;

  const PaymentMethodOption(this.method, this.label, this.icon);
}

const List<PaymentMethodOption> kPaymentMethods = [
  PaymentMethodOption(PaymentMethod.cash, 'Tiền mặt', Icons.payments_rounded),
  PaymentMethodOption(PaymentMethod.vnpay, 'VNPay', Icons.account_balance_wallet_rounded),
];
