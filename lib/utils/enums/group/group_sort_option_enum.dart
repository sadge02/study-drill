/// Enum for group sorting options.
///
/// Defines the different ways group can be sorted in the application.
/// Users can choose how to organize and view group based on their preferences.
enum GroupSortOption {
  /// Sort group by creation date with newest group first.
  newest,

  /// Sort group by creation date with oldest group first.
  oldest,

  /// Sort group by member count from highest to lowest.
  memberCount,

  /// Sort group by recent activity or engagement.
  mostActive,

  /// Sort group alphabetically by name (A-Z).
  alphabetical,
}
