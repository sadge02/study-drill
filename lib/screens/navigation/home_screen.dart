import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:study_drill/service/authentication/authentication_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/utils/utils.dart';

import '../../models/user/user_model.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/navigation/home_screen/home_screen_constants.dart';
import '../../widgets/navigation/dashboard_button.dart';
import '../../widgets/navigation/dashboard_card.dart';
import '../authentication/login_screen.dart';
import '../information/information_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final UserService _userService = UserService();
  final AuthenticationService _authenticationService = AuthenticationService();

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
          GeneralConstants.appName,
          style: GoogleFonts.lexend(
            fontSize: Utils.isMobile(context)
                ? GeneralConstants.mediumTitleSize
                : GeneralConstants.largeTitleSize,
            fontWeight: FontWeight.w200,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userService.currentUserStream,
        builder: (context, snapshot) {
          final username = snapshot.data?.username ?? 'User';
          return SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: Utils.isMobile(context)
                    ? Utils.getWidth(context) *
                          GeneralConstants.widthRatioMobile
                    : Utils.getWidth(context) *
                          GeneralConstants.widthRatioDesktop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: GeneralConstants.largeSpacing),

                    /// WELCOME MESSAGE TITLE
                    Text(
                          'Welcome $username!',
                          maxLines:
                              HomeScreenConstants.welcomeMessageTitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.largeFontSize,
                            fontWeight: FontWeight.w600,
                            color: GeneralConstants.primaryColor,
                          ),
                        )
                        .animate()
                        .fade(duration: 500.ms)
                        .slideX(begin: -GeneralConstants.slideBegin),

                    const SizedBox(height: GeneralConstants.smallSpacing),

                    /// WELCOME MESSAGE SUBTITLE
                    Text(
                          'Ready to learn?',
                          style: GoogleFonts.lexend(
                            fontSize: GeneralConstants.mediumFontSize,
                            color: GeneralConstants.primaryColor,
                            fontWeight: FontWeight.w300,
                          ),
                        )
                        .animate()
                        .fade(delay: 200.ms)
                        .slideX(begin: -GeneralConstants.slideBegin),

                    const SizedBox(height: GeneralConstants.largeSpacing),

                    /// MY GROUPS BUTTON
                    DashboardCard(
                      title: 'My Groups',
                      subtitle: 'View and manage your study groups',
                      icon: Icons.star_rounded,
                      color: GeneralConstants.primaryColor,
                      textColor: Colors.white,
                      onTap: () => {
                        // TODO: navigate to my groups list screen
                      },
                    ).animate().fade(duration: 500.ms).scale(),

                    const SizedBox(height: GeneralConstants.mediumSpacing),

                    Row(
                          children: [
                            /// FIND USERS BUTTON
                            Expanded(
                              child: DashboardButton(
                                label: 'Find Users',
                                icon: Icons.person_search_rounded,
                                onTap: () => {
                                  // TODO: navigate to search users screen
                                },
                              ),
                            ),

                            const SizedBox(
                              width: GeneralConstants.mediumSpacing,
                            ),

                            /// FIND GROUPS BUTTON
                            Expanded(
                              child: DashboardButton(
                                label: 'Find Groups',
                                icon: Icons.groups_rounded,
                                onTap: () => {
                                  // TODO: navigate to search groups screen
                                },
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fade(delay: 200.ms)
                        .slideY(begin: GeneralConstants.slideBegin),

                    const SizedBox(height: GeneralConstants.mediumSpacing),

                    /// MY PROFILE BUTTON
                    DashboardButton(
                      label: 'My Profile',
                      icon: Icons.account_circle_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: GeneralConstants.mediumSpacing),

                    Row(
                          children: [
                            /// INFORMATION BUTTON
                            Expanded(
                              child:
                                  DashboardButton(
                                        label: 'Information',
                                        icon: Icons.info_outline_rounded,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (context) =>
                                                  const InformationScreen(),
                                            ),
                                          );
                                        },
                                      )
                                      .animate()
                                      .fade(delay: 400.ms)
                                      .slideY(
                                        begin: GeneralConstants.slideBegin,
                                      ),
                            ),

                            const SizedBox(
                              width: GeneralConstants.mediumSpacing,
                            ),

                            /// LOG OUT BUTTON
                            Expanded(
                              child: DashboardButton(
                                label: 'Log Out',
                                icon: Icons.logout_rounded,
                                onTap: () async {
                                  await _authenticationService.logout();
                                  if (context.mounted) {
                                    Navigator.of(
                                      context,
                                    ).pushAndRemoveUntil<void>(
                                      PageTransition<void>(
                                        type: PageTransitionType.fade,
                                        child: const LoginScreen(),
                                        duration: const Duration(
                                          milliseconds: GeneralConstants
                                              .transitionDuration,
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fade(delay: 600.ms)
                        .slideY(begin: GeneralConstants.slideBegin),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
