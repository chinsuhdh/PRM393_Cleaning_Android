import 'package:flutter/material.dart';

/// Consistent action layout for destructive confirmations.
class DestructiveDialogActions extends StatelessWidget {
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DestructiveDialogActions({
    super.key,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel = 'Hủy',
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Colors.red,
              ),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(cancelLabel),
            ),
          ],
        ),
      );
}
