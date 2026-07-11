import 'package:flutter/material.dart';

Widget primaryActionButton(String label, Future<void> Function() onPressed) => FilledButton(
      onPressed: () => onPressed(),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: Text(label),
    );

Widget dangerActionButton(String label, VoidCallback onPressed) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      child: Text(label),
    );

Widget outlinedSyncActionButton(String label, VoidCallback onPressed) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: Text(label),
    );
