/// Enum representing the different roles a user can have within a group.
///
/// Used to fetch groups where a user holds a specific role.
enum GroupRole {
  /// The user is the author (owner) of the group.
  author,

  /// The user is an administrator of the group.
  admin,

  /// The user is a content creator (editor) in the group.
  creator,

  /// The user is a regular member of the group.
  member,
}
