/// Enum for authentication input field types.
///
/// Defines the different types of input fields used in authentication screens.
/// Each type determines validation rules, formatting, and visual behavior.
enum AuthenticationInputType {
  /// Email address input field.
  email,

  /// Password input field.
  password,

  /// Password confirmation input field.
  confirmPassword,

  /// Profile picture URL input field.
  profilePic,

  /// Generic text input field.
  text,
}
