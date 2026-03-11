import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/enums/authentication/authentication_input_type_enum.dart';
import '../../utils/validators/authentication/authentication_validator.dart';

class AuthenticationInputField extends StatelessWidget {
  const AuthenticationInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.type = AuthenticationInputType.username,
    this.obscureText = false,
    this.toggleVisibility,
    this.compareController,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final AuthenticationInputType type;
  final bool obscureText;
  final VoidCallback? toggleVisibility;
  final TextEditingController? compareController;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: _keyboardType(),
      validator: _validator,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
        prefixIcon: Icon(icon, color: GeneralConstants.primaryColor),
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: GeneralConstants.tertiaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          borderSide: const BorderSide(color: GeneralConstants.secondaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          borderSide: const BorderSide(color: GeneralConstants.failureColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          borderSide: const BorderSide(color: GeneralConstants.failureColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.mediumPadding,
          vertical: GeneralConstants.smallPadding,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (type == AuthenticationInputType.password ||
        type == AuthenticationInputType.confirmPassword) {
      return IconButton(
        icon: Icon(
          obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: GeneralConstants.primaryColor,
        ),
        onPressed: toggleVisibility,
      );
    }
    return null;
  }

  TextInputType _keyboardType() {
    switch (type) {
      case AuthenticationInputType.email:
        return TextInputType.emailAddress;
      case AuthenticationInputType.profilePic:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  String? _validator(String? value) {
    switch (type) {
      case AuthenticationInputType.username:
        return AuthenticationValidator.validateUsername(value);
      case AuthenticationInputType.email:
        return AuthenticationValidator.validateEmail(value);
      case AuthenticationInputType.password:
        return AuthenticationValidator.validatePassword(value);
      case AuthenticationInputType.confirmPassword:
        final passwordError = AuthenticationValidator.validatePassword(value);
        if (passwordError != null) return passwordError;
        if (compareController != null && value != compareController!.text) {
          return FirebaseExceptionConstants.passwordMismatchMessage;
        }
        return null;
      case AuthenticationInputType.profilePic:
        return null;
    }
  }
}
