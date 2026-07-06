import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  List<Map<String, dynamic>> get _questions {
    final raw = service?['bookingFormSchema'];
    final schema = raw is String ? jsonDecode(raw) : raw;
    if (schema is! Map || schema['questions'] is! List) return const [];
    return List<Map<String, dynamic>>.from(schema['questions'] as List);
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    if (questions.isEmpty) return const Center(child: Text('Dịch vụ này không có câu hỏi bổ sung.'));
    return ListView.separated(
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _Question(
        question: questions[index],
        value: answers[questions[index]['id'] ?? questions[index]['key']],
        onChanged: onChanged,
        onPhotosChanged: onPhotosChanged,
        photoCount: photoCount,
      ),
    );
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
        control = Row(children: [
          IconButton(onPressed: current > min ? () => onChanged(id, current - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
          Text('$current', key: ValueKey('answer-$id')),
          IconButton(onPressed: current < max ? () => onChanged(id, current + 1) : null, icon: const Icon(Icons.add_circle_outline)),
        ]);
        break;
      case 'single_choice':
      case 'choice':
        control = Column(children: options.map((option) => RadioListTile<String>(
          title: Text(option['label'].toString()),
          value: option['id'].toString(),
          groupValue: value?.toString(),
          onChanged: (selected) => onChanged(id, selected),
        )).toList());
        break;
      case 'multi_choice':
        final selected = Set<String>.from(value as Iterable? ?? const []);
        control = Column(children: options.map((option) {
          final optionId = option['id'].toString();
          return CheckboxListTile(
            title: Text(option['label'].toString()),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      control,
    ]);
  }
}
