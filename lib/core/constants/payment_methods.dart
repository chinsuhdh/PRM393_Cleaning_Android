import 'package:flutter/material.dart';

enum PaymentMethod { cash, payos }

class PaymentMethodOption {
  final PaymentMethod method;
  final String label;
  final IconData icon;

  const PaymentMethodOption(this.method, this.label, this.icon);
}

const List<PaymentMethodOption> kPaymentMethods = [
  PaymentMethodOption(PaymentMethod.cash, 'Tiền mặt', Icons.payments_rounded),
  PaymentMethodOption(PaymentMethod.payos, 'payOS', Icons.account_balance_wallet_rounded),
];

extension PaymentMethodApi on PaymentMethod {
  String get apiName => this == PaymentMethod.payos ? 'Payos' : 'Cash';

  static PaymentMethod fromApiName(String value) =>
      value == 'Payos' ? PaymentMethod.payos : PaymentMethod.cash;
}
