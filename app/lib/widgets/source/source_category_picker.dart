import 'package:flutter/material.dart';

import 'package:feeddeck/utils/constants.dart';

/// [SourceCategoryPicker] is a widget that allows users to select or create
/// a category for a source. It provides a dropdown with predefined categories
/// and an option to create a custom category.
class SourceCategoryPicker extends StatefulWidget {
  const SourceCategoryPicker({
    super.key,
    required this.initialCategory,
    required this.onCategoryChanged,
  });

  final String? initialCategory;
  final Function(String?) onCategoryChanged;

  @override
  State<SourceCategoryPicker> createState() => _SourceCategoryPickerState();
}

class _SourceCategoryPickerState extends State<SourceCategoryPicker> {
  late String? _selectedCategory;
  final TextEditingController _customCategoryController = TextEditingController();
  bool _isCustomCategory = false;

  /// Predefined categories that users can choose from
  static const List<String> predefinedCategories = [
    'News',
    'Technology',
    'Sports',
    'Entertainment',
    'Business',
    'Science',
    'Health',
    'Gaming',
    'Programming',
    'Design',
    'Lifestyle',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    // Check if initial category is custom (not in predefined list)
    if (_selectedCategory != null &&
        !predefinedCategories.contains(_selectedCategory)) {
      _isCustomCategory = true;
      _customCategoryController.text = _selectedCategory!;
      _selectedCategory = 'Custom';
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  void _handleCategoryChange(String? value) {
    setState(() {
      _selectedCategory = value;
      _isCustomCategory = value == 'Custom';

      if (value == null || value == 'None') {
        widget.onCategoryChanged(null);
      } else if (value != 'Custom') {
        widget.onCategoryChanged(value);
      }
    });
  }

  void _handleCustomCategoryChange(String value) {
    if (_isCustomCategory && value.isNotEmpty) {
      widget.onCategoryChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Constants.spacingSmall),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a category',
          ),
          items: [
            const DropdownMenuItem(
              value: 'None',
              child: Text('No Category'),
            ),
            ...predefinedCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }),
            const DropdownMenuItem(
              value: 'Custom',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Custom Category'),
                ],
              ),
            ),
          ],
          onChanged: _handleCategoryChange,
        ),
        if (_isCustomCategory) ...[
          const SizedBox(height: Constants.spacingMiddle),
          TextFormField(
            controller: _customCategoryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Custom Category Name',
              hintText: 'Enter category name',
            ),
            onChanged: _handleCustomCategoryChange,
            validator: (value) {
              if (_isCustomCategory && (value == null || value.isEmpty)) {
                return 'Please enter a category name';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
