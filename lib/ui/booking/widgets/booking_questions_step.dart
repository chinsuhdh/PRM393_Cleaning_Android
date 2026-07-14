import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import 'booking_pricing_estimate.dart';

/// Whether an answer value counts as "filled in" — matches the predicate
/// create_booking_screen.dart uses to gate the required-questions check, kept
/// here as the single source of truth so both stay in sync.
bool isQuestionAnswered(dynamic value) {
  if (value == null || value == '') return false;
  if (value is Iterable && value.isEmpty) return false;
  return true;
}

/// Parses the `questions` array out of a service's `bookingFormSchema`. Shared by
/// [BookingQuestionsStep] and create_booking_screen.dart so both read the schema the same way.
List<Map<String, dynamic>> parseBookingQuestions(Map<String, dynamic>? service) {
  final raw = service?['bookingFormSchema'];
  final schema = raw is String ? jsonDecode(raw) : raw;
  if (schema is! Map || schema['questions'] is! List) return const [];
  return List<Map<String, dynamic>>.from(schema['questions'] as List);
}

class BookingQuestionsStep extends StatelessWidget {
  const BookingQuestionsStep({
    super.key,
    required this.service,
    required this.answers,
    required this.onChanged,
    required this.onPhotosChanged,
    required this.photoCount,
  });

  final Map<String, dynamic>? service;
  final Map<String, dynamic> answers;
  final void Function(String id, dynamic value) onChanged;
  final ValueChanged<List<XFile>> onPhotosChanged;
  final int photoCount;

  List<Map<String, dynamic>> get _questions => parseBookingQuestions(service);

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    if (questions.isEmpty) return const Center(child: Text('Dịch vụ này không có câu hỏi bổ sung.'));
    final estimate = computeBookingEstimate(service: service, answers: answers);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _Question(
              question: questions[index],
              value: answers[questions[index]['id'] ?? questions[index]['key']],
              onChanged: onChanged,
              onPhotosChanged: onPhotosChanged,
              photoCount: photoCount,
            ),
          ),
        ),
        _EstimateBar(estimate: estimate),
      ],
    );
  }
}

/// Non-authoritative running total shown while answering questions — the confirmed price still
/// comes from the server's /quote call before the summary step.
class _EstimateBar extends StatelessWidget {
  const _EstimateBar({required this.estimate});
  final PricingEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tạm tính', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(
            '${vndFormat.format(estimate.totalPrice)} · ${estimate.durationHours.toStringAsFixed(1)} giờ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(String? type) {
  switch (type) {
    case 'single_choice':
    case 'choice':
    case 'multi_choice':
      return Icons.checklist_rounded;
    case 'yes_no':
    case 'boolean':
      return Icons.toggle_on_outlined;
    case 'text':
      return Icons.edit_note_rounded;
    case 'stepper':
    case 'number':
      return Icons.exposure_rounded;
    case 'photos':
      return Icons.photo_library_outlined;
    default:
      return Icons.help_outline_rounded;
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.question, required this.value, required this.onChanged, required this.onPhotosChanged, required this.photoCount});
  final Map<String, dynamic> question;
  final dynamic value;
  final void Function(String id, dynamic value) onChanged;
  final ValueChanged<List<XFile>> onPhotosChanged;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final id = (question['id'] ?? question['key']).toString();
    final type = question['type']?.toString();
    final label = question['label']?.toString() ?? id;
    final isRequired = question['required'] == true;
    final answered = isQuestionAnswered(value);
    final options = List<Map<String, dynamic>>.from(
      (question['options'] as List? ?? const []).map((item) =>
          item is Map ? Map<String, dynamic>.from(item) : {'id': item, 'label': item}),
    );
    Widget control;
    switch (type) {
      case 'stepper':
      case 'number':
        final min = (question['min'] as num?)?.toInt() ?? 0;
        final max = (question['max'] as num?)?.toInt() ?? 99;
        final current = (value as num?)?.toInt() ?? min;
        final unitDelta = stepperUnitDelta(question);
        control = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(onPressed: current > min ? () => onChanged(id, current - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$current', key: ValueKey('answer-$id')),
            IconButton(onPressed: current < max ? () => onChanged(id, current + 1) : null, icon: const Icon(Icons.add_circle_outline)),
          ]),
          if (unitDelta != null) _DeltaCaption(delta: unitDelta, suffix: '/ đơn vị'),
        ]);
        break;
      case 'single_choice':
      case 'choice':
        control = Column(children: options.map((option) {
          final delta = optionDelta(option);
          return RadioListTile<String>(
            title: Text(option['label'].toString()),
            subtitle: delta != null ? _DeltaCaption(delta: delta) : null,
            value: option['id'].toString(),
            groupValue: value?.toString(),
            onChanged: (selected) => onChanged(id, selected),
          );
        }).toList());
        break;
      case 'multi_choice':
        final selected = Set<String>.from(value as Iterable? ?? const []);
        control = Column(children: options.map((option) {
          final optionId = option['id'].toString();
          final delta = optionDelta(option);
          return CheckboxListTile(
            title: Text(option['label'].toString()),
            subtitle: delta != null ? _DeltaCaption(delta: delta) : null,
            value: selected.contains(optionId),
            onChanged: (checked) {
              final next = {...selected};
              checked == true ? next.add(optionId) : next.remove(optionId);
              onChanged(id, next.toList());
            },
          );
        }).toList());
        break;
      case 'yes_no':
      case 'boolean':
        control = SwitchListTile(value: value == true, onChanged: (next) => onChanged(id, next), title: const Text('Có'));
        break;
      case 'text':
        control = TextFormField(
          initialValue: value?.toString(),
          maxLength: (question['maxLength'] as num?)?.toInt(),
          maxLines: 3,
          onChanged: (next) => onChanged(id, next),
        );
        break;
      case 'photos':
        control = OutlinedButton.icon(
          onPressed: photoCount >= 5 ? null : () async {
            final picked = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1920);
            onPhotosChanged(picked.take(5 - photoCount).toList());
          },
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text('Chọn ảnh ($photoCount/5)'),
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    final Color accent;
    final Color? borderColor;
    final Color? fillColor;
    if (isRequired && !answered) {
      accent = kTertiary;
      borderColor = kTertiary.withValues(alpha: 0.4);
      fillColor = kTertiary.withValues(alpha: 0.04);
    } else if (isRequired && answered) {
      accent = kSecondary;
      borderColor = kSecondary.withValues(alpha: 0.4);
      fillColor = kSecondary.withValues(alpha: 0.04);
    } else {
      accent = kPrimary;
      borderColor = null;
      fillColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    return Container(
      key: ValueKey('question-card-$id'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: fillColor,
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      // ListTile-family controls (Radio/Checkbox/SwitchListTile) paint ink splashes on the
      // nearest Material ancestor; without this, the colored/bordered decoration above hides
      // them and Flutter throws an assertion in debug/test builds.
      child: Material(
        type: MaterialType.transparency,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_iconForType(type), size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (isRequired && !answered) _RequiredBadge(color: kTertiary),
            if (isRequired && answered) Icon(Icons.check_circle_rounded, size: 20, color: kSecondary),
          ]),
          const SizedBox(height: 10),
          control,
        ]),
      ),
    );
  }
}

/// "+50.000₫ · +45 phút" caption showing exactly what selecting/adding this option costs.
class _DeltaCaption extends StatelessWidget {
  const _DeltaCaption({required this.delta, this.suffix});
  final Delta delta;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (delta.price != 0) '+${vndFormat.format(delta.price)}',
      if (delta.duration != 0) '+${delta.duration.toStringAsFixed(0)} phút',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    final text = suffix != null ? '${parts.join(' · ')} $suffix' : parts.join(' · ');
    return Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600));
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: const Text(
        'Bắt buộc',
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
