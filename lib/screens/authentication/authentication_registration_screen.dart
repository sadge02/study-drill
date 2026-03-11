import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../service/authentication/authentication_service.dart';
import '../../utils/constants/authentication/screens/authentication_registration_screen_constants.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/core/utils.dart';
import '../../utils/enums/authentication/authentication_input_type_enum.dart';
import '../../widgets/authentication/authentication_input_field.dart';
import '../home/home_screen.dart';
import 'authentication_login_screen.dart';

class AuthenticationRegistrationScreen extends StatefulWidget {
  const AuthenticationRegistrationScreen({super.key});

  @override
  State<AuthenticationRegistrationScreen> createState() =>
      _AuthenticationRegistrationScreenState();
}

class _AuthenticationRegistrationScreenState
    extends State<AuthenticationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _avatarLinkController = TextEditingController();

  final AuthenticationService _authenticationService = AuthenticationService();

  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isLoading = false;

  String get _profilePicUrl {
    if (_avatarLinkController.text.trim().isNotEmpty) {
      return _avatarLinkController.text.trim();
    }
    final String name = _userController.text.trim().isEmpty
        ? AuthenticationRegistrationScreenConstants.defaultAvatarName
        : _userController.text.trim();
    final String encodedName = Uri.encodeComponent(name);
    return '${AuthenticationRegistrationScreenConstants.avatarApiBaseUrl}'
        '?name=$encodedName'
        '&background=${AuthenticationRegistrationScreenConstants.avatarApiBackground}'
        '&color=${AuthenticationRegistrationScreenConstants.avatarApiForeground}'
        '&size=${AuthenticationRegistrationScreenConstants.avatarApiSize}';
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final String? result = await _authenticationService.registerUser(
      username: _userController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      profilePicUrl: _profilePicUrl.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: AuthenticationRegistrationScreenConstants
              .registrationSuccessMessage,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AuthenticationLoginScreen(),
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
    _userController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _avatarLinkController.dispose();
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
        AuthenticationRegistrationScreenConstants.appBarTitle,
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
              _buildProfilePicture(context),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildUsernameInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildEmailInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildProfilePicInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildPasswordInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildConfirmPasswordInput(),
              _buildSpacing(height: GeneralConstants.largeSpacing),
              _buildRegisterButton(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildLoginNavigation(),
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
              _buildProfilePicture(context),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildUsernameInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildEmailInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildProfilePicInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildPasswordInput(),
              _buildSpacing(height: GeneralConstants.mediumSpacing),
              _buildConfirmPasswordInput(),
              _buildSpacing(height: GeneralConstants.largeSpacing),
              _buildRegisterButton(),
              _buildSpacing(height: GeneralConstants.smallSpacing),
              _buildLoginNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    final double backgroundRadius = Utils.isMobile(context)
        ? AuthenticationRegistrationScreenConstants
              .profilePicBackgroundRadiusMobile
        : AuthenticationRegistrationScreenConstants
              .profilePicBackgroundRadiusDesktop;
    final double innerRadius = Utils.isMobile(context)
        ? AuthenticationRegistrationScreenConstants.profilePicRadiusMobile
        : AuthenticationRegistrationScreenConstants.profilePicRadiusDesktop;

    return CircleAvatar(
      radius: backgroundRadius,
      backgroundColor: GeneralConstants.tertiaryColor,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: GeneralConstants.tertiaryColor,
        backgroundImage: NetworkImage(_profilePicUrl),
      ),
    );
  }

  Widget _buildUsernameInput() {
    return AuthenticationInputField(
      controller: _userController,
      hint: AuthenticationRegistrationScreenConstants.usernameHint,
      icon: Icons.person_outline,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEmailInput() {
    return AuthenticationInputField(
      controller: _emailController,
      hint: AuthenticationRegistrationScreenConstants.emailHint,
      icon: Icons.email_outlined,
      type: AuthenticationInputType.email,
    );
  }

  Widget _buildProfilePicInput() {
    return AuthenticationInputField(
      controller: _avatarLinkController,
      hint: AuthenticationRegistrationScreenConstants.profilePicHint,
      icon: Icons.link,
      type: AuthenticationInputType.profilePic,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPasswordInput() {
    return AuthenticationInputField(
      controller: _passwordController,
      hint: AuthenticationRegistrationScreenConstants.passwordHint,
      icon: Icons.lock_outline,
      type: AuthenticationInputType.password,
      obscureText: _isPasswordObscure,
      toggleVisibility: () =>
          setState(() => _isPasswordObscure = !_isPasswordObscure),
    );
  }

  Widget _buildConfirmPasswordInput() {
    return AuthenticationInputField(
      controller: _confirmPasswordController,
      hint: AuthenticationRegistrationScreenConstants.confirmPasswordHint,
      icon: Icons.check_circle_outline,
      type: AuthenticationInputType.confirmPassword,
      compareController: _passwordController,
      obscureText: _isConfirmPasswordObscure,
      toggleVisibility: () => setState(
        () => _isConfirmPasswordObscure = !_isConfirmPasswordObscure,
      ),
    );
  }

  Widget _buildRegisterButton() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }

    return SizedBox(
      width: AuthenticationRegistrationScreenConstants.buttonWidth,
      height: AuthenticationRegistrationScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _handleRegister,
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
          AuthenticationRegistrationScreenConstants.registerButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginNavigation() {
    return TextButton(
      onPressed: _navigateToLogin,
      child: Text(
        AuthenticationRegistrationScreenConstants.loginNavigationLabel,
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
