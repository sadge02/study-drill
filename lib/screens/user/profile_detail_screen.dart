import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:study_drill/models/user/user_model.dart';

import '../../service/user/user_service.dart';
import 'edit_profile_detail_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  // Pass a stream for another user, or leave null for the current logged-in user
  final Stream<UserModel?>? userStream;

  const ProfileDetailScreen({super.key, this.userStream});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late final Stream<UserModel?> _profileStream;

  @override
  void initState() {
    super.initState();
    // THE MAGIC: If parameter is null, fallback to the current user's stream
    _profileStream = widget.userStream ?? UserService().currentUserStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Profile Details',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Use the snapshot from the StreamBuilder to get the user
          StreamBuilder<UserModel?>(
            stream: _profileStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfileScreen(currentUser: snapshot.data!),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink(); // Hide button while loading/error
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          // 1. Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle Error State
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong loading the profile.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(color: Colors.red),
              ),
            );
          }

          // 3. Handle Null/Not Found State
          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Text(
                'User not found.',
                style: GoogleFonts.lexend(fontSize: 18),
              ),
            );
          }

          // 4. Handle Success State
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildHeaderSection(user),
              const SizedBox(height: 16),
              _buildDatesSection(user),
              const SizedBox(height: 16),
              _buildSocialAndGroupSection(user),
              const SizedBox(height: 16),
              _buildTestStatisticsSection(user),
              const SizedBox(height: 16),
              _buildPrivacySettingsSection(user),
              const SizedBox(height: 16),
              _buildAppNotificationsSection(user),
            ],
          );
        },
      ),
    );
  }

  // --- UI WIDGETS (Updated to take 'user' as a parameter) ---

  Widget _buildHeaderSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              user.profilePic.isNotEmpty
                  ? user.profilePic
                  : 'https://ui-avatars.com/api/?name=${user.username}&background=27374D&color=fff',
            ),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.usernameLowercase}',
            style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: GoogleFonts.lexend(fontSize: 14, color: Colors.blueGrey),
          ),
          const SizedBox(height: 16),
          if (user.summary.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text(
              user.summary,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[800],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatesSection(UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'Joined',
            value: dateFormat.format(user.createdAt),
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'Last Updated',
            value: dateFormat.format(user.updatedAt),
            icon: Icons.update,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAndGroupSection(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Social & Groups'),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: Text('Friends', style: GoogleFonts.lexend()),
            trailing: Text(
              '${user.friendIds.length}',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.group_work, color: Colors.purple),
            title: Text('Groups Joined', style: GoogleFonts.lexend()),
            trailing: Text(
              '${user.groupIds.length}',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.orange),
            title: Text('Pending Requests', style: GoogleFonts.lexend()),
            trailing: Text(
              '${user.pendingFriendRequestIds.length}',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.send, color: Colors.teal),
            title: Text('Sent Requests', style: GoogleFonts.lexend()),
            trailing: Text(
              '${user.sentFriendRequestIds.length}',
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStatisticsSection(UserModel user) {
    int totalRepetitions = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;

    user.statistics.userTests.forEach((key, result) {
      totalRepetitions += result.repetitions;
      totalCorrect += result.correct;
      totalIncorrect += result.incorrect;
    });

    final accuracy = totalRepetitions == 0
        ? 0.0
        : (totalCorrect / (totalCorrect + totalIncorrect)) * 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Test Statistics'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Tests Taken',
                  user.statistics.userTests.length.toString(),
                  Colors.blue,
                ),
                _buildStatColumn(
                  'Repetitions',
                  totalRepetitions.toString(),
                  Colors.orange,
                ),
                _buildStatColumn(
                  'Accuracy',
                  '${accuracy.toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsSection(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Privacy Settings'),
          _buildPrivacyTile(
            'Email Visibility',
            user.privacySettings.email.name,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyTile(
            'Statistics Visibility',
            user.privacySettings.statistics.name,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyTile(
            'Groups Visibility',
            user.privacySettings.groups.name,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildPrivacyTile(
            'Tests Visibility',
            user.privacySettings.tests.name,
          ),
        ],
      ),
    );
  }

  Widget _buildAppNotificationsSection(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Notifications'),
          SwitchListTile(
            title: Text(
              'In-App Notifications',
              style: GoogleFonts.lexend(fontSize: 14),
            ),
            value: user.settings.getInAppNotifications,
            onChanged: null,
            activeColor: Colors.blue,
          ),
          SwitchListTile(
            title: Text(
              'Push Notifications',
              style: GoogleFonts.lexend(fontSize: 14),
            ),
            value: user.settings.getPushNotifications,
            onChanged: null,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPrivacyTile(String title, String visibilityValue) {
    return ListTile(
      title: Text(title, style: GoogleFonts.lexend(fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: visibilityValue.toLowerCase() == 'public'
              ? Colors.green[50]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          visibilityValue.toUpperCase(),
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: visibilityValue.toLowerCase() == 'public'
                ? Colors.green[700]
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
