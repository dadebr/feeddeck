import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feeddeck/models/column.dart';
import 'package:feeddeck/repositories/items_repository.dart';
import 'package:feeddeck/widgets/column/header/column_layout_header.dart';
import 'package:feeddeck/widgets/column/list/column_layout_list.dart';
import 'package:feeddeck/widgets/column/loading/column_layout_loading.dart';
import 'package:feeddeck/widgets/column/search/column_layout_search.dart';

/// The [ColumnLayout] widget defines the layout of a single column in a deck.
/// The widget must be usable for small and large screens.
///
/// To use the widget a column must be set via the [column] parameter. The
/// [openDrawer] parameter defines an optional function for large screen, to
/// open the passed in widget in a drawer.
class ColumnLayout extends StatefulWidget {
  const ColumnLayout({
    super.key,
    required this.column,
    required this.openDrawer,
  });

  final FDColumn column;
  final void Function(Widget widget)? openDrawer;

  @override
  State<ColumnLayout> createState() => _ColumnLayoutState();
}

class _ColumnLayoutState extends State<ColumnLayout> {
  /// Whether card view mode is enabled (shows thumbnails and full content)
  /// When false, shows compact list view (headlines only)
  bool _isCardView = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  /// Load the saved view preference from SharedPreferences
  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedViewMode = prefs.getBool('isCardView') ?? true;
      setState(() {
        _isCardView = savedViewMode;
        _isLoading = false;
      });
    } catch (e) {
      // If loading fails, use default value
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Toggle view mode and save the preference
  Future<void> _toggleViewMode() async {
    setState(() {
      _isCardView = !_isCardView;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCardView', _isCardView);
    } catch (e) {
      // Silently fail if saving fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading state while loading preference
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ItemsRepository(column: widget.column, context: context),
      child: Column(
        children: [
          ColumnLayoutHeader(
            column: widget.column,
            openDrawer: widget.openDrawer,
            isCardView: _isCardView,
            onToggleViewMode: _toggleViewMode,
          ),
          const ColumnLayoutSearch(),
          const ColumnLayoutLoading(),
          ColumnLayoutList(isCardView: _isCardView),
        ],
      ),
    );
  }
}
