import 'package:flutter/material.dart';

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

extension PaymentMethodApi on PaymentMethod {
  String get apiName => this == PaymentMethod.vnpay ? 'Vnpay' : 'Cash';

  static PaymentMethod fromApiName(String value) =>
      value == 'Vnpay' ? PaymentMethod.vnpay : PaymentMethod.cash;
}
