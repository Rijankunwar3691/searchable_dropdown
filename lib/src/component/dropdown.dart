import 'package:flutter/material.dart';
import 'package:advanced_searchable_dropdown/src/model/search_dropdown.dart';

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

  @override
  State<SearchableDropDown> createState() => _SearchableDropDownState();
}

class _SearchableDropDownState extends State<SearchableDropDown> {
  final _focusNode = FocusNode();
  List<SearchableDropDownItem> filteredData = [];
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final _textController = TextEditingController();

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
    // Remove existing overlay if present
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
    }

    // Create a new overlay entry
    _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  _createOverlayEntry() {
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
                itemCount: filteredData.length,
                shrinkWrap: true,
                itemBuilder: widget.itemBuilder ??
                    (context, index) => ListTile(
                          title: Text(
                            filteredData[index].label,
                            style: widget.textStyle,
                          ),
                          onTap: () {
                            if (filteredData[index].value != -1) {
                              widget.onSelected(filteredData[index]);
                              _textController.text = filteredData[index].label;
                            }
                          },
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void setInitalValue() {
    if (widget.value != null) {
      try {
        final selectedValue = widget.menuList
            .firstWhere((element) => element.value == widget.value);
        _textController.text = selectedValue.label;
      } catch (e) {
        _textController.clear();
        throw "Menu must contain atlease one or more value";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
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
                  BorderSide(color: Theme.of(context).colorScheme.primary)),
          errorBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.error)),
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
              const SizedBox(
                width: 12,
              ),
              const Icon(
                Icons.expand_more,
                size: 24,
              ),
            ],
          ),
        ),
        onTap: () {
          filteredData = widget.menuList;
          _showOverlay();
        },
        onChanged: (value) {
          widget.onSearch ?? _filterItems(value);
        },
      ),
    );
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
      _showOverlay();
    });
  }
}
