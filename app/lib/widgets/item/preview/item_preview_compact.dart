import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:feeddeck/models/item.dart';
import 'package:feeddeck/models/source.dart';
import 'package:feeddeck/repositories/items_repository.dart';
import 'package:feeddeck/utils/constants.dart';
import 'package:feeddeck/widgets/item/preview/utils/details.dart';

/// The [ItemPreviewCompact] widget displays a compact preview for an item,
/// showing only the title and timestamp in a list format without thumbnails.
/// This is used for the "list view" mode.
class ItemPreviewCompact extends StatelessWidget {
  const ItemPreviewCompact({
    super.key,
    required this.item,
  });

  final FDItem item;

  @override
  Widget build(BuildContext context) {
    ItemsRepository items = Provider.of<ItemsRepository>(context, listen: true);
    final source = items.getSource(item.sourceId);

    /// If we are not able to get a source for the item something must be odd,
    /// so we don't display anything.
    if (source == null) {
      return Container();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDetails(context, item, source),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: item.isRead ? Constants.secondary : Constants.surface,
            border: const Border(
              bottom: BorderSide(color: Constants.dividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.spacingSmall,
            vertical: Constants.spacingExtraSmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Bookmark indicator
              if (item.isBookmarked)
                const Padding(
                  padding: EdgeInsets.only(right: Constants.spacingExtraSmall),
                  child: Icon(
                    Icons.bookmark,
                    size: 14.0,
                    color: Constants.primary,
                  ),
                ),

              /// Title
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                    color: Constants.onSurface,
                  ),
                ),
              ),

              /// Timestamp
              if (item.publishedAt != 0)
                Padding(
                  padding: const EdgeInsets.only(left: Constants.spacingExtraSmall),
                  child: Text(
                    _formatTimestamp(item.publishedAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Constants.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats the timestamp to show relative time (e.g., "2h ago", "3d ago")
  String _formatTimestamp(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - timestamp;

    if (diff < 60) {
      return '${diff}s';
    } else if (diff < 3600) {
      return '${diff ~/ 60}m';
    } else if (diff < 86400) {
      return '${diff ~/ 3600}h';
    } else {
      return '${diff ~/ 86400}d';
    }
  }
}
