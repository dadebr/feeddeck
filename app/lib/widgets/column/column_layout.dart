import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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

  void _toggleViewMode() {
    setState(() {
      _isCardView = !_isCardView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ItemsRepository(column: widget.column, context: context),
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
