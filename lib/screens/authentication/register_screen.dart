import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/utils/constants/authentication/registration_screen_constants.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/utils.dart';
import 'package:study_drill/widgets/authentication/authentication_input_field.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../authentication/service/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _avatarLinkController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  bool _isLoading = false;

  String get _profilePicUrl {
    if (_avatarLinkController.text.trim().isNotEmpty) {
      return _avatarLinkController.text.trim();
    }
    final String name = _userController.text.trim().isEmpty
        ? 'User'
        : _userController.text.trim();
    return 'https://ui-avatars.com/api/?name=$name&background=6096B4&color=fff&size=128';
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String? registeredUser = await _authService.registerUser(
        username: _userController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        profilePicUrl: _profilePicUrl,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (registeredUser == null) {
          showTopSnackBar(
            Overlay.of(context),
            displayDuration: const Duration(
              seconds: GeneralConstants.notificationDuration,
            ),
            snackBarPosition: SnackBarPosition.bottom,
            const CustomSnackBar.success(message: 'Registration successful.'),
          );
          Navigator.pop(context);
        } else {
          showTopSnackBar(
            Overlay.of(context),
            displayDuration: const Duration(
              milliseconds: GeneralConstants.notificationDuration,
            ),
            snackBarPosition: SnackBarPosition.bottom,
            CustomSnackBar.error(message: registeredUser),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: GeneralConstants.notificationElevation,
        toolbarHeight: RegistrationScreenConstants.appbarHeight,
        iconTheme: const IconThemeData(color: GeneralConstants.primaryColor),
        centerTitle: true,
        title: Text(
          RegistrationScreenConstants.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: Utils.isMobile(context)
                ? RegistrationScreenConstants.titleSizeMobile
                : RegistrationScreenConstants.titleSizeDesktop,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Center(
            child: SizedBox(
              width: Utils.isMobile(context)
                  ? Utils.getWidth(context) *
                        RegistrationScreenConstants.widthRatioMobile
                  : Utils.getWidth(context) *
                        RegistrationScreenConstants.widthRatioDesktop,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: GeneralConstants.mediumSpacing,
                children: [
                  const SizedBox(height: GeneralConstants.smallSpacing),

                  /// PROFILE PICTURE
                  CircleAvatar(
                    radius: Utils.isMobile(context)
                        ? RegistrationScreenConstants
                              .profilePicBackgroundRadiusMobile
                        : RegistrationScreenConstants
                              .profilePicBackgroundRadiusDesktop,
                    backgroundColor: GeneralConstants.tertiaryColor,
                    child: CircleAvatar(
                      radius: Utils.isMobile(context)
                          ? RegistrationScreenConstants.profilePicRadiusMobile
                          : RegistrationScreenConstants.profilePicRadiusDesktop,
                      backgroundColor: GeneralConstants.tertiaryColor,
                      backgroundImage: NetworkImage(_profilePicUrl),
                    ),
                  ),

                  /// NAME INPUT
                  AuthenticationInputField(
                    controller: _userController,
                    hint: 'Username',
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),

                  /// EMAIL INPUT
                  AuthenticationInputField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    isEmail: true,
                  ),

                  /// PROFILE PIC INPUT
                  AuthenticationInputField(
                    controller: _avatarLinkController,
                    hint: 'Profile Picture Link (Optional)',
                    icon: Icons.link,
                    isProfilePicLink: true,
                    onChanged: (_) => setState(() {}),
                  ),

                  /// PASSWORD INPUT
                  AuthenticationInputField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _isPasswordObscure,
                    toggleVisibility: () => setState(
                      () => _isPasswordObscure = !_isPasswordObscure,
                    ),
                  ),

                  /// PASSWORD CONFIRMATION INPUT
                  AuthenticationInputField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    icon: Icons.check_circle_outline,
                    isPassword: true,
                    isConfirmPassword: true,
                    compareController: _passwordController,
                    obscureText: _isConfirmPasswordObscure,
                    toggleVisibility: () => setState(
                      () => _isConfirmPasswordObscure =
                          !_isConfirmPasswordObscure,
                    ),
                  ),

                  /// REGISTER BUTTON
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: GeneralConstants.primaryColor,
                        )
                      : SizedBox(
                          width: RegistrationScreenConstants.buttonWidth,
                          height: RegistrationScreenConstants.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GeneralConstants.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GeneralConstants.mediumCircularRadius,
                                ),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: GoogleFonts.lexend(
                                fontSize: GeneralConstants.mediumFontSize,
                                fontWeight: FontWeight.w300,
                                color: GeneralConstants.backgroundColor,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
