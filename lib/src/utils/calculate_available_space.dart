import 'package:flutter/material.dart';

Offset calculateAvailableSpace({
  required Offset offset,
  required Size size,
  required BuildContext context,
  required double menuHeight,
}) {
  // Calculate available space below the text field
  final screenHeight = MediaQuery.of(context).size.height;
  final spaceBelow = screenHeight - offset.dy - size.height;

  // Determine the position of the dropdown (above or below)
  final newOffset = (spaceBelow >= menuHeight)
      ? Offset(0, size.height + 5)
      : Offset(
          0,
          -(menuHeight +
              5)); // Position above if there's not enough space below

  return newOffset;
}
