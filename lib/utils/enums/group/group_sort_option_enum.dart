/// Enum for group sorting options.
///
/// Defines the different ways groups can be sorted in the application.
enum GroupSortOption {
  /// Sort groups by creation date with newest first.
  newest,

  /// Sort groups by creation date with oldest first.
  oldest,

  /// Sort groups by last update date with most recently updated first.
  recentlyUpdated,

  /// Sort groups by last update date with least recently updated first.
  leastRecentlyUpdated,

  /// Sort groups by member count from highest to lowest.
  memberCount,

  /// Sort groups by total content count (tests + flashcards + connects).
  mostContent,

  /// Sort groups alphabetically by title (A-Z).
  alphabetical,
}
