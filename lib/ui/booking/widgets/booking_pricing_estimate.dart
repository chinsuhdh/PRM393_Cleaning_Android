import 'package:intl/intl.dart';

import 'booking_questions_step.dart' show isQuestionAnswered, parseBookingQuestions;

final vndFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

typedef Delta = ({num price, num duration});

Delta? _deltaOf(Map<String, dynamic>? source) {
  if (source == null) return null;
  final price = (source['priceDelta'] as num?) ?? 0;
  final duration = (source['durationDelta'] as num?) ?? 0;
  if (price == 0 && duration == 0) return null;
  return (price: price, duration: duration);
}

Delta? stepperUnitDelta(Map<String, dynamic> question) {
  final unit = question['unit'];
  return _deltaOf(unit is Map ? Map<String, dynamic>.from(unit) : question);
}

Delta? optionDelta(Map<String, dynamic> option) => _deltaOf(option);

class PricingEstimate {
  final num totalPrice;
  final double durationHours;
  final double minDurationHours;
  const PricingEstimate({required this.totalPrice, required this.durationHours, required this.minDurationHours});
}

PricingEstimate computeBookingEstimate({
  required Map<String, dynamic>? service,
  required Map<String, dynamic> answers,
  double? durationOverrideHours,
}) {
  final basePrice = (service?['basePrice'] as num?) ?? 0;
  final minimumHours = (service?['minimumHours'] as num?) ?? 0;
  num total = basePrice * minimumHours;
  num minutes = minimumHours * 60;

  void addDelta(Delta? delta, num multiplier) {
    if (delta == null) return;
    total += delta.price * multiplier;
    minutes += delta.duration * multiplier;
  }

  for (final question in parseBookingQuestions(service)) {
    final id = (question['id'] ?? question['key']).toString();
    final value = answers[id];
    if (!isQuestionAnswered(value)) continue;
    final type = question['type']?.toString();
    final options = List<Map<String, dynamic>>.from(
      (question['options'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    Map<String, dynamic>? optionById(String id) {
      for (final option in options) {
        if (option['id'].toString() == id) return option;
      }
      return null;
    }

    switch (type) {
      case 'stepper':
      case 'number':
        addDelta(stepperUnitDelta(question), value as num);
        break;
      case 'single_choice':
      case 'choice':
        final option = optionById(value.toString());
        if (option != null) addDelta(optionDelta(option), 1);
        break;
      case 'multi_choice':
        for (final selected in value as Iterable) {
          final option = optionById(selected.toString());
          if (option != null) addDelta(optionDelta(option), 1);
        }
        break;
    }
  }

  final roundedMinutes = (minutes / 30).ceil() * 30;
  final computedDuration = roundedMinutes / 60;

  var totalDuration = computedDuration;
  if (durationOverrideHours != null && durationOverrideHours > computedDuration) {
    total += (durationOverrideHours - computedDuration) * basePrice;
    totalDuration = durationOverrideHours;
  }

  return PricingEstimate(totalPrice: total, durationHours: totalDuration, minDurationHours: computedDuration);
}
