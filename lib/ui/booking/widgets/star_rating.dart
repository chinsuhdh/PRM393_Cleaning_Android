import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.value, required this.onChanged, this.size = 32});

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          key: ValueKey('star-input-$starValue'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(starValue),
          icon: Icon(
            starValue <= value ? Icons.star_rounded : Icons.star_border_rounded,
            color: kTertiary,
            size: size,
          ),
        );
      }),
    );
  }
}

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 20});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: kTertiary,
          size: size,
        ),
      ),
    );
  }
}
