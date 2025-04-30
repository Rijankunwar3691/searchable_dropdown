import 'package:flutter/services.dart';

class NoLeadingSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new text starts with a space, remove it
    if (newValue.text.startsWith(' ')) {
      return newValue.copyWith(
        text: newValue.text
            .replaceFirst(RegExp(r'^ +'), ''), // Remove all leading spaces
        selection: TextSelection.collapsed(
          offset: newValue.selection.baseOffset -
              (newValue.text.length - newValue.text.trimLeft().length),
        ),
      );
    }
    return newValue;
  }
}
