import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:feeddeck/models/source.dart';
import 'package:feeddeck/repositories/app_repository.dart';
import 'package:feeddeck/utils/constants.dart';
import 'package:feeddeck/widgets/general/elevated_button_progress_indicator.dart';
import 'package:feeddeck/widgets/source/source_category_picker.dart';

/// [SourceListItem] can be used to show the source within a list of sources.
/// This widget should for example be used to show the list of sources in the
/// create column or column settings widget.
class SourceListItem extends StatefulWidget {
  const SourceListItem({
    super.key,
    required this.columnId,
    required this.sourceIndex,
    required this.source,
  });

  final String columnId;
  final int sourceIndex;
  final FDSource source;
  @override
  State<SourceListItem> createState() => _SourceListItemState();
}

class _SourceListItemState extends State<SourceListItem> {
  bool _isLoading = false;
  bool _isFavoriteLoading = false;

  /// [_toggleFavorite] toggles the favorite status of the source.
  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      AppRepository app = Provider.of<AppRepository>(context, listen: false);
      await app.toggleSourceFavorite(widget.columnId, widget.source.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          backgroundColor: Constants.error,
          showCloseIcon: true,
          content: Text(
            'Could not update favorite status. Please try again.',
            style: TextStyle(color: Constants.onError),
          ),
        ),
      );
    }

    setState(() {
      _isFavoriteLoading = false;
    });
  }

  /// [_showCategoryDialog] shows a dialog to edit the category of the source.
  void _showCategoryDialog() {
    String? tempCategory = widget.source.category;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width >=
                    (Constants.centeredFormMaxWidth +
                        2 * Constants.spacingMiddle)
                ? (MediaQuery.of(context).size.width -
                          Constants.centeredFormMaxWidth) /
                      2
                : Constants.spacingMiddle,
          ),
          title: const Text('Edit Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: SourceCategoryPicker(
              initialCategory: widget.source.category,
              onCategoryChanged: (category) {
                tempCategory = category;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Constants.onSurface),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  AppRepository app = Provider.of<AppRepository>(context, listen: false);
                  await app.updateSourceCategory(
                    widget.columnId,
                    widget.source.id,
                    tempCategory,
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 5),
                      backgroundColor: Constants.error,
                      showCloseIcon: true,
                      content: Text(
                        'Could not update category. Please try again.',
                        style: TextStyle(color: Constants.onError),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// [_showDeleteDialog] creates a new dialog, which is shown before the column
  /// can be deleted. This is done to raise the awareness that the column,
  /// sources and items which belongs to the column will also be deleted.
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width >=
                    (Constants.centeredFormMaxWidth +
                        2 * Constants.spacingMiddle)
                ? (MediaQuery.of(context).size.width -
                          Constants.centeredFormMaxWidth) /
                      2
                : Constants.spacingMiddle,
          ),
          title: const Text('Delete Source'),
          content: const Text(
            'Do you really want to delete this source? This can not be undone and will also delete all items and bookmarks related to this source.',
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
              onPressed: _isLoading ? null : () => _deleteSource(),
              child: _isLoading
                  ? const ElevatedButtonProgressIndicator()
                  : const Text(
                      'Delete',
                      style: TextStyle(color: Constants.error),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// [_deleteSource] deletes the source with the provided [sourceId] from the
  /// current column.
  Future<void> _deleteSource() async {
    Navigator.of(context).pop();

    setState(() {
      _isLoading = true;
    });

    try {
      AppRepository app = Provider.of<AppRepository>(context, listen: false);
      await app.deleteSource(widget.columnId, widget.source.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 10),
          backgroundColor: Constants.error,
          showCloseIcon: true,
          content: Text(
            'Source could not be deleted. Please try again later.',
            style: TextStyle(color: Constants.onError),
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: widget.sourceIndex,
      child: Card(
        color: Constants.secondary,
        margin: const EdgeInsets.only(bottom: Constants.spacingSmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(Constants.spacingMiddle),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Characters(widget.source.title)
                              .replaceAll(
                                Characters(''),
                                Characters('\u{200B}'),
                              )
                              .toString(),
                          maxLines: 1,
                          style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Characters(widget.source.type.toLocalizedString())
                              .replaceAll(
                                Characters(''),
                                Characters('\u{200B}'),
                              )
                              .toString(),
                          maxLines: 1,
                          style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 10.0,
                          ),
                        ),
                        if (widget.source.category != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.label,
                                size: 10,
                                color: Constants.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.source.category!,
                                style: const TextStyle(
                                  fontSize: 10.0,
                                  color: Constants.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showCategoryDialog(),
                        icon: Icon(
                          Icons.label_outline,
                          color: widget.source.category != null
                              ? Constants.primary
                              : Constants.onSurface,
                        ),
                        tooltip: 'Edit category',
                      ),
                      IconButton(
                        onPressed: _isFavoriteLoading ? null : () => _toggleFavorite(),
                        icon: _isFavoriteLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                widget.source.isFavorite ? Icons.star : Icons.star_border,
                                color: widget.source.isFavorite
                                    ? Constants.primary
                                    : Constants.onSurface,
                              ),
                        tooltip: widget.source.isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteDialog(),
                        icon: _isLoading
                            ? const ElevatedButtonProgressIndicator()
                            : const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
