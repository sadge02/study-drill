import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user/user_model.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/user/screens/user_list_screen_constants.dart';
import '../../utils/core/utils.dart';
import '../../utils/enums/user/user_sort_option_enum.dart';
import '../../widgets/user/user_card.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  final _nameController = TextEditingController();

  UserSortOption _sortOption = UserSortOption.newest;

  String _currentUserId = '';

  late Stream<List<UserModel>> _userStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _rebuildStream();
  }

  void _rebuildStream() {
    _userStream = _userService.streamFilteredUsers(
      usernameStartsWith: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      sortOption: _sortOption,
    );
  }

  void _onSearchChanged(String _) {
    setState(() => _rebuildStream());
  }

  void _onSortChanged(UserSortOption? option) {
    if (option == null) return;
    setState(() {
      _sortOption = option;
      _rebuildStream();
    });
  }

  void _navigateToDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => UserDetailScreen(userId: user.id),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        UserListScreenConstants.appBarTitle,
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
    return Utils.isMobile(context)
        ? _buildBodyMobile(context)
        : _buildBodyDesktop(context);
  }

  Widget _buildBodyDesktop(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.50,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GeneralConstants.mediumMargin,
            vertical: GeneralConstants.smallMargin,
          ),
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildBodyMobile(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.90,
        child: Padding(
          padding: const EdgeInsets.all(GeneralConstants.smallMargin),
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildNameSearch(),
        _buildSpacing(height: UserListScreenConstants.filterBarSpacing),
        _buildSortDropdown(),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildNameSearch() {
    return TextField(
      controller: _nameController,
      onChanged: _onSearchChanged,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: UserListScreenConstants.nameSearchHint,
        hintStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: GeneralConstants.primaryColor,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GeneralConstants.mediumPadding,
          vertical: GeneralConstants.smallPadding,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.tertiaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          GeneralConstants.mediumCircularRadius,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserSortOption>(
          value: _sortOption,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: GeneralConstants.primaryColor,
          ),
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            color: GeneralConstants.primaryColor,
          ),
          items: UserSortOption.values
              .map(
                (option) => DropdownMenuItem<UserSortOption>(
                  value: option,
                  child: Text(
                    _sortLabel(option),
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      color: GeneralConstants.primaryColor,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _onSortChanged,
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<UserModel>>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        final users = allUsers.where((u) => u.id != _currentUserId).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              UserListScreenConstants.noUsersFoundMessage,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.mediumOpacity,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) =>
              _buildSpacing(height: UserListScreenConstants.filterBarSpacing),
          itemBuilder: (context, index) {
            return UserCard(
              user: users[index],
              onTap: () => _navigateToDetail(users[index]),
            );
          },
        );
      },
    );
  }

  String _sortLabel(UserSortOption option) {
    switch (option) {
      case UserSortOption.newest:
        return UserListScreenConstants.sortNewest;
      case UserSortOption.oldest:
        return UserListScreenConstants.sortOldest;
      case UserSortOption.alphabetical:
        return UserListScreenConstants.sortAlphabetical;
      case UserSortOption.mostGroups:
        return UserListScreenConstants.sortMostGroups;
      case UserSortOption.mostFriends:
        return UserListScreenConstants.sortMostFriends;
    }
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
