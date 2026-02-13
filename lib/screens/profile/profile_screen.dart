import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../service/user/user_service.dart';
import '../../utils/constants/profile/profile_screen_constants.dart';
import '../../utils/utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return DefaultTabController(
      length: ProfileScreenConstants.tabNumber,
      child: Scaffold(
        backgroundColor: GeneralConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: GeneralConstants.backgroundColor,
          elevation: GeneralConstants.appbarElevation,
          toolbarHeight: GeneralConstants.appbarHeight,
          centerTitle: true,
          title: Text(
            ProfileScreenConstants.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: Utils.isMobile(context)
                  ? GeneralConstants.mediumTitleSize
                  : GeneralConstants.largeTitleSize,
              fontWeight: FontWeight.w200,
              color: GeneralConstants.primaryColor,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: GeneralConstants.primaryColor,
                size: GeneralConstants.mediumIconSize,
              ),
              onPressed: () {
                // TODO: edit my profile
              },
            ),
          ],
        ),
        body: StreamBuilder<UserModel?>(
          stream: userService.currentUserStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;

            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            final privacy = user.privacySettings;

            final bool showEmail = privacy?.email == UserVisibility.public;
            final bool showGroups = privacy?.groups == UserVisibility.public;
            final bool showStats = privacy?.statistics == UserVisibility.public;

            return Column(
              children: [
                const SizedBox(height: GeneralConstants.mediumSpacing),

                /// PROFILE PICTURE
                CircleAvatar(
                  radius: Utils.isMobile(context)
                      ? ProfileScreenConstants.profilePictureRadiusMobile
                      : ProfileScreenConstants.profilePictureRadiusDesktop,
                  backgroundColor: GeneralConstants.primaryColor.withValues(
                    alpha: ProfileScreenConstants.profilePictureOpacity,
                  ),
                  backgroundImage: user.profilePic.isNotEmpty
                      ? NetworkImage(user.profilePic)
                      : null,
                  child: user.profilePic.isEmpty
                      ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.largeFontSize,
                      color: GeneralConstants.primaryColor,
                    ),
                  )
                      : null,
                ).animate().scale(),

                const SizedBox(height: GeneralConstants.mediumSpacing),

                /// USERNAME
                Text(
                  user.username,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.largeFontSize,
                    fontWeight: FontWeight.bold,
                    color: GeneralConstants.primaryColor,
                  ),
                ).animate().fade().slideY(begin: GeneralConstants.slideBegin),

                /// CREATED AT
                Text(
                  'Member since ${DateFormat('MMMM yyyy').format(user.createdAt)}',
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    color: GeneralConstants.primaryColor.withValues(alpha: ProfileScreenConstants.dateOpacity),
                    fontWeight: FontWeight.w300,
                  ),
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: GeneralConstants.smallSpacing),

                /// EMAIL
                if (showEmail)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: user.email));
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.success(message: 'Email copied to clipboard'),
                        snackBarPosition: SnackBarPosition.bottom,
                      );
                    },
                    borderRadius: BorderRadius.circular(GeneralConstants.smallCircularRadius),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: GeneralConstants.smallPadding, vertical: GeneralConstants.smallSmallPadding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: GeneralConstants.smallSmallIconSize, color: GeneralConstants.primaryColor.withValues(alpha: GeneralConstants.mediumOpacity)),

                          const SizedBox(width: GeneralConstants.smallSmallSpacing),

                          Text(
                            user.email,
                            style: GoogleFonts.lexend(
                              fontSize: GeneralConstants.smallFontSize,
                              color: GeneralConstants.primaryColor.withValues(alpha: GeneralConstants.mediumOpacity),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 200.ms),

                /// SUMMARY
                if (user.summary.isNotEmpty) ...[
                  const SizedBox(height: GeneralConstants.smallSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GeneralConstants.largeLargePadding),
                    child: Text(
                      user.summary,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: GeneralConstants.smallFontSize,
                        color: GeneralConstants.primaryColor.withValues(alpha: GeneralConstants.largeOpacity),
                      ),
                    ),
                  ).animate().fade().slideY(begin: GeneralConstants.slideBegin),
                ],

                const SizedBox(height: GeneralConstants.mediumSpacing),

                /// TABS
                TabBar(
                  labelColor: GeneralConstants.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: GeneralConstants.primaryColor,
                  labelStyle: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Groups'),
                    Tab(text: 'Tests'),
                    Tab(text: 'Statistics'),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Groups
                      showGroups
                          ? _buildMockList(
                        icon: Icons.group_outlined,
                        text: 'No active groups yet',
                      )
                          : _buildPrivatePlaceholder('Groups are private'),

                      // Tab 2: Stats
                      showStats
                          ? _buildMockList(
                        icon: Icons.bar_chart_rounded,
                        text: 'No test history available',
                      )
                          : _buildPrivatePlaceholder('Statistics are private'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMockList({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(text, style: GoogleFonts.lexend(color: Colors.grey[500])),
        ],
      ),
    ).animate().fade(duration: 600.ms);
  }

  Widget _buildPrivatePlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.lexend(
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fade();
  }
}