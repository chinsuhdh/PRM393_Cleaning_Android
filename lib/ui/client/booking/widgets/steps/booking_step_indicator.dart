import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  const BookingStepIndicator({super.key, required this.currentStep});

  static const _labels = ['Câu hỏi', 'Địa chỉ', 'Thời gian', 'Xác nhận'];
  static const _stepWidth = 58.0;
  static const _connectorWidth = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) _connector(context, isDone: i <= currentStep),
              _step(context, i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(BuildContext context, int i) {
    final theme = Theme.of(context);
    final isActive = i <= currentStep;
    final isCompleted = i < currentStep;
    return SizedBox(
      width: _stepWidth,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? kPrimary : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : Text('${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _labels[i],
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? kPrimary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector(BuildContext context, {required bool isDone}) {
    final theme = Theme.of(context);
    return Container(
      width: _connectorWidth,
      height: 2,
      margin: const EdgeInsets.only(top: 15),
      color: isDone ? kPrimary : theme.colorScheme.surfaceContainerHighest,
    );
  }
}
