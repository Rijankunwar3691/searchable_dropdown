import 'package:flutter/material.dart';
import 'package:advanced_searchable_dropdown/advanced_searchable_dropdown.dart';

/// Calculates the available space for the dropdown menu based on the position of the input field.
///
/// This function determines whether the dropdown should be displayed above or below
/// the input field based on the available space on the screen.
///
/// If the menu alignment is specified, the dropdown will appear at that position,
/// otherwise, it will calculate the space available below the input field and choose
/// the best position (above or below) based on the remaining space.
///
/// **Parameters:**
/// - [offset]: The position of the input field on the screen.
/// - [size]: The size of the input field.
/// - [context]: The current context to get the screen size.
/// - [menuHeight]: The height of the dropdown menu.
/// - [menuAlignment]: The alignment of the dropdown menu. Can be [MenuAlignment.top] or [MenuAlignment.bottom].
///
/// **Returns:**
/// An [Offset] representing the position where the dropdown menu should be displayed.
Offset calculateAvailableSpace({
  required Offset offset,
  required Size size,
  required BuildContext context,
  required double menuHeight,
  required MenuAlignment? menuAlignment,
}) {
  if (menuAlignment == MenuAlignment.top) {
    return Offset(0, -(menuHeight + 5)); // Show dropdown above
  }
  if (menuAlignment == MenuAlignment.bottom) {
    return Offset(0, size.height + 5); // Show dropdown below
  }

  // Calculate available space below the text field
  final screenHeight = MediaQuery.of(context).size.height;
  final spaceBelow = screenHeight - offset.dy - size.height;

  // Determine the position of the dropdown (above or below)
  final newOffset = (spaceBelow >= menuHeight)
      ? Offset(0, size.height + 5) // Position below if space is available
      : Offset(
          0, -(menuHeight + 15)); // Position above if not enough space below

  return newOffset;
}
