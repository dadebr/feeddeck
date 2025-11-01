import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:feeddeck/models/source.dart';
import 'package:feeddeck/repositories/app_repository.dart';
import 'package:feeddeck/repositories/layout_repository.dart';
import 'package:feeddeck/utils/constants.dart';
import 'package:feeddeck/widgets/column/column_layout.dart';
import 'package:feeddeck/widgets/column/create/create_column.dart';
import 'package:feeddeck/widgets/general/logo.dart';
import 'package:feeddeck/widgets/settings/settings.dart';
import 'package:feeddeck/widgets/source/source_icon.dart';

/// The [DeckLayoutLarge] implements the deck screen via a navigation rail for
/// screens larger then our defined breakpoint. It displays a navigation rail on
/// the left side of the screen and all columns of the deck.
class DeckLayoutLarge extends StatefulWidget {
  const DeckLayoutLarge({super.key});

  @override
  State<DeckLayoutLarge> createState() => _DeckLayoutLargeState();
}

class _DeckLayoutLargeState extends State<DeckLayoutLarge> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AutoScrollController _scrollController = AutoScrollController();
  Widget _drawer = Container();

  /// Map to store custom column widths. Key is column ID, value is width.
  final Map<String, double> _columnWidths = {};

  /// Whether auto-sizing is enabled (columns fill available width)
  bool _autoSize = true;

  /// [_openDrawer] opens the provided [widget] in the drawer of the scaffold,
  /// by setting the [_drawer] state first and then opening the drawer.
  void _openDrawer(Widget widget) {
    setState(() {
      _drawer = widget;
    });
    _scaffoldKey.currentState?.openDrawer();
  }

  /// [_getColumnWidth] returns the width for a given column.
  /// If auto-sizing is enabled, it calculates equal widths for all columns.
  /// Otherwise, it uses custom widths or falls back to the default width.
  double _getColumnWidth(String columnId, double availableWidth, int columnCount) {
    if (_autoSize && columnCount > 0) {
      // Distribute available width equally among all columns
      return (availableWidth / columnCount).clamp(200.0, double.infinity);
    }

    // Return custom width if set, otherwise use default
    return _columnWidths[columnId] ?? Constants.columnWidth;
  }

  /// [_buildDestinations] returns a list of destinations for the
  /// [NavigationRail]. The destination are created based on the columns in the
  /// [AppRepository]. Each destination will have the column name as `title` and
  /// the icon of the first source in a column as `icon`.
  ///
  /// Since the [NavigationRail] needs at least two destinations, we will fill
  /// the destinations with some invisible destinations, when the number of
  /// columns is less then 2.
  List<NavigationRailDestination> _buildDestinations() {
    AppRepository app = Provider.of<AppRepository>(context, listen: false);
    final List<NavigationRailDestination> widgets = [];

    for (var column in app.columns) {
      widgets.add(
        NavigationRailDestination(
          padding: const EdgeInsets.only(
            top: Constants.spacingSmall + Constants.spacingExtraSmall,
          ),
          icon: SourceIcon(
            type: column.sources.isNotEmpty
                ? column.sources[0].type
                : FDSourceType.none,
            icon: column.sources.isNotEmpty ? column.sources[0].icon : null,
            size: 32,
          ),
          label: Container(
            padding: const EdgeInsets.only(top: Constants.spacingExtraSmall),
            constraints: const BoxConstraints(minWidth: 54, maxWidth: 54),
            child: Text(
              Characters(
                column.name,
              ).replaceAll(Characters(''), Characters('\u{200B}')).toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    for (var i = widgets.length; i < 2; i++) {
      widgets.add(
        const NavigationRailDestination(
          icon: Icon(Icons.circle, color: Colors.transparent),
          label: Text(''),
        ),
      );
    }

    return widgets;
  }

  /// [_buildColumns] builds the columns view which is displayed next to the
  /// navigation rail. Each column is implemented via the [ColumnLayout] widget
  /// which we are already using for smaller screens, but we are adding an
  /// additional border to the columns for a better seperation.
  Widget _buildColumns() {
    AppRepository app = Provider.of<AppRepository>(context, listen: false);

    if (app.columns.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Constants.spacingMiddle),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(color: Constants.onSurface, fontSize: 14.0),
                children: [
                  TextSpan(
                    text: 'Add you first column by clicking on the plus icon (',
                  ),
                  WidgetSpan(child: Icon(Icons.add, size: 14.0)),
                  TextSpan(text: ') in the sidebar on the left side.'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final columnCount = app.columns.length;

          if (_autoSize) {
            // Auto-size mode: use Row with Expanded to fill available width
            final List<Widget> widgets = [];

            for (var i = 0; i < columnCount; i++) {
              final column = app.columns[i];

              widgets.add(
                Expanded(
                  child: AutoScrollTag(
                    key: ValueKey(column.id),
                    controller: _scrollController,
                    index: i,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.black,
                            width: Constants.columnSpacing,
                          ),
                        ),
                      ),
                      child: ColumnLayout(
                        key: ValueKey(column.id),
                        column: column,
                        openDrawer: _openDrawer,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Row(children: widgets);
          } else {
            // Manual resize mode: each column has resizable dividers on both sides
            final List<Widget> widgets = [];

            for (var i = 0; i < columnCount; i++) {
              final column = app.columns[i];
              final columnWidth = _columnWidths[column.id] ?? Constants.columnWidth;

              // Add left divider for this column (resizes previous column when dragged)
              if (i > 0) {
                final prevColumn = app.columns[i - 1];
                widgets.add(
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          final currentWidth = _columnWidths[prevColumn.id] ?? Constants.columnWidth;
                          final newWidth = (currentWidth + details.delta.dx).clamp(200.0, 1000.0);
                          _columnWidths[prevColumn.id] = newWidth;
                        });
                      },
                      child: Container(
                        width: Constants.columnSpacing * 3,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: Constants.dividerColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Add the column
              widgets.add(
                AutoScrollTag(
                  key: ValueKey(column.id),
                  controller: _scrollController,
                  index: i,
                  child: SizedBox(
                    width: columnWidth,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.black,
                            width: Constants.columnSpacing,
                          ),
                        ),
                      ),
                      child: ColumnLayout(
                        key: ValueKey(column.id),
                        column: column,
                        openDrawer: _openDrawer,
                      ),
                    ),
                  ),
                ),
              );

              // Add right divider for this column (resizes this column when dragged)
              widgets.add(
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        final currentWidth = _columnWidths[column.id] ?? Constants.columnWidth;
                        final newWidth = (currentWidth + details.delta.dx).clamp(200.0, 1000.0);
                        _columnWidths[column.id] = newWidth;
                      });
                    },
                    child: Container(
                      width: Constants.columnSpacing * 3,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 2,
                          color: Constants.dividerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              children: widgets,
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// We have to subscribe to all changes in the [AppRepository] so that we
    /// can retrigger the [_buildDestinations] and [_buildColumns] functions on
    /// a change.
    Provider.of<AppRepository>(context, listen: true);

    return Scaffold(
      key: _scaffoldKey,

      /// The drawer is used to display the [CreateColumn] widget, so that a
      /// user can add a new column without leaving the screen.
      drawer: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(Constants.spacingMiddle),
          bottomRight: Radius.circular(Constants.spacingMiddle),
        ),
        child: Drawer(width: Constants.columnWidth, child: _drawer),
      ),
      body: SafeArea(
        child: Row(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: NavigationRail(
                      backgroundColor: Constants.surface,
                      selectedIndex: null,

                      /// When a user selects a destination in the navigation
                      /// rail we scroll to the corresponding column by using
                      /// the `scroll_to_index` package.
                      onDestinationSelected: (int index) {
                        /// Before we scroll to the corresponding column, we
                        /// also update the [deckLayoutSmallInitialTabIndex] in
                        /// the [LayoutRepository] so that the correct tab is
                        /// also selected when a user switches to the small
                        /// layout.
                        Provider.of<LayoutRepository>(
                          context,
                          listen: false,
                        ).deckLayoutSmallInitialTabIndex = index;

                        _scrollController.scrollToIndex(
                          index,
                          preferPosition: AutoScrollPosition.end,
                        );
                      },
                      labelType: NavigationRailLabelType.all,
                      leading: Container(
                        padding: const EdgeInsets.only(
                          top: Constants.spacingSmall,
                          bottom: Constants.spacingSmall,
                        ),
                        child: const Logo(size: 32.0),
                      ),

                      /// We add additional items to the navigation rail via
                      /// the trailing property. These items are used to allow a
                      /// user to create a new column, toggle auto-sizing, and
                      /// go to the settings of the app.
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Wrap(
                            direction: Axis.vertical,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'Add Column',
                                onPressed: () {
                                  _openDrawer(const CreateColumn());
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _autoSize ? Icons.view_column : Icons.width_full,
                                  color: _autoSize ? Constants.primary : Constants.onSurface,
                                ),
                                tooltip: _autoSize
                                    ? 'Auto-size enabled (click to resize manually)'
                                    : 'Manual resize enabled (click for auto-size)',
                                onPressed: () {
                                  setState(() {
                                    _autoSize = !_autoSize;
                                    if (_autoSize) {
                                      // Clear custom widths when enabling auto-size
                                      _columnWidths.clear();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                tooltip: 'Settings',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          const Settings(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: Constants.spacingMiddle),
                            ],
                          ),
                        ),
                      ),
                      destinations: _buildDestinations(),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(
              color: Constants.dividerColor,
              width: 1,
              thickness: 1,
            ),
            SizedBox(
              width: Constants.columnSpacing,
              height: MediaQuery.of(context).size.height,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            ),
            _buildColumns(),
          ],
        ),
      ),
    );
  }
}
