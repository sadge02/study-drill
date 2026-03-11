import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../models/connect/connect_model.dart';
import '../../models/flashcard/flashcard_model.dart';
import '../../models/group/group_model.dart';
import '../../models/test/test_model.dart';
import '../../models/user/user_model.dart';
import '../../service/group/group_service.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/group/screens/group_detail_screen_constants.dart';
import '../../utils/core/utils.dart';
import '../connect/connect_create_edit_screen.dart';
import '../flashcard/flashcard_create_edit_screen.dart';
import '../test/test_create_edit_screen.dart';
import 'group_create_edit_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();

  late TabController _tabController;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: GroupDetailScreenConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    final result = await _groupService.addMember(
      widget.groupId,
      _currentUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: GroupDetailScreenConstants.joinSuccessMessage,
        ),
      );
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _handleLeave() async {
    final result = await _groupService.leaveGroup(
      widget.groupId,
      _currentUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: GroupDetailScreenConstants.leaveSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          GroupDetailScreenConstants.deleteConfirmTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w500),
        ),
        content: Text(
          GroupDetailScreenConstants.deleteConfirmMessage,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              GroupDetailScreenConstants.cancelLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              GroupDetailScreenConstants.confirmLabel,
              style: GoogleFonts.lexend(color: GeneralConstants.failureColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _groupService.deleteGroup(
      widget.groupId,
      deletedBy: _currentUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(
        const CustomSnackBar.success(
          message: GroupDetailScreenConstants.deleteSuccessMessage,
        ),
      );
      Navigator.pop(context);
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  void _navigateToEdit(GroupModel group) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupCreateEditScreen(group: group),
      ),
    );
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
    return StreamBuilder<GroupModel?>(
      stream: _groupService.streamGroupById(widget.groupId),
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

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: Center(
              child: Text(
                'Error loading group.',
                style: GoogleFonts.lexend(
                  color: GeneralConstants.primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          );
        }

        final group = snapshot.data;
        if (group == null) {
          return Scaffold(
            backgroundColor: GeneralConstants.backgroundColor,
            appBar: _buildAppBar(null),
            body: Center(
              child: Text(
                'Group not found.',
                style: GoogleFonts.lexend(
                  color: GeneralConstants.primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          );
        }

        final bool isMember = group.isMember(_currentUserId);
        final bool isAuthor = group.authorId == _currentUserId;
        final bool isAdmin = group.isAdmin(_currentUserId);

        return Scaffold(
          backgroundColor: GeneralConstants.backgroundColor,
          appBar: _buildAppBar(group),
          body: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(group, isMember, isAuthor, isAdmin),
                    _buildMembersTab(group, isAuthor, isAdmin),
                    _buildTestsTab(
                      group,
                      isAuthor || isAdmin || group.isCreator(_currentUserId),
                    ),
                    _buildFlashcardsTab(
                      group,
                      isAuthor || isAdmin || group.isCreator(_currentUserId),
                    ),
                    _buildConnectsTab(
                      group,
                      isAuthor || isAdmin || group.isCreator(_currentUserId),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(GroupModel? group) {
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
        group?.title ?? GroupDetailScreenConstants.appBarTitle,
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
      actions: group != null ? _buildAppBarActions(group) : null,
    );
  }

  List<Widget> _buildAppBarActions(GroupModel group) {
    final bool isAuthor = group.authorId == _currentUserId;
    final bool isAdmin = group.isAdmin(_currentUserId);
    final bool isMember = group.isMember(_currentUserId);

    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: GeneralConstants.primaryColor),
        offset: const Offset(0, GeneralConstants.appBarHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            GeneralConstants.mediumCircularRadius,
          ),
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _navigateToEdit(group);
            case 'leave':
              _handleLeave();
            case 'delete':
              _handleDelete();
            case 'join':
              _handleJoin();
          }
        },
        itemBuilder: (_) {
          final items = <PopupMenuEntry<String>>[];

          if (!isMember) {
            items.add(
              _buildPopupItem(
                'join',
                Icons.group_add_outlined,
                GroupDetailScreenConstants.joinGroupLabel,
                GeneralConstants.successColor,
              ),
            );
          }

          if (isAuthor || isAdmin) {
            items.add(
              _buildPopupItem(
                'edit',
                Icons.edit_outlined,
                GroupDetailScreenConstants.editGroupLabel,
                GeneralConstants.primaryColor,
              ),
            );
          }

          if (isMember && !isAuthor) {
            items.add(
              _buildPopupItem(
                'leave',
                Icons.exit_to_app,
                GroupDetailScreenConstants.leaveGroupLabel,
                GeneralConstants.failureColor,
              ),
            );
          }

          if (isAuthor) {
            items.add(
              _buildPopupItem(
                'delete',
                Icons.delete_outline,
                GroupDetailScreenConstants.deleteGroupLabel,
                GeneralConstants.failureColor,
              ),
            );
          }

          return items;
        },
      ),
      const SizedBox(width: GeneralConstants.smallMargin),
    ];
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: GeneralConstants.smallSpacing),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w300,
              color: color,
            ),
          ),
        ],
      ),
    );
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
          Tab(text: GroupDetailScreenConstants.overviewTab),
          Tab(text: GroupDetailScreenConstants.membersTab),
          Tab(text: GroupDetailScreenConstants.testsTab),
          Tab(text: GroupDetailScreenConstants.flashcardsTab),
          Tab(text: GroupDetailScreenConstants.connectsTab),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab(
    GroupModel group,
    bool isMember,
    bool isAuthor,
    bool isAdmin,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow(group),
          _buildSpacing(height: GroupDetailScreenConstants.sectionSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.descriptionLabel,
            Icons.description_outlined,
            child: Text(
              group.description.isEmpty
                  ? GroupDetailScreenConstants.noDescriptionLabel
                  : group.description,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: group.description.isEmpty
                    ? GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      )
                    : GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.tagsLabel,
            Icons.tag,
            child: group.tags.isEmpty
                ? Text(
                    GroupDetailScreenConstants.noTagsLabel,
                    style: GoogleFonts.lexend(
                      fontSize: GeneralConstants.smallFontSize,
                      fontWeight: FontWeight.w300,
                      color: GeneralConstants.primaryColor.withValues(
                        alpha: GeneralConstants.mediumOpacity,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: GroupDetailScreenConstants.tagChipSpacing,
                    runSpacing: GroupDetailScreenConstants.tagChipSpacing,
                    children: group.tags.map(_buildTagChip).toList(),
                  ),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.visibilityLabel,
            Icons.visibility_outlined,
            child: _buildVisibilityBadge(group),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.settingsLabel,
            Icons.settings_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.settings.autoAddAsEditor
                      ? GroupDetailScreenConstants.autoAddEditorEnabled
                      : GroupDetailScreenConstants.autoAddEditorDisabled,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w300,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: GeneralConstants.tinySpacing),
                Text(
                  group.settings.requiresJoinApproval
                      ? GroupDetailScreenConstants.requireApprovalEnabled
                      : GroupDetailScreenConstants.requireApprovalDisabled,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w300,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.createdLabel,
            Icons.calendar_today_outlined,
            child: Text(
              _formatDate(group.createdAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          _buildOverviewSection(
            GroupDetailScreenConstants.updatedLabel,
            Icons.update_outlined,
            child: Text(
              _formatDate(group.updatedAt),
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor,
              ),
            ),
          ),
          _buildSpacing(height: GroupDetailScreenConstants.sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildStatRow(GroupModel group) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            group.memberCount.toString(),
            GroupDetailScreenConstants.membersCountLabel,
            Icons.people_outline,
          ),
        ),
        const SizedBox(width: GroupDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            group.testCount.toString(),
            GroupDetailScreenConstants.testsCountLabel,
            Icons.quiz_outlined,
          ),
        ),
        const SizedBox(width: GroupDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            group.flashcardCount.toString(),
            GroupDetailScreenConstants.flashcardsCountLabel,
            Icons.style_outlined,
          ),
        ),
        const SizedBox(width: GroupDetailScreenConstants.fieldSpacing),
        Expanded(
          child: _buildStatCard(
            group.connectCount.toString(),
            GroupDetailScreenConstants.connectsCountLabel,
            Icons.link,
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
          GroupDetailScreenConstants.cardBorderRadius,
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
              fontSize: GroupDetailScreenConstants.statFontSize,
              fontWeight: FontWeight.w600,
              color: GeneralConstants.primaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: GroupDetailScreenConstants.statLabelFontSize,
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

  Widget _buildOverviewSection(
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
          GroupDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: GroupDetailScreenConstants.cardBorderOpacity,
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
                  fontSize: GroupDetailScreenConstants.sectionHeaderFontSize,
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

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GroupDetailScreenConstants.badgeHorizontalPadding,
        vertical: GroupDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: GeneralConstants.tertiaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.lexend(
          fontSize: GroupDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w300,
          color: GeneralConstants.secondaryColor,
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(GroupModel group) {
    final String label;
    final Color color;

    if (group.isPublic) {
      label = GroupDetailScreenConstants.visibilityPublic;
      color = GeneralConstants.successColor;
    } else if (group.isFriendsOnly) {
      label = GroupDetailScreenConstants.visibilityFriends;
      color = GeneralConstants.tertiaryColor;
    } else {
      label = GroupDetailScreenConstants.visibilityPrivate;
      color = GeneralConstants.failureColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GroupDetailScreenConstants.badgeHorizontalPadding,
        vertical: GroupDetailScreenConstants.badgeVerticalPadding,
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
          fontSize: GroupDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MEMBERS TAB
  // ---------------------------------------------------------------------------

  Widget _buildMembersTab(GroupModel group, bool isAuthor, bool isAdmin) {
    return FutureBuilder<List<UserModel>>(
      future: _userService.getUsersByIds(group.userIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return _buildEmptyState(GroupDetailScreenConstants.noMembersMessage);
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: Utils.isMobile(context)
                ? GeneralConstants.smallMargin
                : MediaQuery.of(context).size.width * 0.2,
            vertical: GeneralConstants.smallMargin,
          ),
          itemCount: members.length,
          separatorBuilder: (_, __) =>
              _buildSpacing(height: GroupDetailScreenConstants.fieldSpacing),
          itemBuilder: (context, index) {
            return _buildMemberTile(members[index], group, isAuthor, isAdmin);
          },
        );
      },
    );
  }

  Widget _buildMemberTile(
    UserModel user,
    GroupModel group,
    bool isCurrentUserAuthor,
    bool isCurrentUserAdmin,
  ) {
    final String role = _getMemberRole(user.id, group);

    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          GroupDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: GroupDetailScreenConstants.cardBorderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: GroupDetailScreenConstants.memberAvatarRadius,
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
                  user.username,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: GeneralConstants.tinySpacing),
                _buildRoleBadge(role),
              ],
            ),
          ),
          if ((isCurrentUserAuthor || isCurrentUserAdmin) &&
              user.id != group.authorId &&
              user.id != _currentUserId)
            IconButton(
              icon: const Icon(
                Icons.person_remove_outlined,
                color: GeneralConstants.failureColor,
                size: GeneralConstants.smallIconSize,
              ),
              onPressed: () => _handleKick(group.id, user.id),
            ),
        ],
      ),
    );
  }

  void _handleKick(String groupId, String userId) async {
    final result = await _groupService.kickMember(
      groupId,
      userId,
      kickedBy: _currentUserId,
    );
    if (!mounted) return;
    if (result == null) {
      _showSnackBar(const CustomSnackBar.success(message: 'Member removed.'));
    } else {
      _showSnackBar(CustomSnackBar.error(message: result));
    }
  }

  String _getMemberRole(String userId, GroupModel group) {
    if (group.authorId == userId) {
      return GroupDetailScreenConstants.roleOwner;
    }
    if (group.isAdmin(userId)) {
      return GroupDetailScreenConstants.roleAdmin;
    }
    if (group.isCreator(userId)) {
      return GroupDetailScreenConstants.roleCreator;
    }
    return GroupDetailScreenConstants.roleMember;
  }

  Widget _buildRoleBadge(String role) {
    final Color color;
    switch (role) {
      case GroupDetailScreenConstants.roleOwner:
        color = GeneralConstants.secondaryColor;
      case GroupDetailScreenConstants.roleAdmin:
        color = GeneralConstants.tertiaryColor;
      case GroupDetailScreenConstants.roleCreator:
        color = GeneralConstants.successColor;
      default:
        color = GeneralConstants.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GroupDetailScreenConstants.badgeHorizontalPadding,
        vertical: GroupDetailScreenConstants.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          GeneralConstants.smallCircularRadius,
        ),
      ),
      child: Text(
        role,
        style: GoogleFonts.lexend(
          fontSize: GroupDetailScreenConstants.badgeFontSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TESTS TAB
  // ---------------------------------------------------------------------------

  Widget _buildTestsTab(GroupModel group, bool canCreate) {
    return StreamBuilder<List<TestModel>>(
      stream: _groupService.streamTestsByGroupId(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading tests.');
        }

        final tests = snapshot.data ?? [];

        if (tests.isEmpty && !canCreate) {
          return _buildEmptyState(GroupDetailScreenConstants.noTestsMessage);
        }

        return Column(
          children: [
            if (canCreate)
              _buildCreateButton(
                GroupDetailScreenConstants.createTestLabel,
                Icons.quiz_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TestCreateEditScreen(groupId: group.id),
                  ),
                ),
              ),
            if (tests.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  GroupDetailScreenConstants.noTestsMessage,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: Utils.isMobile(context)
                        ? GeneralConstants.smallMargin
                        : MediaQuery.of(context).size.width * 0.2,
                    vertical: GeneralConstants.smallMargin,
                  ),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => _buildSpacing(
                    height: GroupDetailScreenConstants.fieldSpacing,
                  ),
                  itemBuilder: (context, index) => _buildTestCard(tests[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTestCard(TestModel test) {
    return _buildContentCard(
      title: test.title,
      description: test.description,
      icon: Icons.quiz_outlined,
      stats: [
        '${test.questionCount} ${GroupDetailScreenConstants.questionsLabel}',
        '${test.attemptCount} ${GroupDetailScreenConstants.attemptsLabel}',
      ],
      tags: test.tags,
    );
  }

  // ---------------------------------------------------------------------------
  // FLASHCARDS TAB
  // ---------------------------------------------------------------------------

  Widget _buildFlashcardsTab(GroupModel group, bool canCreate) {
    return StreamBuilder<List<FlashcardSet>>(
      stream: _groupService.streamFlashcardSetsByGroupId(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading flashcards.');
        }

        final flashcards = snapshot.data ?? [];

        if (flashcards.isEmpty && !canCreate) {
          return _buildEmptyState(
            GroupDetailScreenConstants.noFlashcardsMessage,
          );
        }

        return Column(
          children: [
            if (canCreate)
              _buildCreateButton(
                GroupDetailScreenConstants.createFlashcardLabel,
                Icons.style_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CreateEditFlashcardScreen(groupId: group.id),
                  ),
                ),
              ),
            if (flashcards.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  GroupDetailScreenConstants.noFlashcardsMessage,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: Utils.isMobile(context)
                        ? GeneralConstants.smallMargin
                        : MediaQuery.of(context).size.width * 0.2,
                    vertical: GeneralConstants.smallMargin,
                  ),
                  itemCount: flashcards.length,
                  separatorBuilder: (_, __) => _buildSpacing(
                    height: GroupDetailScreenConstants.fieldSpacing,
                  ),
                  itemBuilder: (context, index) =>
                      _buildFlashcardCard(flashcards[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFlashcardCard(FlashcardSet flashcard) {
    return _buildContentCard(
      title: flashcard.title,
      description: flashcard.description,
      icon: Icons.style_outlined,
      stats: [
        '${flashcard.cardCount} ${GroupDetailScreenConstants.cardsLabel}',
        '${flashcard.attemptCount} ${GroupDetailScreenConstants.attemptsLabel}',
      ],
      tags: flashcard.tags,
    );
  }

  // ---------------------------------------------------------------------------
  // CONNECTS TAB
  // ---------------------------------------------------------------------------

  Widget _buildConnectsTab(GroupModel group, bool canCreate) {
    return StreamBuilder<List<ConnectModel>>(
      stream: _groupService.streamConnectsByGroupId(group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading connects.');
        }

        final connects = snapshot.data ?? [];

        if (connects.isEmpty && !canCreate) {
          return _buildEmptyState(GroupDetailScreenConstants.noConnectsMessage);
        }

        return Column(
          children: [
            if (canCreate)
              _buildCreateButton(
                GroupDetailScreenConstants.createConnectLabel,
                Icons.link,
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ConnectCreateEditScreen(groupId: group.id),
                  ),
                ),
              ),
            if (connects.isEmpty)
              Expanded(
                child: _buildEmptyState(
                  GroupDetailScreenConstants.noConnectsMessage,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: Utils.isMobile(context)
                        ? GeneralConstants.smallMargin
                        : MediaQuery.of(context).size.width * 0.2,
                    vertical: GeneralConstants.smallMargin,
                  ),
                  itemCount: connects.length,
                  separatorBuilder: (_, __) => _buildSpacing(
                    height: GroupDetailScreenConstants.fieldSpacing,
                  ),
                  itemBuilder: (context, index) =>
                      _buildConnectCard(connects[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConnectCard(ConnectModel connect) {
    return _buildContentCard(
      title: connect.title,
      description: connect.description,
      icon: Icons.link,
      stats: [
        '${connect.pairCount} ${GroupDetailScreenConstants.pairsLabel}',
        '${connect.attemptCount} ${GroupDetailScreenConstants.attemptsLabel}',
      ],
      tags: connect.tags,
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildCreateButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.isMobile(context)
            ? GeneralConstants.smallMargin
            : MediaQuery.of(context).size.width * 0.2,
        vertical: GeneralConstants.smallPadding,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: GeneralConstants.secondaryColor),
          label: Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: GeneralConstants.smallFontSize,
              fontWeight: FontWeight.w500,
              color: GeneralConstants.secondaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: GeneralConstants.secondaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                GeneralConstants.mediumCircularRadius,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: GeneralConstants.smallPadding,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String description,
    required IconData icon,
    required List<String> stats,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(GeneralConstants.smallPadding),
      decoration: BoxDecoration(
        color: GeneralConstants.backgroundColor,
        borderRadius: BorderRadius.circular(
          GroupDetailScreenConstants.cardBorderRadius,
        ),
        border: Border.all(
          color: GeneralConstants.primaryColor.withValues(
            alpha: GroupDetailScreenConstants.cardBorderOpacity,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: GroupDetailScreenConstants.cardShadowOpacity,
            ),
            blurRadius: GroupDetailScreenConstants.cardBlurRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: GeneralConstants.secondaryColor,
                size: GeneralConstants.smallIconSize,
              ),
              const SizedBox(width: GeneralConstants.smallSpacing),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    fontWeight: FontWeight.w500,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: GeneralConstants.tinySpacing),
            Text(
              description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: GoogleFonts.lexend(
                fontSize: GeneralConstants.smallFontSize - 2,
                fontWeight: FontWeight.w300,
                color: GeneralConstants.primaryColor.withValues(
                  alpha: GeneralConstants.smallOpacity,
                ),
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: GeneralConstants.smallSpacing),
            Wrap(
              spacing: GroupDetailScreenConstants.tagChipSpacing,
              runSpacing: GroupDetailScreenConstants.tagChipSpacing,
              children: tags.map(_buildTagChip).toList(),
            ),
          ],
          const SizedBox(height: GeneralConstants.smallSpacing),
          Row(
            children: stats
                .map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(
                      right: GeneralConstants.smallSpacing,
                    ),
                    child: Text(
                      stat,
                      style: GoogleFonts.lexend(
                        fontSize: GroupDetailScreenConstants.badgeFontSize,
                        fontWeight: FontWeight.w300,
                        color: GeneralConstants.secondaryColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

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
