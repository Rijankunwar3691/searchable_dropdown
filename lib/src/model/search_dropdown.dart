/// A class representing an item in the searchable dropdown list.
///
/// The item has a [label] that will be displayed to the user, and a [value] that is
/// used to identify the item when selected.

class SearchableDropDownItem {
  /// The label of the dropdown item, displayed to the user.
  final String label;

  /// The value of the dropdown item, used to identify the item when selected.
  final dynamic value;

  /// Creates a [SearchableDropDownItem] with the specified [label] and [value].
  SearchableDropDownItem({required this.label, required this.value});
}
