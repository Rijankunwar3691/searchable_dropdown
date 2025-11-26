import 'package:flutter/foundation.dart';

/// Controls the open/close state of a [SearchableDropDown] menu.
class SearchableDropdownController extends ChangeNotifier {
  bool _isOpen = false;

  /// Whether the dropdown menu is currently open.
  bool get isOpen => _isOpen;

  /// Opens the dropdown menu.
  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  /// Closes the dropdown menu.
  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  /// Toggles the dropdown menu's open state.
  void toggle() {
    _isOpen ? close() : open();
  }
}
