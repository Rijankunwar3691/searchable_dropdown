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
    this.textStyle,
    this.onSearch,
    this.itemBuilder,
    this.hoverColor,
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
  final TextStyle? textStyle;
  final ValueChanged<String>? onSearch;
  final Widget? Function(BuildContext, int)? itemBuilder;
  final Color? hoverColor;

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
    setInitalValue();
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

  void onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _overlayEntry?.remove();
    _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
            color: widget.menuColor,
            child: Container(
              decoration: const BoxDecoration(),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final isHovered = _hoveredIndex == index;
                  return Container(
                    color: isHovered
                        ? Theme.of(context).highlightColor
                        : Colors.transparent,
                    child: ListTile(
                      enabled: filteredData[index].value != -1,
                      title: Text(
                        filteredData[index].label,
                        style: widget.textStyle ??
                            TextStyle(
                                color: widget.value != null &&
                                        widget.value ==
                                            filteredData[index].value
                                    ? Colors.blue
                                    : Colors.black),
                      ),
                      onTap: () {
                        _onTapTile(filteredData[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void setInitalValue() {
    if (widget.value != null) {
      final int selectedIndex = widget.menuList.indexWhere(
        (element) => element.value == widget.value,
      );
      if (selectedIndex != -1) {
        final selectedValue = widget.menuList[selectedIndex];
        _textController.text = selectedValue.label;
      } else {
        _textController.clear();
        assert(selectedIndex != -1,
            "Menu must contain at least one or more value");
      }
    } else {
      _textController.clear();
    }
  }

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
      _hoveredIndex = 0;
      _showOverlay();
    });
  }

  void _handleKey(KeyEvent event) {
    if (_overlayEntry == null) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _hoveredIndex = (_hoveredIndex + 1) % filteredData.length;
        });
        _showOverlay();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _hoveredIndex =
              (_hoveredIndex - 1 + filteredData.length) % filteredData.length;
        });
        _showOverlay();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (filteredData.isNotEmpty) {
          final selected = filteredData[_hoveredIndex];
          _onTapTile(selected);
        }
      }
    }
  }

  void _onTapTile(SearchableDropDownItem item) {
    if (item.value != -1) {
      widget.onSelected(item);
      _textController.text = item.label;
      _removeOverlay();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(), // New focus node for keyboard events
        onKeyEvent: _handleKey,
        child: TextField(
          onTapOutside: (event) {
            setInitalValue();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          controller: _textController,
          focusNode: _focusNode,
          decoration: InputDecoration(
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
            widget.onSearch != null
                ? widget.onSearch!(value)
                : _filterItems(value);
          },
        ),
      ),
    );
  }
}
