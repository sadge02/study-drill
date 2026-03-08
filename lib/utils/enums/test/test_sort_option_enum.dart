/// Enum for test sorting options.
///
/// Defines the different ways tests can be sorted in the application.
enum TestSortOption {
  /// Sort tests by number of attempts from highest to lowest.
  mostAttempts,

  /// Sort tests by number of attempts from lowest to highest.
  fewestAttempts,

  /// Sort tests by number of questions from highest to lowest.
  mostQuestions,

  /// Sort tests by number of questions from lowest to highest.
  fewestQuestions,

  /// Sort tests by creation date with newest first.
  newest,

  /// Sort tests by creation date with oldest first.
  oldest,

  /// Sort tests alphabetically by title (A-Z).
  alphabetical,
}
