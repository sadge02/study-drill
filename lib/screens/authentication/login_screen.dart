import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:study_drill/utils/constants/authentication/login_screen/login_screen_constants.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/utils.dart';
import 'package:study_drill/widgets/authentication/authentication_input_field.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../service/authentication/authentication_service.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthenticationService _authService = AuthenticationService();

  bool _isPasswordObscure = true;

  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String? loggedUser = await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (loggedUser != null) {
          showTopSnackBar(
            Overlay.of(context),
            displayDuration: const Duration(
              milliseconds: GeneralConstants.notificationDuration,
            ),
            snackBarPosition: SnackBarPosition.bottom,
            CustomSnackBar.error(message: loggedUser),
          );
        } else {
          showTopSnackBar(
            Overlay.of(context),
            displayDuration: const Duration(
              milliseconds: GeneralConstants.notificationDuration,
            ),
            snackBarPosition: SnackBarPosition.bottom,
            const CustomSnackBar.success(message: 'Login successful'),
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
        elevation: GeneralConstants.appbarElevation,
        toolbarHeight: GeneralConstants.appbarHeight,
        centerTitle: true,
        title: Text(
          LoginScreenConstants.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: Utils.isMobile(context)
                ? GeneralConstants.mediumTitleSize
                : GeneralConstants.largeTitleSize,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: SizedBox(
              width: Utils.isMobile(context)
                  ? Utils.getWidth(context) * GeneralConstants.widthRatioMobile
                  : Utils.getWidth(context) *
                        GeneralConstants.widthRatioDesktop,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: GeneralConstants.mediumSpacing,
                children: [
                  const SizedBox(height: GeneralConstants.smallSpacing),

                  /// EMAIL INPUT
                  AuthenticationInputField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    isEmail: true,
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

                  /// LOGIN BUTTON
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: GeneralConstants.primaryColor,
                        )
                      : SizedBox(
                          width: LoginScreenConstants.buttonWidth,
                          height: LoginScreenConstants.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GeneralConstants.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  GeneralConstants.mediumCircularRadius,
                                ),
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.lexend(
                                fontSize: GeneralConstants.mediumFontSize,
                                fontWeight: FontWeight.w300,
                                color: GeneralConstants.backgroundColor,
                              ),
                            ),
                          ),
                        ),

                  /// REGISTER SCREEN BUTTON
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition<void>(
                          type: PageTransitionType.fade,
                          duration: const Duration(
                            milliseconds: GeneralConstants.transitionDuration,
                          ),
                          child: const RegistrationScreen(),
                          isIos: true,
                        ),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register',
                      style: GoogleFonts.lexend(
                        color: GeneralConstants.primaryColor,
                        fontWeight: FontWeight.w400,
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
