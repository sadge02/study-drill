class DatabaseConstants {
  /// COLLECTIONS ///

  // Firestore collection name for storing user documents.
  static const String usersCollection = 'users';

  // Firestore collection name for storing username reservations and mappings.
  static const String usernamesCollection = 'usernames';

  // Firestore collection name for storing group documents.
  static const String groupsCollection = 'groups';

  // Firestore collection name for storing connect game documents.
  static const String connectsCollection = 'connects';

  // Firestore collection name for storing flashcard set documents.
  static const String flashcardsCollection = 'flashcards';

  // Firestore collection name for storing test documents.
  static const String testsCollection = 'tests';

  /// CONSTRAINTS ///

  // Maximum number of operations per Firestore batch write.
  static const int batchLimit = 500;

  // Maximum number of values allowed in a single Firestore whereIn query.
  static const int whereInLimit = 10;
}
