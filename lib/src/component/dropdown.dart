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
    this.menuMaxHeight = 300,
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
    this.showCancelButton = true,
    this.controller,
    this.closeOnSelect,
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

  /// This controls weather to show or hide cancel button
  final bool showCancelButton;

  /// Optional [SearchableDropdownController] to drive the dropdown menu manually.
  /// When supplied, you can programmatically open/close the menu.
  final SearchableDropdownController? controller;

  /// Whether the menu should close automatically when an item is picked.
  /// Defaults to `true` unless a [controller] is provided, in which case the
  /// caller must opt-in by setting this to `true`.
  final bool? closeOnSelect;

  @override
  State<SearchableDropDown> createState() => _SearchableDropDownState();
}

class _SearchableDropDownState extends State<SearchableDropDown> {
  /// Keeps track of the dropdown that currently has its menu open so that
  /// only one dropdown is open at a time across the app.
  static _SearchableDropDownState? _currentlyOpenDropdown;

  final _focusNode = FocusNode();
  List<SearchableDropDownItem> filteredData = [];
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _portalController = OverlayPortalController();
  late TextEditingController _textController;
  int _hoveredIndex = 0;

  final double tileHeight = 40;
  final ScrollController _scrollController = ScrollController();
  bool _justSelected = false;
  late final SearchableDropdownController _internalMenuController =
      SearchableDropdownController();
  SearchableDropdownController? _listeningMenuController;
  final GlobalKey _anchorKey = GlobalKey();

  SearchableDropdownController get _menuController =>
      widget.controller ?? _internalMenuController;

  @override
  void initState() {
    _updateMenuControllerListener();
    _textController = widget.textController ?? TextEditingController();
    _focusNode.onKeyEvent = _handleKey;
    filteredData = widget.menuList;
    super.initState();
    _setInitialValue();
  }

  void _updateMenuControllerListener() {
    final controller = _menuController;
    if (identical(_listeningMenuController, controller)) return;

    _listeningMenuController?.removeListener(_handleMenuControllerChange);
    _listeningMenuController = controller;
    controller.addListener(_handleMenuControllerChange);
    _handleMenuControllerChange();
  }

  @override
  void didUpdateWidget(covariant SearchableDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _updateMenuControllerListener();
    }

    if (oldWidget.value != widget.value) {
      _setInitialValue();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.textController == null) {
      _textController.dispose();
    }
    _scrollController.dispose();
    _listeningMenuController?.removeListener(_handleMenuControllerChange);
    super.dispose();
  }

  void _handleMenuControllerChange() {
    if (!mounted) return;
    final shouldShow = _menuController.isOpen;
    if (shouldShow) {
      _registerAsOpenDropdown();
      if (!_portalController.isShowing) {
        _portalController.show();
      }
    } else if (_portalController.isShowing) {
      _portalController.hide();
    }
    setState(() {});
  }

  void _registerAsOpenDropdown() {
    if (identical(_currentlyOpenDropdown, this)) return;

    _currentlyOpenDropdown?._closeMenu();
    _currentlyOpenDropdown = this;
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final menuOffset = calculateAvailableSpace(
      offset: offset,
      size: size,
      context: context,
      menuHeight: widget.menuMaxHeight,
      menuAlignment: widget.menuAlignment,
    );

    return Positioned(
      width: size.width,
      left: offset.dx,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: menuOffset,
        child: _buildMenuSurface(size.width),
      ),
    );
  }

  Widget _buildMenuSurface(double width) {
    return Material(
      color: widget.menuColor ?? Colors.white,
      shape: widget.menuShape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: TapRegion(
        groupId: "dropDown",
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.menuMaxHeight),
          child: _buildMenuContent(width, widget.menuMaxHeight),
        ),
      ),
    );
  }

  void _onTextChanged(String text) {
    /// Search Menu List if Text Changes
    ///

    _replaceWithFirstCharacter(text);
    final updatedText = _textController.text.trim();

    _filterItems(updatedText);
  }

  /// This function replaces the text controller with new text entered in locked state at start
  ///
  void _replaceWithFirstCharacter(String text) {
    if (_justSelected && text.isNotEmpty) {
      // Replace all text with the first typed character
      final firstChar = text.characters.first;
      _textController.value = TextEditingValue(
        text: firstChar,
        selection: const TextSelection.collapsed(offset: 1),
      );
      _justSelected = false; // stop replacing further input
    }
  }

  bool get _shouldAutoCloseMenu =>
      widget.closeOnSelect ?? widget.controller == null;

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
    return MouseRegion(
      onEnter: (_) => _updateHoveredIndex(index),
      child: Container(
        color: isHovered
            ? widget.hoverColor ?? Theme.of(context).highlightColor
            : Colors.transparent, // Highlight hovered item
        child: ListTile(
          minTileHeight: tileHeight,
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

  Widget _buildMenuContent(double menuWidth, double menuHeight) {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: filteredData.length,
      itemBuilder: (context, index) =>
          _buildMenuItem(index, index == _hoveredIndex),
    );
  }

  /// Sets the initial text in the field based on the current [widget.value].
  /// OnTap outside of the textfield so that text not selected are removed to default.
  void _setInitialValue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.value != null) {
        final selectedItem = _getSelectedItem();
        if (selectedItem != null) {
          _justSelected = true;
          _textController.value = TextEditingValue(
            text: selectedItem.label,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _textController.value = const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
          if (widget.value != 0) {
            assert(false, "Menu must contain at least one or more value");
          }
        }
      } else {
        _textController.clear();
      }
    });
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
    });
  }

  void _updateHoveredIndex(int index) {
    if (_hoveredIndex == index) return;
    setState(() {
      _hoveredIndex = index;
    });
  }

  // Handles keyboard events like arrow up, arrow down, and enter keys
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isMenuOpen = _menuController.isOpen;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!isMenuOpen) {
        _openMenu();
      } else {
        _moveToNextItem();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (!isMenuOpen) {
        _openMenu();
      } else if (_hoveredIndex == 0) {
        _menuController.close();
      } else {
        _moveToPreviousItem();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter && isMenuOpen) {
      if (filteredData.isNotEmpty) {
        final selected = filteredData[_hoveredIndex];
        _onTapTile(selected); // Select the hovered item
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape && isMenuOpen) {
      _closeMenu();
      return KeyEventResult.handled;
    }

    if (!isMenuOpen && event.logicalKey == LogicalKeyboardKey.space) {
      _openMenu();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // Method to move to the next item
  void _moveToNextItem() {
    setState(() {
      if (_hoveredIndex < filteredData.length - 1) {
        _hoveredIndex++;
      }
    });
    _scrollToItem(_hoveredIndex);
  }

  // Method to move to the previous item
  void _moveToPreviousItem() {
    setState(() {
      if (_hoveredIndex > 0) {
        _hoveredIndex--;
      }
    });
    _scrollToItem(_hoveredIndex);
  }

  void _openMenu({bool resetFilter = false}) {
    setState(() {
      if (resetFilter || filteredData.isEmpty) {
        filteredData = widget.menuList;
      }

      if (filteredData.isEmpty) {
        _hoveredIndex = 0;
      } else if (resetFilter || _hoveredIndex >= filteredData.length) {
        _hoveredIndex = 0;
      }
    });
    if (!_menuController.isOpen) {
      _menuController.open();
    }
  }

  void _closeMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else if (_portalController.isShowing) {
      _portalController.hide();
    }

    if (identical(_currentlyOpenDropdown, this)) {
      _currentlyOpenDropdown = null;
    }
  }

  void _scrollToItem(int index) {
    final itemHeight = tileHeight; // Height of each item
    final targetOffset = itemHeight * index;

    if (!_scrollController.hasClients) return;

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
    if (item.value != -1) {
      _justSelected = true;
      // Set the selected item label in the text field
      _textController.value = TextEditingValue(
          text: item.label,
          selection: const TextSelection.collapsed(offset: 0));
      // Call the onSelected callback
      widget.onSelected(item);
    }

    if (_shouldAutoCloseMenu) {
      _closeMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: 'dropDown',
      onTapOutside: (event) {
        if (!_justSelected) {
          _setInitialValue();
        }
        widget.onTapOutside?.call(event);
        _justSelected = false;

        _closeMenu();
      },
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildOverlay,
        child: _buildTextField(context),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        enableInteractiveSelection: false,
        key: _anchorKey,
        inputFormatters: [NoLeadingSpaceFormatter()],
        autofocus: widget.autoFocus ?? false,
        textAlign: TextAlign.start,
        expands: widget.expands,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        autovalidateMode: widget.autovalidateMode,
        style: widget.textStyle,
        validator: widget.validator,
        controller: _textController,
        focusNode: _focusNode,
        decoration: widget.decoration?.copyWith(
              suffixIconConstraints: const BoxConstraints(maxHeight: 18),
              suffixIcon: _suffixIcon(),
              hintText: widget.hintText,
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
              hintText: widget.hintText,
              label: widget.label,
              suffixIcon: _suffixIcon(),
            ),
        onTap: () {
          _justSelected = true;
          _textController.selection = const TextSelection.collapsed(offset: 0);
          widget.onTap?.call();
          _openMenu(resetFilter: true);
        },
        onChanged: _onTextChanged,
      ),
    );
  }

  Row _suffixIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.value != null &&
            widget.showCancelButton &&
            widget.value != 0)
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
