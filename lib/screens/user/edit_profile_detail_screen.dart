import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/models/user/user_model.dart';

import '../../service/user/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  // Text Controllers
  late TextEditingController _usernameController;
  late TextEditingController _summaryController;
  late TextEditingController _profilePicController;

  // Local State for Toggles
  late bool _inAppNotifications;
  late bool _pushNotifications;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controllers with the user's current data
    _usernameController = TextEditingController(
      text: widget.currentUser.username,
    );
    _summaryController = TextEditingController(
      text: widget.currentUser.summary,
    );
    _profilePicController = TextEditingController(
      text: widget.currentUser.profilePic,
    );

    // Pre-fill settings
    _inAppNotifications = widget.currentUser.settings.getInAppNotifications;
    _pushNotifications = widget.currentUser.settings.getPushNotifications;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _summaryController.dispose();
    _profilePicController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validate the form before saving
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Reconstruct the settings object with the new toggle values
      final updatedSettings = UserSettings(
        getInAppNotifications: _inAppNotifications,
        getPushNotifications: _pushNotifications,
      );

      // Call your existing service method
      await _userService.updateUser(
        username: _usernameController.text.trim(),
        summary: _summaryController.text.trim(),
        profilePic: _profilePicController.text.trim(),
        settings: updatedSettings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to the profile detail screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blue),
              onPressed: _saveProfile,
              tooltip: 'Save Profile',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Basic Information'),
            _buildTextFieldCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username cannot be empty';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const Divider(height: 1),
                  _buildTextField(
                    controller: _summaryController,
                    label: 'Bio / Summary',
                    icon: Icons.info_outline,
                    maxLines: 3,
                  ),
                  const Divider(height: 1),
                  _buildTextField(
                    controller: _profilePicController,
                    label: 'Profile Picture URL',
                    icon: Icons.image_outlined,
                    hintText: 'https://example.com/image.jpg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Notification Preferences'),
            _buildToggleCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'In-App Notifications',
                      style: GoogleFonts.lexend(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Receive alerts while using the app',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    value: _inAppNotifications,
                    activeColor: Colors.blue,
                    onChanged: (bool value) {
                      setState(() {
                        _inAppNotifications = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.lexend(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Receive alerts outside the app',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    value: _pushNotifications,
                    activeColor: Colors.blue,
                    onChanged: (bool value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildToggleCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.lexend(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lexend(color: Colors.grey),
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: validator,
      ),
    );
  }
}
