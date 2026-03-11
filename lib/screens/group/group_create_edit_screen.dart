import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/group/group_model.dart';
import '../../service/group/group_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/group/screens/group_create_edit_screen_constants.dart';
import '../../utils/core/utils.dart';

// Screens for creating and editing groups
class GroupCreateEditScreen extends StatefulWidget {
  const GroupCreateEditScreen({super.key, this.group});

  final GroupModel? group;

  @override
  State<GroupCreateEditScreen> createState() => _GroupCreateEditScreenState();
}

class _GroupCreateEditScreenState extends State<GroupCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupService _groupService = GroupService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _profilePicController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _tags = [];
  GroupVisibility _visibility = GroupVisibility.public;
  bool _autoAddAsEditor = true;
  bool _requiresJoinApproval = false;
  bool _isLoading = false;

  bool get _isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.group!.title;
      _descriptionController.text = widget.group!.description;
      _profilePicController.text = widget.group!.profilePic;
      _tags.addAll(widget.group!.tags);
      _visibility = widget.group!.visibility;
      _autoAddAsEditor = widget.group!.settings.autoAddAsEditor;
      _requiresJoinApproval = widget.group!.settings.requiresJoinApproval;
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    String? result;

    if (_isEditing) {
      final updated = widget.group!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        profilePic: _profilePicController.text.trim(),
        tags: List<String>.from(_tags),
        visibility: _visibility,
        settings: GroupSettings(
          autoAddAsEditor: _autoAddAsEditor,
          requiresJoinApproval: _requiresJoinApproval,
        ),
        updatedAt: now,
      );
      result = await _groupService.updateGroup(updated, updatedBy: userId);
    } else {
      final newGroup = GroupModel(
        id: FirebaseFirestore.instance.collection('groups').doc().id,
        authorId: userId,
        createdAt: now,
        updatedAt: now,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        profilePic: _profilePicController.text.trim(),
        visibility: _visibility,
        settings: GroupSettings(
          autoAddAsEditor: _autoAddAsEditor,
          requiresJoinApproval: _requiresJoinApproval,
        ),
        tags: List<String>.from(_tags),
        userIds: [userId],
        adminIds: [userId],
        creatorIds: [userId],
      );
      result = await _groupService.createGroup(newGroup);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnackBar(
        CustomSnackBar.success(
          message: _isEditing
              ? GroupCreateEditScreenConstants.updateSuccessMessage
              : GroupCreateEditScreenConstants.createSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _onTagSubmitted(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    if (_tags.length >= GroupCreateEditScreenConstants.maxTags) {
      _showSnackBar(
        const CustomSnackBar.info(
          message: GroupCreateEditScreenConstants.maxTagsError,
        ),
      );
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _onTagRemoved(String tag) {
    setState(() => _tags.remove(tag));
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
    _titleController.dispose();
    _descriptionController.dispose();
    _profilePicController.dispose();
    _tagController.dispose();
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
        _isEditing
            ? GroupCreateEditScreenConstants.editAppBarTitle
            : GroupCreateEditScreenConstants.createAppBarTitle,
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
          child: _buildFormContent(),
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
          child: _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(GroupCreateEditScreenConstants.basicInfoSection),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildTitleInput(),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildDescriptionInput(),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildProfilePicInput(),
        _buildSpacing(height: GroupCreateEditScreenConstants.sectionSpacing),
        _buildSectionHeader(GroupCreateEditScreenConstants.tagsSection),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildTagInput(),
        if (_tags.isNotEmpty) ...[
          _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
          _buildActiveTagChips(),
        ],
        _buildSpacing(height: GroupCreateEditScreenConstants.sectionSpacing),
        _buildSectionHeader(GroupCreateEditScreenConstants.visibilitySection),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildVisibilityOptions(),
        _buildSpacing(height: GroupCreateEditScreenConstants.sectionSpacing),
        _buildSectionHeader(GroupCreateEditScreenConstants.settingsSection),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildSettingsToggles(),
        _buildSpacing(height: GeneralConstants.largeSpacing),
        Center(child: _buildSubmitButton()),
        _buildSpacing(height: GeneralConstants.largeSpacing),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: GroupCreateEditScreenConstants.sectionHeaderFontSize,
        fontWeight: FontWeight.w500,
        color: GeneralConstants.primaryColor,
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleController,
      validator: _validateTitle,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: GroupCreateEditScreenConstants.titleHint,
        icon: Icons.title,
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      validator: _validateDescription,
      maxLines: GroupCreateEditScreenConstants.descriptionMaxLines.toInt(),
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: GroupCreateEditScreenConstants.descriptionHint,
        icon: Icons.description_outlined,
      ),
    );
  }

  Widget _buildProfilePicInput() {
    return TextFormField(
      controller: _profilePicController,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: GroupCreateEditScreenConstants.profilePicHint,
        icon: Icons.image_outlined,
      ),
    );
  }

  Widget _buildTagInput() {
    return TextField(
      controller: _tagController,
      onSubmitted: _onTagSubmitted,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: _inputDecoration(
        hint: GroupCreateEditScreenConstants.tagInputHint,
        icon: Icons.tag,
      ),
    );
  }

  Widget _buildActiveTagChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: GroupCreateEditScreenConstants.tagChipSpacing,
        runSpacing: GroupCreateEditScreenConstants.tagChipSpacing,
        children: _tags.map((tag) => _buildRemovableTagChip(tag)).toList(),
      ),
    );
  }

  Widget _buildRemovableTagChip(String tag) {
    return Chip(
      label: Text(
        tag,
        style: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w400,
          color: GeneralConstants.secondaryColor,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: GeneralConstants.smallSmallIconSize,
      ),
      deleteIconColor: GeneralConstants.secondaryColor,
      onDeleted: () => _onTagRemoved(tag),
      backgroundColor: GeneralConstants.tertiaryColor.withValues(alpha: 0.15),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
    );
  }

  Widget _buildVisibilityOptions() {
    return Column(
      children: [
        _buildVisibilityOption(
          visibility: GroupVisibility.public,
          icon: Icons.public,
          label: GroupCreateEditScreenConstants.visibilityPublicLabel,
          description:
              GroupCreateEditScreenConstants.visibilityPublicDescription,
        ),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildVisibilityOption(
          visibility: GroupVisibility.friends,
          icon: Icons.people_outline,
          label: GroupCreateEditScreenConstants.visibilityFriendsLabel,
          description:
              GroupCreateEditScreenConstants.visibilityFriendsDescription,
        ),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildVisibilityOption(
          visibility: GroupVisibility.private,
          icon: Icons.lock_outline,
          label: GroupCreateEditScreenConstants.visibilityPrivateLabel,
          description:
              GroupCreateEditScreenConstants.visibilityPrivateDescription,
        ),
      ],
    );
  }

  Widget _buildVisibilityOption({
    required GroupVisibility visibility,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final bool isSelected = _visibility == visibility;

    return GestureDetector(
      onTap: () => setState(() => _visibility = visibility),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: GeneralConstants.transitionDurationMs,
        ),
        padding: const EdgeInsets.all(GeneralConstants.smallPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? GeneralConstants.secondaryColor.withValues(alpha: 0.08)
              : GeneralConstants.backgroundColor,
          borderRadius: BorderRadius.circular(
            GroupCreateEditScreenConstants.visibilityOptionRadius,
          ),
          border: Border.all(
            color: isSelected
                ? GeneralConstants.secondaryColor
                : GeneralConstants.primaryColor.withValues(
                    alpha: GroupCreateEditScreenConstants
                        .visibilityOptionBorderOpacity,
                  ),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? GeneralConstants.secondaryColor
                  : GeneralConstants.primaryColor,
              size: GeneralConstants.smallIconSize,
            ),
            const SizedBox(width: GeneralConstants.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? GeneralConstants.secondaryColor
                          : GeneralConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: GeneralConstants.tinySpacing),
                  Text(
                    description,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize - 2,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.smallOpacity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: GeneralConstants.secondaryColor,
                size: GeneralConstants.smallIconSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggles() {
    return Column(
      children: [
        _buildSettingsTile(
          icon: Icons.edit_outlined,
          label: GroupCreateEditScreenConstants.autoAddEditorLabel,
          description: GroupCreateEditScreenConstants.autoAddEditorDescription,
          value: _autoAddAsEditor,
          onChanged: (val) => setState(() => _autoAddAsEditor = val),
        ),
        _buildSpacing(height: GroupCreateEditScreenConstants.fieldSpacing),
        _buildSettingsTile(
          icon: Icons.verified_user_outlined,
          label: GroupCreateEditScreenConstants.requireApprovalLabel,
          description:
              GroupCreateEditScreenConstants.requireApprovalDescription,
          value: _requiresJoinApproval,
          onChanged: (val) => setState(() => _requiresJoinApproval = val),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          GroupCreateEditScreenConstants.settingsTileRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: GroupCreateEditScreenConstants.visibilityOptionBorderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: GeneralConstants.primaryColor,
            size: GeneralConstants.smallIconSize,
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: GeneralConstants.tinySpacing),
                Text(
                  description,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize - 2,
                    fontWeight: FontWeight.w300,
                    color: GeneralConstants.primaryColor.withValues(
                      alpha: GeneralConstants.smallOpacity,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: GeneralConstants.secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (_isLoading) {
      return const CircularProgressIndicator(
        color: GeneralConstants.primaryColor,
      );
    }

    return SizedBox(
      width: GroupCreateEditScreenConstants.buttonWidth,
      height: GroupCreateEditScreenConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _handleSubmit,
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
          _isEditing
              ? GroupCreateEditScreenConstants.saveButtonLabel
              : GroupCreateEditScreenConstants.createButtonLabel,
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

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return GroupCreateEditScreenConstants.titleEmptyError;
    }
    if (value.trim().length < GroupCreateEditScreenConstants.titleMinLength) {
      return GroupCreateEditScreenConstants.titleTooShortError;
    }
    if (value.trim().length > GroupCreateEditScreenConstants.titleMaxLength) {
      return GroupCreateEditScreenConstants.titleTooLongError;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null &&
        value.trim().length >
            GroupCreateEditScreenConstants.descriptionMaxLength) {
      return GroupCreateEditScreenConstants.descriptionTooLongError;
    }
    return null;
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
