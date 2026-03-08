/// Enum for flashcard set sorting options.
///
/// Defines the different ways flashcard sets can be sorted in the application.
enum FlashcardSortOption {
  /// Sort flashcard sets by number of attempts from highest to lowest.
  mostAttempts,

  /// Sort flashcard sets by number of attempts from lowest to highest.
  fewestAttempts,

  /// Sort flashcard sets by number of cards from highest to lowest.
  mostCards,

  /// Sort flashcard sets by number of cards from lowest to highest.
  fewestCards,

  /// Sort flashcard sets by creation date with newest first.
  newest,

  /// Sort flashcard sets by creation date with oldest first.
  oldest,

  /// Sort flashcard sets alphabetically by title (A-Z).
  alphabetical,
}
