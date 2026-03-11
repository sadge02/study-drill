import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../service/authentication/authentication_service.dart';
import '../../utils/constants/authentication/screens/authentication_login_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';
import '../../utils/enums/authentication/authentication_input_type_enum.dart';
import '../../widgets/authentication/authentication_input_field.dart';
import '../home/home_screen.dart';
import 'authentication_registration_screen.dart';

class AuthenticationLoginScreen extends StatefulWidget {
  const AuthenticationLoginScreen({super.key});

  @override
  State<AuthenticationLoginScreen> createState() =>
      _AuthenticationLoginScreenState();
}

class _AuthenticationLoginScreenState extends State<AuthenticationLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthenticationService _authenticationService = AuthenticationService();

  bool _isPasswordObscure = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final String? result = await _authenticationService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: AuthenticationLoginScreenConstants.loginSuccessMessage,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(
        const CustomSnackBar.error(
          message: AuthenticationLoginScreenConstants.loginFailureMessage,
        ),
      );
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(
        const CustomSnackBar.info(
          message: AuthenticationLoginScreenConstants.emailMissingMessage,
        ),
      );
      return;
    }

    final result = await _authenticationService.sendPasswordReset(email);

    if (!mounted) {
      return;
    }

    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: AuthenticationLoginScreenConstants.passwordResetSentMessage,
        ),
      );
    } else {
      _showSnackBar(
        const CustomSnackBar.error(
          message:
              AuthenticationLoginScreenConstants.passwordResetFailureMessage,
        ),
      );
    }
  }

  void _navigateToRegistration() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AuthenticationRegistrationScreen(),
      ),
    );
  }

  void _showSnackBar(Widget snackBar) {
    showTopSnackBar(
      Overlay.of(context),
      displayDuration: const Duration(
        milliseconds: GeneralConstants.notificationDurationMs,
      ),
      snackBarPosition: SnackBarPosition.bottom,
      snackBar,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GeneralConstants.backgroundColor,
      toolbarHeight: GeneralConstants.appBarHeight,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        AuthenticationLoginScreenConstants.appBarTitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.lexend(
          fontSize: Utils.isMobile(context)
              ? GeneralConstants.mediumTitleSize
              : GeneralConstants.largeTitleSize,
          fontWeight: FontWeight.w200,
          color: GeneralConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      body: Form(
        key: _formKey,
        child: Utils.isMobile(context)
            ? _buildBodyMobile(context)
            : _buildBodyDesktop(context),
      ),
    );
  }

  Widget _buildBodyDesktop(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.50,
        heightFactor: 0.75,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
            vertical: GeneralConstants.smallMargin,
          ),
          child: Column(
            children: [
              _buildEmailInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildPasswordInput(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildForgotPasswordButton(),
              _buildSpacing(height: GeneralConstants.largeSpacing),
              _buildLoginButton(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyMobile(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.75,
        heightFactor: 0.75,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GeneralConstants.smallMargin),
          child: Column(
            children: [
              _buildEmailInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildPasswordInput(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildForgotPasswordButton(),
              _buildSpacing(height: GeneralConstants.largeSpacing),
              _buildLoginButton(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return AuthenticationInputField(
      controller: _emailController,
      hint: AuthenticationLoginScreenConstants.emailHint,
      icon: Icons.email_outlined,
      type: AuthenticationInputType.email,
    );
  }

  Widget _buildPasswordInput() {
    return AuthenticationInputField(
      controller: _passwordController,
      hint: AuthenticationLoginScreenConstants.passwordHint,
      icon: Icons.lock_outline,
      type: AuthenticationInputType.password,
      obscureText: _isPasswordObscure,
      toggleVisibility: () =>
          setState(() => _isPasswordObscure = !_isPasswordObscure),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          AuthenticationLoginScreenConstants.forgotPasswordLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }
    return SizedBox(
      width: AuthenticationLoginScreenConstants.buttonWidth,
      height: AuthenticationLoginScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: GeneralConstants.secondaryColor,
          elevation: GeneralConstants.buttonElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GeneralConstants.mediumCircularRadius,
            ),
          ),
        ),
        child: Text(
          AuthenticationLoginScreenConstants.loginButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return TextButton(
      onPressed: _navigateToRegistration,
      child: Text(
        AuthenticationLoginScreenConstants.registerNavigationLabel,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.secondaryColor,
        ),
      ),
    );
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
