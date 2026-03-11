import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../service/authentication/authentication_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/home/screens/home_screen_constants.dart';
import '../../utils/core/utils.dart';
import '../../widgets/home/home_navigation_button.dart';
import '../authentication/authentication_login_screen.dart';
import '../group/group_create_edit_screen.dart';
import '../group/group_list_screen.dart';
import '../tutorial/tutorial_screen.dart';
import '../user/user_detail_screen.dart';
import '../user/user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthenticationService _authenticationService = AuthenticationService();

  void _handleLogout() async {
    await _authenticationService.logout();

    if (!mounted) {
      return;
    }

    _showSnackBar(
      const CustomSnackBar.success(
        message: HomeScreenConstants.logoutSuccessMessage,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AuthenticationLoginScreen(),
      ),
      (route) => false,
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
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
        HomeScreenConstants.appBarTitle,
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
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.account_circle_outlined,
            color: GeneralConstants.primaryColor,
            size: GeneralConstants.mediumIconSize,
          ),
          offset: const Offset(0, GeneralConstants.appBarHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GeneralConstants.mediumCircularRadius,
            ),
          ),
          onSelected: (value) {
            if (value == HomeScreenConstants.myProfileLabel) {
              _navigateTo(const UserDetailScreen());
            } else if (value == HomeScreenConstants.logoutLabel) {
              _handleLogout();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: HomeScreenConstants.myProfileLabel,
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: GeneralConstants.primaryColor,
                  ),
                  const SizedBox(width: GeneralConstants.smallSpacing),
                  Text(
                    HomeScreenConstants.myProfileLabel,
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: HomeScreenConstants.logoutLabel,
              child: Row(
                children: [
                  const Icon(
                    Icons.logout,
                    color: GeneralConstants.failureColor,
                  ),
                  const SizedBox(width: GeneralConstants.smallSpacing),
                  Text(
                    HomeScreenConstants.logoutLabel,
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.failureColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: GeneralConstants.smallMargin),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Utils.isMobile(context)
        ? _buildBodyMobile(context)
        : _buildBodyDesktop(context);
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
          child: _buildNavigationButtons(),
        ),
      ),
    );
  }

  Widget _buildBodyMobile(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        heightFactor: 0.75,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GeneralConstants.smallMargin),
          child: _buildNavigationButtons(),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      children: [
        HomeNavigationButton(
          label: HomeScreenConstants.searchGroupsLabel,
          icon: Icons.search,
          onTap: () => _navigateTo(const GroupListScreen()),
        ),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        HomeNavigationButton(
          label: HomeScreenConstants.searchUsersLabel,
          icon: Icons.people_outline,
          onTap: () => _navigateTo(const UserListScreen()),
        ),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        HomeNavigationButton(
          label: HomeScreenConstants.myGroupsLabel,
          icon: Icons.folder_outlined,
          onTap: () => _navigateTo(const GroupListScreen(myGroupsOnly: true)),
        ),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        HomeNavigationButton(
          label: HomeScreenConstants.createGroupLabel,
          icon: Icons.add_circle_outline,
          onTap: () => _navigateTo(const GroupCreateEditScreen()),
        ),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        HomeNavigationButton(
          label: HomeScreenConstants.tutorialLabel,
          icon: Icons.help_outline,
          onTap: () => _navigateTo(const TutorialScreen()),
        ),
      ],
    );
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
