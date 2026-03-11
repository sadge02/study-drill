import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/user/user_model.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/user/screens/user_edit_screen_constants.dart';
import '../../utils/core/utils.dart';

// Screen for editing the user profile
class UserEditScreen extends StatefulWidget {
  const UserEditScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late final TextEditingController _usernameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _profilePicController;

  bool _isLoading = false;

  String get _profilePicUrl {
    if (_profilePicController.text.trim().isNotEmpty) {
      return _profilePicController.text.trim();
    }
    final name = _usernameController.text.trim().isEmpty
        ? 'User'
        : _usernameController.text.trim();
    final encodedName = Uri.encodeComponent(name);
    return '${UserEditScreenConstants.avatarApiBaseUrl}'
        '?name=$encodedName'
        '&background=${UserEditScreenConstants.avatarApiBackground}'
        '&color=${UserEditScreenConstants.avatarApiForeground}'
        '&size=${UserEditScreenConstants.avatarApiSize}';
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _descriptionController = TextEditingController(
      text: widget.user.description,
    );
    _profilePicController = TextEditingController(text: widget.user.profilePic);
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updated = widget.user.copyWith(
      username: _usernameController.text.trim(),
      description: _descriptionController.text.trim(),
      profilePic: _profilePicUrl,
      updatedAt: DateTime.now(),
    );

    final result = await _userService.updateUser(updated);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: UserEditScreenConstants.updateSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
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
    _usernameController.dispose();
    _descriptionController.dispose();
    _profilePicController.dispose();
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
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: GeneralConstants.primaryColor,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        UserEditScreenConstants.appBarTitle,
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
    return Form(
      key: _formKey,
      child: Utils.isMobile(context)
          ? _buildBodyMobile(context)
          : _buildBodyDesktop(context),
    );
  }

  Widget _buildBodyDesktop(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
            vertical: GeneralConstants.smallMargin,
          ),
          child: _buildFormContent(context),
        ),
      ),
    );
  }

  Widget _buildBodyMobile(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.90,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GeneralConstants.smallMargin),
          child: _buildFormContent(context),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildProfilePicPreview(context)),
        _buildSpacing(height: UserEditScreenConstants.sectionSpacing),
        _buildSectionHeader(UserEditScreenConstants.profileSection),
        _buildSpacing(height: UserEditScreenConstants.fieldSpacing),
        _buildUsernameInput(),
        _buildSpacing(height: UserEditScreenConstants.fieldSpacing),
        _buildDescriptionInput(),
        _buildSpacing(height: UserEditScreenConstants.sectionSpacing),
        _buildSectionHeader(UserEditScreenConstants.accountSection),
        _buildSpacing(height: UserEditScreenConstants.fieldSpacing),
        _buildProfilePicInput(),
        _buildSpacing(height: UserEditScreenConstants.fieldSpacing),
        _buildEmailDisplay(),
        _buildSpacing(height: GeneralConstants.largeSpacing),
        Center(child: _buildSaveButton()),
        _buildSpacing(height: GeneralConstants.largeSpacing),
      ],
    );
  }

  Widget _buildProfilePicPreview(BuildContext context) {
    final isMobile = Utils.isMobile(context);
    final bgRadius = isMobile
        ? UserEditScreenConstants.profilePicBackgroundRadiusMobile
        : UserEditScreenConstants.profilePicBackgroundRadiusDesktop;
    final innerRadius = isMobile
        ? UserEditScreenConstants.profilePicRadiusMobile
        : UserEditScreenConstants.profilePicRadiusDesktop;

    return CircleAvatar(
      radius: bgRadius,
      backgroundColor: GeneralConstants.tertiaryColor,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: GeneralConstants.tertiaryColor,
        backgroundImage: NetworkImage(_profilePicUrl),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: UserEditScreenConstants.sectionHeaderFontSize,
        fontWeight: FontWeight.w500,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  Widget _buildUsernameInput() {
    return TextFormField(
      controller: _usernameController,
      validator: _validateUsername,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: UserEditScreenConstants.usernameHint,
        icon: Icons.person_outline,
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      validator: _validateDescription,
      maxLines: UserEditScreenConstants.descriptionMaxLines.toInt(),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: UserEditScreenConstants.descriptionHint,
        icon: Icons.info_outline,
      ),
    );
  }

  Widget _buildProfilePicInput() {
    return TextFormField(
      controller: _profilePicController,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: UserEditScreenConstants.profilePicHint,
        icon: Icons.image_outlined,
      ),
    );
  }

  Widget _buildEmailDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.mediumPadding,
        vertical: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.tertiaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: GeneralConstants.primaryColor.withValues(
              alpha: GeneralConstants.mediumOpacity,
            ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Text(
              widget.user.email,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.mediumOpacity,
                ),
              ),
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: GeneralConstants.smallSmallIconSize,
            color: GeneralConstants.primaryColor.withValues(
              alpha: GeneralConstants.largeOpacity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }

    return SizedBox(
      width: UserEditScreenConstants.buttonWidth,
      height: UserEditScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _handleSave,
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
          UserEditScreenConstants.saveButtonLabel,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumFontSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.backgroundColor,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.mediumOpacity,
        ),
      ),
      prefixIcon: Icon(icon, color: GeneralConstants.primaryColor),
      filled: true,
      fillColor: GeneralConstants.tertiaryColor.withValues(alpha: 0.1),
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
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UserEditScreenConstants.usernameEmptyError;
    }
    if (value.trim().length < UserEditScreenConstants.usernameMinLength) {
      return UserEditScreenConstants.usernameTooShortError;
    }
    if (value.trim().length > UserEditScreenConstants.usernameMaxLength) {
      return UserEditScreenConstants.usernameTooLongError;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null &&
        value.trim().length > UserEditScreenConstants.descriptionMaxLength) {
      return UserEditScreenConstants.descriptionTooLongError;
    }
    return null;
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
