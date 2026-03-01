import 'package:flutter/material.dart';
import 'package:study_drill/utils/constants/core/general_constants.dart';
import 'package:study_drill/utils/core/utils.dart';
import 'package:study_drill/utils/enums/authentication/authentication_input_type_enum.dart';

import '../../utils/constants/authentication/validator/authentication_validator_constants.dart';
import '../../utils/constants/authentication/widgets/authentication_input_field_constants.dart';
import '../../utils/constants/error/messages/firebase_exception_constants.dart';

/// A customizable text input field for authentication screens.
///
/// [AuthenticationInputField] provides a styled form field with built-in validation
/// for different input types (email, password, confirmation password, profile picture, etc).
/// It includes visual feedback through icons, hint text, and optional password visibility toggle.
class AuthenticationInputField extends StatelessWidget {
  const AuthenticationInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.type = AuthenticationInputType.text,
    this.obscureText = false,
    this.toggleVisibility,
    this.onChanged,
    this.compareController,
  });

  /// The controller for managing the text input value.
  final TextEditingController controller;

  /// The hint text displayed when the field is empty.
  final String hint;

  /// The leading icon displayed in the input field.
  final IconData icon;

  /// The type of input field (determines validation and behavior).
  final AuthenticationInputType type;

  /// Whether the text should be obscured (for password fields).
  final bool obscureText;

  /// Callback to toggle text visibility for password fields.
  final VoidCallback? toggleVisibility;

  /// Callback triggered when the text value changes.
  final void Function(String)? onChanged;

  /// Controller to compare against (used for password confirmation).
  final TextEditingController? compareController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      maxLength: _getMaxLength(),
      style: const TextStyle(color: GeneralConstants.primaryColor),
      decoration: _buildInputDecoration(),
      validator: _validate,
    );
  }

  /// Gets the maximum character length based on input type.
  int? _getMaxLength() {
    switch (type) {
      case AuthenticationInputType.email:
        return AuthenticationValidatorConstants.maximumSizeEmail;
      case AuthenticationInputType.password:
      case AuthenticationInputType.confirmPassword:
        return AuthenticationValidatorConstants.maximumSizePassword;
      default:
        return null;
    }
  }

  /// Builds the input field decoration with styling and icons.
  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      prefixIcon: Icon(icon, color: GeneralConstants.secondaryColor),
      suffixIcon: _buildSuffixIcon(),
      hintText: hint,
      hintMaxLines: 1,
      hintStyle: TextStyle(
        color: GeneralConstants.secondaryColor.withValues(
          alpha: AuthenticationInputFieldWidgetConstants.inputTextOpacity,
        ),
      ),
      filled: true,
      fillColor: GeneralConstants.tertiaryColor.withValues(
        alpha: AuthenticationInputFieldWidgetConstants.inputBackgroundOpacity,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.mediumPadding,
      ),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// Builds the suffix icon (visibility toggle for password fields).
  Widget? _buildSuffixIcon() {
    if (type == AuthenticationInputType.password ||
        type == AuthenticationInputType.confirmPassword) {
      return IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: GeneralConstants.secondaryColor,
          size: GeneralConstants.smallIconSize,
        ),
        onPressed: toggleVisibility,
      );
    }
    return null;
  }

  /// Validates the input based on its type and value.
  String? _validate(String? value) {
    if (type != AuthenticationInputType.profilePic) {
      if (value == null || value.isEmpty) {
        return FirebaseExceptionConstants.requiredFieldMessage;
      }
    }
    switch (type) {
      case AuthenticationInputType.email:
        if (!Utils.isValidEmail(value!)) {
          return FirebaseExceptionConstants.emailInvalidMessage;
        }
        break;
      case AuthenticationInputType.password:
        if (value!.length <
            AuthenticationValidatorConstants.minimumSizePassword) {
          return '${FirebaseExceptionConstants.passwordShortMessage} ${AuthenticationValidatorConstants.minimumSizePassword}';
        }
        break;
      case AuthenticationInputType.confirmPassword:
        if (compareController != null && value != compareController!.text) {
          return FirebaseExceptionConstants.passwordMismatchMessage;
        }
        break;
      default:
        return null;
    }
    return null;
  }
}
