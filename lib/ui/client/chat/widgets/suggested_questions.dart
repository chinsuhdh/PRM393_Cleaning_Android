import 'package:flutter/material.dart';

const suggestedQuestions = [
  'Chính sách hủy đặt lịch?',
  'Có những dịch vụ nào?',
  'Cách ghép nhân viên?',
  'Thanh toán như thế nào?',
];

class SuggestedQuestions extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const SuggestedQuestions({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(suggestedQuestions[i]),
          onPressed: () => onSelected(suggestedQuestions[i]),
        ),
      ),
    );
  }
}
