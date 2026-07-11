import 'package:flutter/material.dart';

class ReasonRadioList extends StatelessWidget {
  final List<({String code, String label})> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const ReasonRadioList({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: options
            .map((option) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  value: option.code,
                  groupValue: selected,
                  onChanged: onChanged,
                ))
            .toList(),
      );
}
