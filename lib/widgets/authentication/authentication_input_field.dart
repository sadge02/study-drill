import 'package:flutter/material.dart';
import 'package:study_drill/utils/constants/authentication/utils/authentication_validator_constants.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/utils.dart';

import '../../utils/constants/authentication/widget/authentication_widget_constants.dart';

class AuthenticationInputField extends StatelessWidget {
  const AuthenticationInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isEmail = false,
    this.isConfirmPassword = false,
    this.obscureText = false,
    this.isProfilePicLink = false,
    this.toggleVisibility,
    this.onChanged,
    this.compareController,
  });

  final TextEditingController controller;

  final String hint;

  final IconData icon;

  final bool isPassword;
  final bool isEmail;
  final bool isConfirmPassword;
  final bool isProfilePicLink;

  final bool obscureText;

  final VoidCallback? toggleVisibility;

  final void Function(String)? onChanged;

  final TextEditingController? compareController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(color: GeneralConstants.primaryColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: GeneralConstants.secondaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: GeneralConstants.secondaryColor,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        hintText: hint,
        hintStyle: TextStyle(
          color: GeneralConstants.secondaryColor.withValues(
            alpha: AuthenticationWidgetConstants.inputTextOpacity,
          ),
        ),
        filled: true,
        fillColor: GeneralConstants.tertiaryColor.withValues(
          alpha: AuthenticationWidgetConstants.inputBackgroundOpacity,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: GeneralConstants.mediumPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (!isConfirmPassword &&
            (value == null || value.isEmpty) &&
            !isProfilePicLink) {
          return 'This field is required';
        }
        if (isEmail && !Utils.isValidEmail(value!)) {
          return 'Invalid email address';
        }
        if (isPassword &&
            value!.length <
                AuthenticationValidatorConstants.minimumSizePassword) {
          return 'Password too short (min ${AuthenticationValidatorConstants.minimumSizePassword})';
        }
        if (isConfirmPassword &&
            compareController != null &&
            value != compareController!.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
