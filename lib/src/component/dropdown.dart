import 'package:flutter/material.dart';
import 'package:advanced_searchable_dropdown/src/model/search_dropdown.dart';
import 'package:flutter/services.dart';

class SearchableDropDown extends StatefulWidget {
  const SearchableDropDown({
    super.key,
    this.menuMaxHeight,
    required this.menuList,
    required this.onSelected,
    required this.value,
    this.onTapCancel,
    this.menuShape,
    this.menuColor = Colors.white,
    this.contentPadding,
    this.hintText = '',
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
    this.maxLines,
    this.decoration,
    this.expands = false,
    this.selectedColor = Colors.blue,
  });

  final double? menuMaxHeight;
  final List<SearchableDropDownItem> menuList;
  final ValueChanged<SearchableDropDownItem> onSelected;
  final dynamic value;
  final VoidCallback? onTapCancel;
  final ShapeBorder? menuShape;
  final Color? menuColor;
  final EdgeInsetsGeometry? contentPadding;
  final String hintText;
  final Widget? label;
  final TextStyle? menuTextStyle;
  final ValueChanged<String>? onSearch;
  final Widget? Function(BuildContext, int)? itemBuilder;
  final Color? hoverColor;
  final String? Function(String?)? validator;
  final TextStyle? errorStyle;
  final TextStyle? textStyle;
  final AutovalidateMode? autovalidateMode;
  final bool? enabled;
  final int? maxLines;
  final InputDecoration? decoration;
  final bool expands;
  final Color selectedColor;

  @override
  State<SearchableDropDown> createState() => _SearchableDropDownState();
}

class _SearchableDropDownState extends State<SearchableDropDown> {
  final _focusNode = FocusNode();
  List<SearchableDropDownItem> filteredData = [];
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final _textController = TextEditingController();
  int _hoveredIndex = 0;

  @override
  void initState() {
    _focusNode.addListener(onFocusChange);
    filteredData = widget.menuList;
    _setInitialValue(); // Set the initial value for the dropdown (if any)
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.removeListener(onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  /// Listener that removes the overlay when focus is lost
  ///  Delay added so that the onTap function of tile can be called.
  void onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  // Displays the overlay with the filtered items
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

  void _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        height: widget.menuMaxHeight,
        width: size.width,
        top: offset.dy + size.height,
        left: offset.dx,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
    );
  }

  // Builds each menu item in the dropdown
  Widget _buildMenuItem(int index, bool isHovered) {
    return Container(
      color: isHovered
          ? Theme.of(context).highlightColor
          : Colors.transparent, // Highlight hovered item
      child: ListTile(
        enabled: filteredData[index].value != -1, // Disable if value is -1
        title: Text(
          filteredData[index].label, // Display the item label
          style: widget.menuTextStyle?.copyWith(
            color: widget.value != null &&
                    widget.value == filteredData[index].value
                ? widget.selectedColor // Use selectedColor if set
                : widget.textStyle?.color ??
                    Colors.black, // Default to black if no color set) ??
          ),
        ),
        onTap: () {
          _onTapTile(filteredData[index]); // Handle item tap
        },
      ),
    );
  }

  /// This function sets the inital value on first initialization and
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

  /// Helper method to get the selected item based on the current value
  SearchableDropDownItem? _getSelectedItem() {
    final selectedIndex = widget.menuList.indexWhere(
      (element) => element.value == widget.value,
    );
    if (selectedIndex != -1) {
      return widget.menuList[selectedIndex];
    }
    return null;
  }

  /// Filters the menu items based on the query entered by the user
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
  void _handleKey(KeyEvent event) {
    if (_overlayEntry == null) {
      return; // No overlay to handle keys if it's not present
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _hoveredIndex = (_hoveredIndex + 1) %
              filteredData.length; // Move to the next item
        });
        _showOverlay(); // Update the overlay
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _hoveredIndex = (_hoveredIndex - 1 + filteredData.length) %
              filteredData.length; // Move to the previous item
        });
        _showOverlay(); // Update the overlay
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (filteredData.isNotEmpty) {
          final selected =
              filteredData[_hoveredIndex]; // Get the currently hovered item
          _onTapTile(selected); // Select the hovered item
        }
      }
    }
  }

  // Handles the tap on a menu item and updates the selected value
  void _onTapTile(SearchableDropDownItem item) {
    if (item.value != -1) {
      widget.onSelected(item); // Call the onSelected callback
      _textController.text =
          item.label; // Set the selected item label in the text field
      _removeOverlay(); // Remove the overlay
      FocusManager.instance.primaryFocus?.unfocus(); // Unfocus the text field
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(), // New focus node for keyboard events
        onKeyEvent: _handleKey,
        child: _buildTextField(context),
      ),
    );
  }

  TextFormField _buildTextField(BuildContext context) {
    return TextFormField(
      textAlign: TextAlign.start,
      expands: widget.expands,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      autovalidateMode: widget.autovalidateMode,
      style: widget.textStyle,
      validator: widget.validator,
      onTapOutside: (event) {
        _setInitialValue();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      controller: _textController,
      focusNode: _focusNode,
      decoration: widget.decoration ??
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
            hintText: widget.hintText,
            label: widget.label,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.value != null)
                  InkWell(
                    onTap: widget.onTapCancel ??
                        () {
                          _textController.clear();
                          setState(() {
                            filteredData = widget.menuList;
                          });
                        },
                    child: const Icon(
                      Icons.close,
                      size: 19,
                    ),
                  ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.expand_more,
                  size: 24,
                ),
              ],
            ),
          ),
      onTap: () {
        filteredData = widget.menuList;
        _hoveredIndex = 0;
        _showOverlay();
      },
      onChanged: (value) {
        widget.onSearch != null ? widget.onSearch!(value) : _filterItems(value);
      },
    );
  }
}
