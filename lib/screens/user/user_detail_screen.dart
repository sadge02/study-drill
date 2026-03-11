import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/group/group_model.dart';
import '../../models/user/user_model.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/user/screens/user_detail_screen_constants.dart';
import '../../utils/core/utils.dart';
import '../group/group_detail_screen.dart';
import 'user_edit_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, this.userId});

  final String? userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  late TabController _tabController;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _targetUserId => widget.userId ?? _currentUserId;

  bool get _isOwnProfile => _targetUserId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: UserDetailScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAddFriend() async {
    final result = await _userService.sendFriendRequest(
      _currentUserId,
      _targetUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: UserDetailScreenConstants.friendRequestSentMessage,
        ),
      );
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _handleRemoveFriend() async {
    final result = await _userService.removeFriend(
      _currentUserId,
      _targetUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: UserDetailScreenConstants.friendRemovedMessage,
        ),
      );
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
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userService.streamUserById(_targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: const Center(
              child: CircularProgressIndicator(
                color: GeneralConstants.primaryColor,
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: Center(
              child: Text(
                'User not found.',
                style: GoogleFonts.lexend(
                  color: GeneralConstants.primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: GeneralConstants.backgroundColor,
          appBar: _buildAppBar(user),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(user),
                    _buildGroupsTab(user),
                    _buildFriendsTab(user),
                    _buildStatsTab(user),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel? user) {
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
        user?.username ?? UserDetailScreenConstants.appBarTitle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lexend(
          fontSize: Utils.isMobile(context)
              ? GeneralConstants.smallTitleSize
              : GeneralConstants.mediumTitleSize,
          fontWeight: FontWeight.w200,
          color: GeneralConstants.primaryColor,
        ),
      ),
      actions: user != null
          ? _isOwnProfile
                ? _buildOwnProfileActions(user)
                : _buildAppBarActions(user)
          : null,
    );
  }

  List<Widget> _buildOwnProfileActions(UserModel user) {
    return [
      IconButton(
        icon: const Icon(
          Icons.edit_outlined,
          color: GeneralConstants.primaryColor,
        ),
        tooltip: UserDetailScreenConstants.editProfileLabel,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => UserEditScreen(user: user)),
        ),
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  List<Widget> _buildAppBarActions(UserModel user) {
    return [
      StreamBuilder<UserModel?>(
        stream: _userService.streamUserById(_currentUserId),
        builder: (context, snapshot) {
          final currentUser = snapshot.data;
          if (currentUser == null) return const SizedBox.shrink();

          final isFriend = currentUser.friendIds.contains(_targetUserId);
          final hasPendingRequest = currentUser.requests.any(
            (r) =>
                r.requestType == RequestType.friendInvite &&
                r.toUserId == _targetUserId &&
                r.status == RequestStatus.pending,
          );

          if (isFriend) {
            return IconButton(
              icon: const Icon(
                Icons.person_remove_outlined,
                color: GeneralConstants.failureColor,
              ),
              tooltip: UserDetailScreenConstants.removeFriendLabel,
              onPressed: _handleRemoveFriend,
            );
          }

          if (hasPendingRequest) {
            return Padding(
              padding: const EdgeInsets.only(
                right: GeneralConstants.smallMargin,
              ),
              child: Center(
                child: Text(
                  UserDetailScreenConstants.friendRequestSentLabel,
                  style: GoogleFonts.lexend(
                    fontSize: UserDetailScreenConstants.badgeFontSize,
                    fontWeight: FontWeight.w400,
                    color: GeneralConstants.primaryColor.withValues(
                      alpha: GeneralConstants.mediumOpacity,
                    ),
                  ),
                ),
              ),
            );
          }

          return IconButton(
            icon: const Icon(
              Icons.person_add_outlined,
              color: GeneralConstants.secondaryColor,
            ),
            tooltip: UserDetailScreenConstants.addFriendLabel,
            onPressed: _handleAddFriend,
          );
        },
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: GeneralConstants.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: GeneralConstants.secondaryColor,
        unselectedLabelColor: GeneralConstants.primaryColor.withValues(
          alpha: GeneralConstants.mediumOpacity,
        ),
        indicatorColor: GeneralConstants.secondaryColor,
        labelStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          fontWeight: FontWeight.w300,
        ),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: UserDetailScreenConstants.overviewTab),
          Tab(text: UserDetailScreenConstants.groupsTab),
          Tab(text: UserDetailScreenConstants.friendsTab),
          Tab(text: UserDetailScreenConstants.statsTab),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(UserModel user) {
    final isMobile = Utils.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      child: Column(
        children: [
          _buildProfileHeader(user, isMobile),
          _buildSpacing(height: UserDetailScreenConstants.sectionSpacing),
          _buildStatRow(user),
          _buildSpacing(height: UserDetailScreenConstants.sectionSpacing),
          _buildInfoSection(
            UserDetailScreenConstants.descriptionLabel,
            Icons.info_outline,
            child: Text(
              user.description.isEmpty
                  ? UserDetailScreenConstants.noDescriptionLabel
                  : user.description,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: user.description.isEmpty
                    ? GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      )
                    : GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            UserDetailScreenConstants.emailLabel,
            Icons.email_outlined,
            child: Text(
              user.email,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
          _buildInfoSection(
            UserDetailScreenConstants.joinedLabel,
            Icons.calendar_today_outlined,
            child: Text(
              _formatDate(user.createdAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: UserDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isMobile) {
    final radius = isMobile
        ? UserDetailScreenConstants.profilePicRadiusMobile
        : UserDetailScreenConstants.profilePicRadiusDesktop;

    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: GeneralConstants.tertiaryColor,
          backgroundImage: user.profilePic.isNotEmpty
              ? NetworkImage(user.profilePic)
              : null,
          child: user.profilePic.isEmpty
              ? Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.lexend(
                    fontSize: radius * 0.8,
                    color: GeneralConstants.backgroundColor,
                    fontWeight: FontWeight.w300,
                  ),
                )
              : null,
        ),
        _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
        Text(
          user.username,
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.largeFontSize,
            fontWeight: FontWeight.w500,
            color: GeneralConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            user.groupIds.length.toString(),
            UserDetailScreenConstants.groupsCountLabel,
            Icons.folder_outlined,
          ),
        ),
        const SizedBox(width: UserDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            user.friendIds.length.toString(),
            UserDetailScreenConstants.friendsCountLabel,
            Icons.people_outline,
          ),
        ),
        const SizedBox(width: UserDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            user.totalAttempts.toString(),
            UserDetailScreenConstants.attemptsCountLabel,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: UserDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            '${user.globalAccuracy.toStringAsFixed(0)}%',
            UserDetailScreenConstants.accuracyLabel,
            Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GeneralConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.secondaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(
          UserDetailScreenConstants.cardBorderRadius,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: GeneralConstants.smallIconSize,
            color: GeneralConstants.secondaryColor,
          ),
          const SizedBox(height: GeneralConstants.tinySpacing),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: UserDetailScreenConstants.statFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.primaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: UserDetailScreenConstants.statLabelFontSize,
              fontWeight: FontWeight.w300,
              color: GeneralConstants.primaryColor.withValues(
                alpha: GeneralConstants.smallOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          UserDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: UserDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: GeneralConstants.smallSmallIconSize,
                color: GeneralConstants.secondaryColor,
              ),
              const SizedBox(width: GeneralConstants.tinySpacing),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: UserDetailScreenConstants.sectionHeaderFontSize,
                  fontWeight: FontWeight.w500,
                  color: GeneralConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: GeneralConstants.smallSpacing),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GROUPS TAB
  // ---------------------------------------------------------------------------

  Widget _buildGroupsTab(UserModel user) {
    return StreamBuilder<List<GroupModel>>(
      stream: _userService.streamUserGroups(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return _buildEmptyState(UserDetailScreenConstants.noGroupsMessage);
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: Utils.isMobile(context)
                ? GeneralConstants.smallMargin
                : MediaQuery.of(context).size.width * 0.2,
            vertical: GeneralConstants.smallMargin,
          ),
          itemCount: groups.length,
          separatorBuilder: (_, __) =>
              _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
          itemBuilder: (context, index) => _buildGroupTile(groups[index]),
        );
      },
    );
  }

  Widget _buildGroupTile(GroupModel group) {
    return Container(
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          UserDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: UserDetailScreenConstants.cardBorderOpacity,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: UserDetailScreenConstants.cardShadowOpacity,
            ),
            blurRadius: UserDetailScreenConstants.cardBlurRadius,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            UserDetailScreenConstants.cardBorderRadius,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => GroupDetailScreen(groupId: group.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(GeneralConstants.smallPadding),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: GeneralConstants.secondaryColor,
                  size: GeneralConstants.smallIconSize,
                ),
                const SizedBox(width: GeneralConstants.smallSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.lexend(
                          fontSize: GeneralConstants.smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: GeneralConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: GeneralConstants.tinySpacing),
                      Row(
                        children: [
                          Text(
                            '${group.memberCount} members',
                            style: GoogleFonts.lexend(
                              fontSize: UserDetailScreenConstants.badgeFontSize,
                              fontWeight: FontWeight.w300,
                              color: GeneralConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: GeneralConstants.smallSpacing),
                          Text(
                            '${group.totalContentCount} items',
                            style: GoogleFonts.lexend(
                              fontSize: UserDetailScreenConstants.badgeFontSize,
                              fontWeight: FontWeight.w300,
                              color: GeneralConstants.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildVisibilityBadge(group),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(GroupModel group) {
    final String label;
    final Color color;

    if (group.isPublic) {
      label = 'Public';
      color = GeneralConstants.successColor;
    } else if (group.isFriendsOnly) {
      label = 'Friends';
      color = GeneralConstants.tertiaryColor;
    } else {
      label = 'Private';
      color = GeneralConstants.failureColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UserDetailScreenConstants.badgeHorizontalPadding,
        vertical: UserDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: UserDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FRIENDS TAB
  // ---------------------------------------------------------------------------

  Widget _buildFriendsTab(UserModel user) {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.streamFriends(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return _buildEmptyState(UserDetailScreenConstants.noFriendsMessage);
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: Utils.isMobile(context)
                ? GeneralConstants.smallMargin
                : MediaQuery.of(context).size.width * 0.2,
            vertical: GeneralConstants.smallMargin,
          ),
          itemCount: friends.length,
          separatorBuilder: (_, __) =>
              _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
          itemBuilder: (context, index) => _buildFriendTile(friends[index]),
        );
      },
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    return Container(
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          UserDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: UserDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            UserDetailScreenConstants.cardBorderRadius,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => UserDetailScreen(userId: friend.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(GeneralConstants.smallPadding),
            child: Row(
              children: [
                CircleAvatar(
                  radius: UserDetailScreenConstants.memberAvatarRadius,
                  backgroundColor: GeneralConstants.tertiaryColor,
                  backgroundImage: friend.profilePic.isNotEmpty
                      ? NetworkImage(friend.profilePic)
                      : null,
                  child: friend.profilePic.isEmpty
                      ? Text(
                          friend.username.isNotEmpty
                              ? friend.username[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.lexend(
                            color: GeneralConstants.backgroundColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: GeneralConstants.smallSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.username,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.lexend(
                          fontSize: GeneralConstants.smallFontSize,
                          fontWeight: FontWeight.w500,
                          color: GeneralConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: GeneralConstants.tinySpacing),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: GeneralConstants.smallSmallIconSize,
                            color: GeneralConstants.secondaryColor,
                          ),
                          const SizedBox(width: GeneralConstants.tinySpacing),
                          Text(
                            '${friend.groupIds.length}',
                            style: GoogleFonts.lexend(
                              fontSize: UserDetailScreenConstants.badgeFontSize,
                              fontWeight: FontWeight.w300,
                              color: GeneralConstants.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: GeneralConstants.smallSpacing),
                          Icon(
                            Icons.people_outline,
                            size: GeneralConstants.smallSmallIconSize,
                            color: GeneralConstants.secondaryColor,
                          ),
                          const SizedBox(width: GeneralConstants.tinySpacing),
                          Text(
                            '${friend.friendIds.length}',
                            style: GoogleFonts.lexend(
                              fontSize: UserDetailScreenConstants.badgeFontSize,
                              fontWeight: FontWeight.w300,
                              color: GeneralConstants.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: GeneralConstants.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATISTICS TAB
  // ---------------------------------------------------------------------------

  Widget _buildStatsTab(UserModel user) {
    final entries = user.allStatistics
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (entries.isEmpty) {
      return _buildEmptyState(UserDetailScreenConstants.noStatsMessage);
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          _buildSpacing(height: UserDetailScreenConstants.fieldSpacing),
      itemBuilder: (context, index) => _buildStatEntry(entries[index]),
    );
  }

  Widget _buildStatEntry(UserStatisticsEntry entry) {
    final IconData icon;
    final Color accentColor;

    switch (entry.activityType) {
      case AttemtType.test:
        icon = Icons.quiz_outlined;
        accentColor = GeneralConstants.secondaryColor;
      case AttemtType.flashcard:
        icon = Icons.style_outlined;
        accentColor = GeneralConstants.tertiaryColor;
      case AttemtType.connect:
        icon = Icons.link;
        accentColor = GeneralConstants.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          UserDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: UserDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(GeneralConstants.smallPadding),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(
                GeneralConstants.smallCircularRadius,
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: GeneralConstants.smallIconSize,
            ),
          ),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: GeneralConstants.tinySpacing),
                Row(
                  children: [
                    Text(
                      '${entry.correct} ${UserDetailScreenConstants.correctLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: UserDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      '${entry.incorrect} ${UserDetailScreenConstants.incorrectLabel}',
                      style: GoogleFonts.lexend(
                        fontSize: UserDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.failureColor,
                      ),
                    ),
                    const SizedBox(width: GeneralConstants.smallSpacing),
                    Text(
                      _formatDate(entry.completedAt),
                      style: GoogleFonts.lexend(
                        fontSize: UserDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.primaryColor.withValues(
                          alpha: GeneralConstants.mediumOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildAccuracyBadge(entry.accuracy),
        ],
      ),
    );
  }

  Widget _buildAccuracyBadge(double accuracy) {
    final Color color;
    if (accuracy >= 80) {
      color = GeneralConstants.successColor;
    } else if (accuracy >= 50) {
      color = GeneralConstants.tertiaryColor;
    } else {
      color = GeneralConstants.failureColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UserDetailScreenConstants.badgeHorizontalPadding,
        vertical: UserDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        '${accuracy.toStringAsFixed(0)}%',
        style: GoogleFonts.lexend(
          fontSize: UserDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
