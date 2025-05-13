import 'package:advanced_searchable_dropdown/advanced_searchable_dropdown.dart';
import 'package:advanced_searchable_dropdown/src/helper/no_leading_space_text_formatter.dart';
import 'package:advanced_searchable_dropdown/src/utils/calculate_available_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable dropdown widget with search functionality.
///
/// Displays a list of [SearchableDropDownItem] and allows the user to type to filter the list.
/// When an item is selected, [onSelected] callback is triggered.
class SearchableDropDown extends StatefulWidget {
  /// Creates a [SearchableDropDown] with the provided parameters.
  ///
  /// The [menuList], [onSelected], and [value] parameters are required.
  /// [menuMaxHeight] sets the maximum height of the dropdown menu.
  /// [onTapCancel] is called when the user taps the cancel/clear icon.
  /// [menuShape] defines the shape of the dropdown menu, and [menuColor] its background color.
  /// [contentPadding], [hintText], [label], [menuTextStyle], [textStyle], and [errorStyle]
  /// control the appearance of the input field and menu items.
  /// [onSearch] is a callback invoked when the search query changes.
  /// [itemBuilder] can be used to provide a custom builder for menu items.
  /// [hoverColor] specifies the color used on hover (if supported).
  /// [validator] validates the input text, and [autovalidateMode] controls when to validate.
  /// [enabled] toggles whether the dropdown is interactive.
  /// [maxLines] sets the maximum lines for the input field.
  /// [decoration] allows a custom [InputDecoration] for the text field.
  /// [expands] makes the field expand to fill its parent.
  /// [selectedColor] is the color used for selected item text in the menu.
  /// [menuAlignment] controls the alignment of the dropdown menu relative to the input field
  /// [onTap] called on Tap of the textField.
  /// [onTapOutside] called on Tap Outside of the TextField.

  const SearchableDropDown({
    super.key,
    this.menuMaxHeight = 200,
    required this.menuList,
    required this.onSelected,
    required this.value,
    this.onTapCancel,
    this.menuShape,
    this.menuColor = Colors.white,
    this.contentPadding,
    this.hintText,
    this.label,
    this.menuTextStyle,
    this.onSearch,
    this.itemBuilder,
    this.hoverColor,
    this.validator,
    this.errorStyle,
    this.textStyle,
    this.autovalidateMode,
    this.enabled,
    this.maxLines = 1,
    this.decoration,
    this.expands = false,
    this.selectedColor = Colors.blue,
    this.menuAlignment,
    this.autoFocus,
    this.textController,
    this.onTap,
    this.onTapOutside,
    this.iconSize = 20,
  });

  /// The maximum height of the dropdown menu.
  /// If null, height is determined by content.
  final double menuMaxHeight;

  /// List of items to display in the dropdown.
  final List<SearchableDropDownItem> menuList;

  /// Callback triggered when an item is selected.
  /// Provides the selected [SearchableDropDownItem].
  final ValueChanged<SearchableDropDownItem> onSelected;

  /// The currently selected value.
  /// This should correspond to one of the values in [menuList].
  final dynamic value;

  /// Callback when the user taps the cancel/clear icon.
  final VoidCallback? onTapCancel;

  /// Shape of the dropdown menu (e.g., rounded corners).
  final ShapeBorder? menuShape;

  /// Background color of the dropdown menu.
  final Color? menuColor;

  /// Padding inside the input field.
  final EdgeInsetsGeometry? contentPadding;

  /// Hint text displayed in the input field when empty.
  final String? hintText;

  /// A widget to display as a label for the input field.
  final Widget? label;

  /// Text style for items in the dropdown menu.
  final TextStyle? menuTextStyle;

  /// Callback when the search text changes.
  /// If provided, this is called with the current search query.
  final ValueChanged<String>? onSearch;

  /// Custom builder for rendering dropdown items.
  /// Receives the context and item index.
  final Widget? Function(BuildContext, int)? itemBuilder;

  /// Color used to indicate an item is hovered (currently not applied).
  final Color? hoverColor;

  /// Function to validate the input text.
  final String? Function(String?)? validator;

  /// Text style for displaying validation error messages.
  final TextStyle? errorStyle;

  /// Text style for the text input field.
  final TextStyle? textStyle;

  /// Controls when validation is triggered.
  final AutovalidateMode? autovalidateMode;

  /// Whether the dropdown (input field) is enabled.
  final bool? enabled;

  /// Maximum lines of the input field.
  final int? maxLines;

  /// Custom decoration for the input field.
  final InputDecoration? decoration;

  /// If true, the input field expands to fill available space.
  final bool expands;

  /// Color used for the selected item text in the menu.
  final Color selectedColor;

  /// Alignment of the dropdown menu relative to the input field.
  final MenuAlignment? menuAlignment;

  /// auto focus for the testfield
  final bool? autoFocus;

  /// Text Controller for the text field
  final TextEditingController? textController;

  /// Function called onTap on textField
  final VoidCallback? onTap;

  /// Function called onTapOutside on textField
  final void Function(PointerDownEvent)? onTapOutside;

  final double iconSize;

  @override
  State<SearchableDropDown> createState() => _SearchableDropDownState();
}

class _SearchableDropDownState extends State<SearchableDropDown> {
  final _focusNode = FocusNode();
  List<SearchableDropDownItem> filteredData = [];
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _textController;
  int _hoveredIndex = 0;

  final double tileHeight = 40;
  final ScrollController _scrollController = ScrollController();
  bool _didSelectItem = false;
  bool isLocked = false;

  @override
  void initState() {
    _textController = widget.textController ?? TextEditingController();
    _focusNode.onKeyEvent = _handleKey;
    _focusNode.addListener(onFocusChange);
    filteredData = widget.menuList;
    _textController.addListener(_onTextChanged);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialValue(); // Safe to call here
    }); // Set the initial value for the dropdown (if any)
  }

  @override
  void dispose() {
    _focusNode.removeListener(onFocusChange);
    _focusNode.dispose();
    if (widget.textController == null) {
      _textController.dispose();
    }
    _textController.removeListener(
      () {
        _filterItems(_textController.text.trim());
      },
    );
    _overlayEntry?.remove();
    _overlayEntry = null;
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;

    /// Value of Text Controller
    final text = _textController.text;

    /// Search Menu List if Text Changes
    ///
    if (!isLocked) {
      widget.onSearch != null
          ? widget.onSearch!(isLocked ? '' : text.trim())
          : _filterItems(isLocked ? '' : text.trim());
    }

    /// Get selected label to check if the newly entered value is different from selected value
    ///
    final selectedLabel = _getSelectedItem()?.label;

    /// If is in locked state then move cursor to start
    ///
    if (isLocked && text.isNotEmpty) {
      _setCursorToStart();

      /// If Text is not empty and selected lable is different than user has typed something in start index
      /// Now replace the Text with new text at start
      /// Set is Locked to false to allow free movement in textfield
      if (selectedLabel != text) {
        // Replace entire text with latest single character (simulate overwrite)
        _replaceWithFirstCharacter(text);
        isLocked = false; // Unlock after user enters new text
      }
    }
  }

  /// This function replaces the text controller with new text entered in locked state at start
  ///
  void _replaceWithFirstCharacter(String text) {
    final newText = text.substring(0, 1);
    if (text != newText) {
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  /// This function sets the cursor the start position
  ///
  void _setCursorToStart() {
    _textController.selection = const TextSelection.collapsed(offset: 0);
  }

  /// Listens for focus changes.
  /// Hides the dropdown overlay when the input field loses focus.
  void onFocusChange() {
    if (!_focusNode.hasFocus) {
      /// Delay applied so that the On Tap of List Tile can be called
      ///
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    } else {
      /// Set is Locked to true and Cursor to start on Focus if it contains a value
      ///
      if (widget.value != null) {
        isLocked = true;
        _setCursorToStart();
      }
    }
  }

  /// Displays the overlay with the filtered items
  ///
  void _showOverlay() {
    _overlayEntry?.remove(); // Remove any existing overlay
    _createOverlayEntry(); // Create a new overlay entry
    Overlay.of(context)
        .insert(_overlayEntry!); // Insert the overlay into the context
  }

  // Removes the overlay from the screen
  void _removeOverlay() {
    _overlayEntry?.remove(); // Remove the overlay
    _overlayEntry = null; // Clear the overlay entry reference
  }

  /// Creates the overlay entry widget that displays the dropdown menu.
  /// Positions and sizes the menu based on available space.
  void _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    final approxMenuHeight = filteredData.length * tileHeight;
    final menuMaxHeight = approxMenuHeight < widget.menuMaxHeight
        ? approxMenuHeight
        : widget.menuMaxHeight;

    final requiredOffset = calculateAvailableSpace(
        menuAlignment: widget.menuAlignment,
        offset: offset,
        size: size,
        context: context,
        menuHeight: menuMaxHeight);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        left: offset.dx,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: requiredOffset,
          child: Material(
            elevation: 4,
            shape: widget.menuShape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
            color:
                widget.menuColor, // Set the background color for the dropdown
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.menuMaxHeight),
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  shrinkWrap: true,
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final isHovered =
                        _hoveredIndex == index; // Check if the item is hovered
                    return _buildMenuItem(
                        index, isHovered); // Build each menu item
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single menu item widget for the dropdown.
  /// Displays [filteredData[index].label] and highlights if hovered.
  Widget _buildMenuItem(int index, bool isHovered) {
    TextStyle textStyle = widget.menuTextStyle?.copyWith(
          color:
              widget.value != null && widget.value == filteredData[index].value
                  ? widget.selectedColor // Use selectedColor if set
                  : widget.textStyle?.color ??
                      Colors.black, // Default to black if no color set) ??
        ) ??
        TextStyle(
          color:
              widget.value != null && widget.value == filteredData[index].value
                  ? widget.selectedColor // Use selectedColor if set
                  : widget.textStyle?.color ??
                      Colors.black, // Default to black if no color set
        );
    return Container(
      color: isHovered
          ? Theme.of(context).highlightColor
          : Colors.transparent, // Highlight hovered item
      child: SizedBox(
        height: tileHeight,
        child: ListTile(
          enabled: filteredData[index].value != -1, // Disable if value is -1
          title: Text(
            filteredData[index].label, // Display the item label
            style: textStyle,
          ),
          onTap: () {
            _onTapTile(filteredData[index]); // Handle item tap
          },
        ),
      ),
    );
  }

  /// Sets the initial text in the field based on the current [widget.value].
  /// OnTap outside of the textfield so that text not selected are removed to default.
  void _setInitialValue() {
    if (widget.value != null) {
      final selectedItem = _getSelectedItem();
      if (selectedItem != null) {
        _textController.text = selectedItem.label;
      } else {
        _textController.clear();
        assert(false, "Menu must contain at least one or more value");
      }
    } else {
      _textController.clear();
    }
  }

  /// Returns the [SearchableDropDownItem] from [menuList] that matches [widget.value].
  /// Returns null if no match is found.
  SearchableDropDownItem? _getSelectedItem() {
    final selectedIndex = widget.menuList.indexWhere(
      (element) => element.value == widget.value,
    );
    if (selectedIndex != -1) {
      return widget.menuList[selectedIndex];
    }
    return null;
  }

  /// Filters [menuList] items based on [query], updating [filteredData].
  /// If no items match, shows a "no data available" item.
  void _filterItems(String query) {
    setState(() {
      filteredData = widget.menuList
          .where((element) =>
              element.label.toLowerCase().contains(query.toLowerCase()))
          .toList();
      if (filteredData.isEmpty) {
        filteredData = [
          SearchableDropDownItem(label: "no data available.", value: -1)
        ];
      }
      _hoveredIndex = 0; // Reset hovered index to the first item
      _showOverlay(); // Show the overlay with filtered items
    });
  }

  // Handles keyboard events like arrow up, arrow down, and enter keys
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_overlayEntry == null) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _showOverlay();
        return KeyEventResult.handled;
      }
      return KeyEventResult
          .ignored; // No overlay to handle keys if it's not present
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveToNextItem();
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveToPreviousItem();
        _overlayEntry?.markNeedsBuild();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (filteredData.isNotEmpty) {
          final selected =
              filteredData[_hoveredIndex]; // Get the currently hovered item
          _onTapTile(selected); // Select the hovered item
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  // Method to move to the next item
  void _moveToNextItem() {
    if (_hoveredIndex < filteredData.length - 1) {
      _hoveredIndex++;
    }
    _scrollToItem(_hoveredIndex);
  }

  // Method to move to the previous item
  void _moveToPreviousItem() {
    if (_hoveredIndex > 0) {
      _hoveredIndex--;
    }
    _scrollToItem(_hoveredIndex);
  }

  void _scrollToItem(int index) {
    final itemHeight = tileHeight; // Height of each item
    final targetOffset = itemHeight * index;

    // Check the current scroll position and the viewport height
    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Scroll up or down based on where the item is relative to the viewport
    if (targetOffset < scrollPosition) {
      // Item is above the current view, scroll upwards
      _scrollController.animateTo(targetOffset,
          duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
    } else if (targetOffset + itemHeight > scrollPosition + viewportHeight) {
      // Item is below the current view, scroll downwards
      _scrollController.animateTo(
          targetOffset - viewportHeight + itemHeight + 10,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut);
    }
  }

  /// Called when a menu item is tapped.
  /// Selects the item, calls [onSelected], updates text, and closes the overlay.
  void _onTapTile(SearchableDropDownItem item) {
    /// Set menu Item selected to true.
    _didSelectItem = true;
    isLocked = false;
    if (item.value != -1) {
      widget.onSelected(item); // Call the onSelected callback
      _textController.text =
          item.label; // Set the selected item label in the text field
      _removeOverlay(); // Remove the overlay
    }

    /// Set to false after some milliseconds
    Future.delayed(const Duration(milliseconds: 200), () {
      _didSelectItem = false; // <-- Reset after short time
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: _buildTextField(context),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final selectedItem = _getSelectedItem();
    return Focus(
      skipTraversal: true,
      onFocusChange: (value) {
        if (!value && !_didSelectItem) {
          _setInitialValue();
        }
      },
      child: TextFormField(
        inputFormatters: [NoLeadingSpaceFormatter()],
        autofocus: widget.autoFocus ?? false,
        textAlign: TextAlign.start,
        expands: widget.expands,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        autovalidateMode: widget.autovalidateMode,
        style: widget.textStyle,
        validator: widget.validator,
        onTapOutside: widget.onTapOutside ??
            (event) {
              if (_overlayEntry == null) {
                FocusManager.instance.primaryFocus?.unfocus();
              } else {
                Future.delayed(
                  const Duration(milliseconds: 250),
                  () {
                    _removeOverlay();
                  },
                );
              }
            },
        controller: _textController,
        focusNode: _focusNode,
        decoration: widget.decoration?.copyWith(
              suffixIconConstraints: const BoxConstraints(maxHeight: 18),
              suffixIcon: _suffixIcon(),
              hintText:
                  widget.value != null ? selectedItem?.label : widget.hintText,
            ) ??
            InputDecoration(
              isDense: true,
              errorStyle: widget.errorStyle,
              contentPadding: widget.contentPadding,
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              hintText: widget.value != null
                  ? _textController.text.trim()
                  : widget.hintText,
              label: widget.label,
              suffixIcon: _suffixIcon(),
            ),
        onTap: () {
          filteredData = widget.menuList;
          _hoveredIndex = 0;
          _showOverlay();
          widget.onTap?.call();
        },
        onChanged: (value) {},
      ),
    );
  }

  Row _suffixIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.value != null)
          IconButton(
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onPressed: () {
              widget.onTapCancel?.call();
              _textController.clear();
              setState(() {
                filteredData = widget.menuList;
              });
            },
            icon: Icon(
              Icons.close,
              size: widget.iconSize,
            ),
          ),
        const SizedBox(width: 8),
        Icon(
          Icons.expand_more,
          size: widget.iconSize,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
