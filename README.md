# `advanced_searchable_dropdown`

A customizable Flutter dropdown with search functionality. This widget allows users to filter items in a dropdown based on user input and select the desired item. It's ideal for situations where the list of items can be long, and you need to quickly search for an item.

## Features

- Searchable dropdown list
- Customizable UI for the dropdown menu and items
- Flexible text field with optional label, hint, and icon support
- Clear button to reset the selected value
- Supports custom item builders
- Supports focus management and overlay for dropdown list display

## Installation

Add `advanced_searchable_dropdown` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  advanced_searchable_dropdown: ^0.0.2
```

Then run the following command to install the package:

```bash
flutter pub add advanced_searchable_dropdown
flutter pub get
```

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:advanced_searchable_dropdown/advanced_searchable_dropdown.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Searchable Dropdown')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchableDropDown(
            menuList: [
              SearchableDropDownItem(label: "Apple", value: 1),
              SearchableDropDownItem(label: "Banana", value: 2),
              SearchableDropDownItem(label: "Cherry", value: 3),
              SearchableDropDownItem(label: "Date", value: 4),
            ],
            value: 1,
            hintText: "Select a fruit",
            onSelected: (item) {
              print("Selected: ${item.label}");
            },
          ),
        ),
      ),
    );
  }
}
```

### Customization Options

- `menuMaxHeight`: Set the maximum height of the dropdown menu.
- `menuList`: A list of `SearchableDropDownItem` that will appear in the dropdown menu.
- `onSelected`: A callback function triggered when an item is selected.
- `value`: The initial selected value (can be a dynamic type).
- `menuShape`: The shape of the dropdown menu (e.g., `RoundedRectangleBorder`).
- `menuColor`: The background color of the dropdown menu.
- `hintText`: Placeholder text for the input field.
- `label`: A label for the input field.
- `textStyle`: Custom style for the text displayed inside the input field.
- `onSearch`: Callback function triggered when the text in the input field changes (for custom search behavior).
- `itemBuilder`: A custom builder for the dropdown list items.

### Example with Custom Item Builder

```dart
SearchableDropDown(
  menuList: [
    SearchableDropDownItem(label: "Apple", value: 1),
    SearchableDropDownItem(label: "Banana", value: 2),
    SearchableDropDownItem(label: "Cherry", value: 3),
    SearchableDropDownItem(label: "Date", value: 4),
  ],
  value: 1,
  hintText: "Select a fruit",
  onSelected: (item) {
    print("Selected: ${item.label}");
  },
  itemBuilder: (context, index) {
    return ListTile(
      leading: Icon(Icons.fastfood),
      title: Text(menuList[index].label),
    );
  },
)
```

## Contributing

Feel free to fork the repository, make changes, and open pull requests. Contributions are welcome!

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for more information.

---

