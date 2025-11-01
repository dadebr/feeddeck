import 'package:flutter/material.dart';

import 'package:feeddeck/utils/constants.dart';

/// [ItemCategoryPicker] is a widget that allows users to select or enter a
/// category for a feed item. It provides predefined categories as well as
/// the option to enter a custom category.
class ItemCategoryPicker extends StatefulWidget {
  const ItemCategoryPicker({
    super.key,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  final String? currentCategory;
  final Function(String?) onCategorySelected;

  @override
  State<ItemCategoryPicker> createState() => _ItemCategoryPickerState();
}

class _ItemCategoryPickerState extends State<ItemCategoryPicker> {
  final TextEditingController _customCategoryController =
      TextEditingController();
  String? _selectedCategory;
  bool _showCustomInput = false;

  // Predefined categories that users can quickly select
  final List<String> _predefinedCategories = [
    'Technology',
    'News',
    'Sports',
    'Entertainment',
    'Business',
    'Science',
    'Health',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;

    // If current category is not in predefined list, show custom input
    if (_selectedCategory != null &&
        !_predefinedCategories.contains(_selectedCategory)) {
      _showCustomInput = true;
      _customCategoryController.text = _selectedCategory!;
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width >=
                (Constants.centeredFormMaxWidth + 2 * Constants.spacingMiddle)
            ? (MediaQuery.of(context).size.width -
                      Constants.centeredFormMaxWidth) /
                  2
            : Constants.spacingMiddle,
      ),
      title: const Text('Set Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show "None" option to remove category
            if (_selectedCategory != null)
              ListTile(
                title: const Text('None (Remove Category)'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = null;
                      _showCustomInput = false;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _showCustomInput = false;
                  });
                },
              ),
            // Predefined categories
            ..._predefinedCategories.map((category) {
              return ListTile(
                title: Text(category),
                leading: Radio<String>(
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _showCustomInput = false;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _showCustomInput = false;
                  });
                },
              );
            }),
            // Custom category option
            ListTile(
              title: const Text('Custom Category'),
              leading: Radio<bool>(
                value: true,
                groupValue: _showCustomInput,
                onChanged: (value) {
                  setState(() {
                    _showCustomInput = value!;
                    if (_showCustomInput) {
                      _selectedCategory = _customCategoryController.text;
                    }
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _showCustomInput = true;
                  _selectedCategory = _customCategoryController.text;
                });
              },
            ),
            // Custom category input field
            if (_showCustomInput)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.spacingMiddle,
                  vertical: Constants.spacingSmall,
                ),
                child: TextField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Enter custom category',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Constants.onSurface),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: () {
            widget.onCategorySelected(_selectedCategory);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Save',
            style: TextStyle(color: Constants.primary),
          ),
        ),
      ],
    );
  }
}
