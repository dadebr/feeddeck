/// [FDItem] is the model for a item in our app. The following fields are
/// required for a item:
///   - An [id] to uniquely identify an item in the database
///   - A [sourceId] to define to which source the item belongs to
///   - A [title], [link] and a optional [media] (image or video), [description]
///     and [author]
///   - The [publishedAt] field is the Unix timestamp when the item was
///     published by a source
///   - The [isRead] field is used to define if the user has read the item
///   - The [isBookmarked] field is used to define if the user has bookmarked
///     the item (also serves as favorite/star functionality)
///   - The [category] field allows user to organize items into categories
///   - The [tags] field allows user to add multiple tags for flexible organization
class FDItem {
  String id;
  String sourceId;
  String title;
  String link;
  String? media;
  String? description;
  String? author;
  Map<String, dynamic>? options;
  int publishedAt;
  bool isRead;
  bool isBookmarked;
  String? category;
  List<String>? tags;

  FDItem({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.link,
    required this.media,
    required this.description,
    required this.author,
    required this.options,
    required this.publishedAt,
    required this.isRead,
    required this.isBookmarked,
    this.category,
    this.tags,
  });

  factory FDItem.fromJson(Map<String, dynamic> data) {
    return FDItem(
      id: data['id'],
      sourceId: data['sourceId'],
      title: data['title'],
      link: data['link'],
      media: data.containsKey('media') && data['media'] != null
          ? data['media']
          : null,
      description:
          data.containsKey('description') && data['description'] != null
              ? data['description']
              : null,
      author: data.containsKey('author') && data['author'] != null
          ? data['author']
          : null,
      options: data['options'],
      publishedAt: data['publishedAt'],
      isRead: data.containsKey('isRead') && data['isRead'] != null
          ? data['isRead']
          : false,
      isBookmarked:
          data.containsKey('isBookmarked') && data['isBookmarked'] != null
              ? data['isBookmarked']
              : false,
      category:
          data.containsKey('category') && data['category'] != null
              ? data['category']
              : null,
      tags:
          data.containsKey('tags') && data['tags'] != null
              ? List<String>.from(data['tags'])
              : null,
    );
  }
}
