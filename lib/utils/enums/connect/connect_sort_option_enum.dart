/// Enum for connect game sorting options.
///
/// Defines the different ways connect games can be sorted in the application.
enum ConnectSortOption {
  /// Sort connect games by number of attempts from highest to lowest.
  mostAttempts,

  /// Sort connect games by number of attempts from lowest to highest.
  fewestAttempts,

  /// Sort connect games by number of pairs from highest to lowest.
  mostPairs,

  /// Sort connect games by number of pairs from lowest to highest.
  fewestPairs,

  /// Sort connect games by creation date with newest first.
  newest,

  /// Sort connect games by creation date with oldest first.
  oldest,

  /// Sort connect games alphabetically by title (A-Z).
  alphabetical,
}
