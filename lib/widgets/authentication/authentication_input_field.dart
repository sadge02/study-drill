import 'package:flutter/material.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';
import 'package:study_drill/utils/enums/authentication_input_type_enum.dart';
import 'package:study_drill/utils/utils.dart';

import '../../utils/constants/authentication/widgets/authentication_input_field_constants.dart';

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

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final AuthenticationInputType type;
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
      decoration: _buildInputDecoration(),
      validator: _validate,
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      prefixIcon: Icon(icon, color: GeneralConstants.secondaryColor),
      suffixIcon: _buildSuffixIcon(),
      hintText: hint,
      hintStyle: TextStyle(
        color: GeneralConstants.secondaryColor.withValues(
          alpha: AuthenticationInpputFieldWidgetConstants.inputTextOpacity,
        ),
      ),
      filled: true,
      fillColor: GeneralConstants.tertiaryColor.withValues(
        alpha: AuthenticationInpputFieldWidgetConstants.inputBackgroundOpacity,
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
    );
  }

  Widget? _buildSuffixIcon() {
    if (type == AuthenticationInputType.password ||
        type == AuthenticationInputType.confirmPassword) {
      return IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: GeneralConstants.secondaryColor,
        ),
        onPressed: toggleVisibility,
      );
    }
    return null;
  }

  String? _validate(String? value) {
    if (type != AuthenticationInputType.profilePic) {
      if (value == null || value.isEmpty) {
        return AuthenticationValidatorConstants.requiredFieldMessage;
      }
    }
    switch (type) {
      case AuthenticationInputType.email:
        if (!Utils.isValidEmail(value!)) {
          return AuthenticationValidatorConstants.emailInvalidMessage;
        }
        break;
      case AuthenticationInputType.password:
        if (value!.length <
            AuthenticationValidatorConstants.minimumSizePassword) {
          return '${AuthenticationValidatorConstants.passwordShortMessage} ${AuthenticationValidatorConstants.minimumSizePassword}';
        }
        break;
      case AuthenticationInputType.confirmPassword:
        if (compareController != null && value != compareController!.text) {
          return AuthenticationValidatorConstants.passwordMismatchMessage;
        }
        break;
      default:
        return null;
    }
    return null;
  }
}
