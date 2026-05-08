import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating; // pass product.rating here
  final int maxRating;
  final double starSize;
  final Color filledColor;
  final Color unfilledColor;

  const StarRating({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 14,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = [];

    for (int i = 1; i <= maxRating; i++) {
      if (i <= rating) {
        stars.add(Icon(Icons.star, color: filledColor, size: 10));
      } else if (i - rating < 1) {
        stars.add(Icon(Icons.star_half, color: filledColor, size: 10));
      } else {
        stars.add(Icon(Icons.star_border, color: unfilledColor, size: 10));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
