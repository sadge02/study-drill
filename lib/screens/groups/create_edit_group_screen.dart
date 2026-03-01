import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Adjust import paths according to your project structure
import '../../models/group/group_model.dart';
import '../../utils/constants/core/general_constants.dart';

class CreateEditGroupScreen extends StatefulWidget {
  final GroupModel? group; // If null, we are creating. If not, we are editing.

  const CreateEditGroupScreen({super.key, this.group});

  @override
  State<CreateEditGroupScreen> createState() => _CreateEditGroupScreenState();
}

class _CreateEditGroupScreenState extends State<CreateEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _summaryController;
  late TextEditingController _profilePicController;
  final TextEditingController _tagController = TextEditingController();

  late GroupVisibility _visibility;

  // Settings [cite: 19, 20, 21]
  late bool _autoAddAsEditor;
  late bool _notifyOnNewContent;
  late bool _requiresApproval;

  // Tags [cite: 22, 25]
  List<String> _tags = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing, or defaults if creating
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _summaryController = TextEditingController(
      text: widget.group?.summary ?? '',
    );
    _profilePicController = TextEditingController(
      text: widget.group?.profilePic ?? '',
    );

    _visibility = widget.group?.visibility ?? GroupVisibility.public;

    _autoAddAsEditor = widget.group?.settings.autoAddAsEditor ?? false;
    _notifyOnNewContent = widget.group?.settings.notifyOnNewContent ?? true;
    _requiresApproval = widget.group?.settings.requiresApproval ?? false;

    _tags = widget.group?.tags.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    _profilePicController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Build the Settings object [cite: 19, 21]
      final settings = GroupSettings(
        autoAddAsEditor: _autoAddAsEditor,
        notifyOnNewContent: _notifyOnNewContent,
        requiresApproval: _requiresApproval,
      );

      final groupRef = FirebaseFirestore.instance.collection('group');

      if (widget.group == null) {
        // CREATE LOGIC
        final docRef = groupRef.doc();
        final now = DateTime.now();

        final newGroup = GroupModel(
          id: docRef.id,
          name: _nameController.text.trim(),
          nameLowercase: _nameController.text.trim().toLowerCase(),
          summary: _summaryController.text.trim(),
          profilePic: _profilePicController.text.trim(),
          authorId: currentUser.uid,
          visibility: _visibility,
          settings: settings,
          tags: _tags,
          userIds: [currentUser.uid], // Author is the first user
          adminIds: [currentUser.uid], // Author is admin
          createdAt: now,
          updatedAt: now,
        );

        await docRef.set(newGroup.toJson());
      } else {
        // EDIT LOGIC [cite: 30]
        final updatedGroup = widget.group!.copyWith(
          name: _nameController.text.trim(),
          summary: _summaryController.text.trim(),
          profilePic: _profilePicController.text.trim(),
          visibility: _visibility,
          settings: settings,
          tags: _tags,
          updatedAt: DateTime.now(),
        );

        await groupRef.doc(updatedGroup.id).update(updatedGroup.toJson());
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: GeneralConstants.appBarElevation,
        iconTheme: const IconThemeData(color: GeneralConstants.primaryColor),
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit Group' : 'Create Group',
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.mediumTitleSize,
            fontWeight: FontWeight.w300,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: GeneralConstants.primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(
                GeneralConstants.mediumPadding ?? 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Group Name',
                      icon: Icons.group,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Group name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _summaryController,
                      label: 'Summary',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _profilePicController,
                      label: 'Profile Picture URL',
                      icon: Icons.image,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Tags'),
                    _buildTagManager(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Visibility & Settings'),
                    _buildVisibilityDropdown(),
                    const SizedBox(height: 8),
                    _buildSwitchListTile(
                      title: 'Auto-add members as editors',
                      subtitle: 'New members can immediately edit content',
                      value: _autoAddAsEditor,
                      onChanged: (val) =>
                          setState(() => _autoAddAsEditor = val),
                    ),
                    _buildSwitchListTile(
                      title: 'Notify on new content',
                      subtitle: 'Send alerts when tests/flashcards are added',
                      value: _notifyOnNewContent,
                      onChanged: (val) =>
                          setState(() => _notifyOnNewContent = val),
                    ),
                    _buildSwitchListTile(
                      title: 'Requires approval to join',
                      subtitle: 'Admins must approve requests to join',
                      value: _requiresApproval,
                      onChanged: (val) =>
                          setState(() => _requiresApproval = val),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GeneralConstants.secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              GeneralConstants.mediumCircularRadius ?? 12,
                            ),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Group',
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.mediumFontSize,
                            color: GeneralConstants.backgroundColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: GeneralConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lexend(color: Colors.grey),
        prefixIcon: Icon(icon, color: GeneralConstants.primaryColor),
        filled: true,
        fillColor: GeneralConstants.tertiaryColor ?? Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius ?? 12.0,
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTagManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _tagController,
                label: 'Add a tag (e.g. math, biology)',
                icon: Icons.tag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: GeneralConstants.secondaryColor,
                size: 36,
              ),
              onPressed: _addTag,
            ),
          ],
        ),
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: GoogleFonts.lexend(
                      color: GeneralConstants.backgroundColor,
                    ),
                  ),
                  backgroundColor: GeneralConstants.primaryColor,
                  deleteIconColor: GeneralConstants.backgroundColor,
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVisibilityDropdown() {
    return DropdownButtonFormField<GroupVisibility>(
      value: _visibility,
      dropdownColor: GeneralConstants.backgroundColor,
      style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
      decoration: InputDecoration(
        labelText: 'Visibility',
        labelStyle: GoogleFonts.lexend(color: Colors.grey),
        prefixIcon: const Icon(
          Icons.visibility,
          color: GeneralConstants.primaryColor,
        ),
        filled: true,
        fillColor: GeneralConstants.tertiaryColor ?? Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius ?? 12.0,
          ),
          borderSide: BorderSide.none,
        ),
      ),
      items: GroupVisibility.values.map((v) {
        return DropdownMenuItem(
          value: v,
          child: Text(
            v.name.toUpperCase(),
          ), // Will display PUBLIC or PRIVATE [cite: 19]
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _visibility = val);
      },
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 14,
          color: GeneralConstants.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[600]),
      ),
      value: value,
      activeColor: GeneralConstants.secondaryColor,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
