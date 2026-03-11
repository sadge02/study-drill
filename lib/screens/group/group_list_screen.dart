import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/group/group_model.dart';
import '../../service/group/group_service.dart';
import '../../service/user/user_service.dart';
import '../../utils/constants/core/general_constants.dart';
import '../../utils/constants/group/screens/group_list_screen_constants.dart';
import '../../utils/constants/home/screens/home_screen_constants.dart';
import '../../utils/core/utils.dart';
import '../../utils/enums/group/group_sort_option_enum.dart';
import '../../widgets/group/group_card.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key, this.myGroupsOnly = false});

  final bool myGroupsOnly;

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final GroupService _groupService = GroupService();
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _tags = [];
  GroupVisibility? _selectedVisibility;
  GroupSortOption _sortOption = GroupSortOption.newest;

  String _currentUserId = '';
  List<String> _currentUserFriendIds = [];
  bool _isUserLoaded = false;

  late Stream<List<GroupModel>> _groupStream;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _rebuildStream();
  }

  void _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    _currentUserId = firebaseUser.uid;

    final user = await _userService.getUserById(_currentUserId);
    if (!mounted) return;

    setState(() {
      _currentUserFriendIds = user?.friendIds ?? [];
      _isUserLoaded = true;
    });
  }

  void _rebuildStream() {
    _groupStream = _groupService.streamFilteredGroups(
      titleStartsWith: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      tags: _tags.isEmpty ? null : _tags,
      visibility: _selectedVisibility,
      sortOption: _sortOption,
    );
  }

  void _onSearchChanged(String _) {
    setState(() => _rebuildStream());
  }

  void _onTagSubmitted(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
      _rebuildStream();
    });
  }

  void _onTagRemoved(String tag) {
    setState(() {
      _tags.remove(tag);
      _rebuildStream();
    });
  }

  void _onVisibilityChanged(GroupVisibility? visibility) {
    setState(() {
      _selectedVisibility = visibility;
      _rebuildStream();
    });
  }

  void _onSortChanged(GroupSortOption? option) {
    if (option == null) return;
    setState(() {
      _sortOption = option;
      _rebuildStream();
    });
  }

  void _navigateToDetail(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailScreen(groupId: group.id),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      title: Text(
        widget.myGroupsOnly
            ? HomeScreenConstants.myGroupsLabel
            : GroupListScreenConstants.appBarTitle,
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
        _buildSpacing(height: GroupListScreenConstants.filterBarSpacing),
        _buildTagInput(),
        if (_tags.isNotEmpty) ...[
          _buildSpacing(height: GroupListScreenConstants.filterBarSpacing),
          _buildActiveTagChips(),
        ],
        _buildSpacing(height: GroupListScreenConstants.filterBarSpacing),
        _buildFilterRow(),
        _buildSpacing(height: GeneralConstants.mediumSpacing),
        Expanded(child: _buildGroupList()),
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
        hintText: GroupListScreenConstants.nameSearchHint,
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

  Widget _buildTagInput() {
    return TextField(
      controller: _tagController,
      onSubmitted: _onTagSubmitted,
      style: GoogleFonts.lexend(
        fontSize: GeneralConstants.smallFontSize,
        color: GeneralConstants.primaryColor,
      ),
      decoration: InputDecoration(
        hintText: GroupListScreenConstants.tagInputHint,
        hintStyle: GoogleFonts.lexend(
          fontSize: GeneralConstants.smallFontSize,
          color: GeneralConstants.primaryColor.withValues(
            alpha: GeneralConstants.mediumOpacity,
          ),
        ),
        prefixIcon: const Icon(Icons.tag, color: GeneralConstants.primaryColor),
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

  Widget _buildActiveTagChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: GroupListScreenConstants.tagChipSpacing,
        runSpacing: GroupListScreenConstants.tagChipSpacing,
        children: _tags.map((tag) => _buildRemovableTagChip(tag)).toList(),
      ),
    );
  }

  Widget _buildRemovableTagChip(String tag) {
    return Chip(
      label: Text(
        tag,
        style: GoogleFonts.lexend(
          fontSize: GroupListScreenConstants.visibilityBadgeFontSize,
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

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildVisibilityDropdown()),
        const SizedBox(width: GroupListScreenConstants.filterBarSpacing),
        Expanded(child: _buildSortDropdown()),
      ],
    );
  }

  Widget _buildVisibilityDropdown() {
    return Container(
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
        child: DropdownButton<GroupVisibility?>(
          value: _selectedVisibility,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: GeneralConstants.primaryColor,
          ),
          style: GoogleFonts.lexend(
            fontSize: GeneralConstants.smallFontSize,
            color: GeneralConstants.primaryColor,
          ),
          items: [
            DropdownMenuItem<GroupVisibility?>(
              value: null,
              child: Text(
                GroupListScreenConstants.visibilityAll,
                style: GoogleFonts.lexend(
                  fontSize: GeneralConstants.smallFontSize,
                  color: GeneralConstants.primaryColor,
                ),
              ),
            ),
            ...GroupVisibility.values.map(
              (v) => DropdownMenuItem<GroupVisibility?>(
                value: v,
                child: Text(
                  _visibilityLabel(v),
                  style: GoogleFonts.lexend(
                    fontSize: GeneralConstants.smallFontSize,
                    color: GeneralConstants.primaryColor,
                  ),
                ),
              ),
            ),
          ],
          onChanged: _onVisibilityChanged,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
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
        child: DropdownButton<GroupSortOption>(
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
          items: GroupSortOption.values
              .map(
                (option) => DropdownMenuItem<GroupSortOption>(
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

  Widget _buildGroupList() {
    if (!_isUserLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: GeneralConstants.primaryColor),
      );
    }

    return StreamBuilder<List<GroupModel>>(
      stream: _groupStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: GeneralConstants.primaryColor,
            ),
          );
        }

        final allGroups = snapshot.data ?? [];

        final List<GroupModel> groups;
        if (widget.myGroupsOnly) {
          groups = allGroups.where((g) => g.isMember(_currentUserId)).toList();
        } else {
          groups = allGroups
              .where(
                (g) => g.isVisibleToUser(_currentUserId, _currentUserFriendIds),
              )
              .toList();
        }

        if (groups.isEmpty) {
          return Center(
            child: Text(
              GroupListScreenConstants.noGroupsFoundMessage,
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
          itemCount: groups.length,
          separatorBuilder: (_, __) =>
              _buildSpacing(height: GroupListScreenConstants.filterBarSpacing),
          itemBuilder: (context, index) {
            return GroupCard(
              group: groups[index],
              onTap: () => _navigateToDetail(groups[index]),
            );
          },
        );
      },
    );
  }

  String _visibilityLabel(GroupVisibility visibility) {
    switch (visibility) {
      case GroupVisibility.public:
        return GroupListScreenConstants.visibilityPublic;
      case GroupVisibility.private:
        return GroupListScreenConstants.visibilityPrivate;
      case GroupVisibility.friends:
        return GroupListScreenConstants.visibilityFriends;
    }
  }

  String _sortLabel(GroupSortOption option) {
    switch (option) {
      case GroupSortOption.newest:
        return GroupListScreenConstants.sortNewest;
      case GroupSortOption.oldest:
        return GroupListScreenConstants.sortOldest;
      case GroupSortOption.recentlyUpdated:
        return GroupListScreenConstants.sortRecentlyUpdated;
      case GroupSortOption.leastRecentlyUpdated:
        return GroupListScreenConstants.sortLeastRecentlyUpdated;
      case GroupSortOption.memberCount:
        return GroupListScreenConstants.sortMemberCount;
      case GroupSortOption.mostContent:
        return GroupListScreenConstants.sortMostContent;
      case GroupSortOption.alphabetical:
        return GroupListScreenConstants.sortAlphabetical;
    }
  }

  Widget _buildSpacing({double height = 0.0, double width = 0.0}) {
    return SizedBox(height: height, width: width);
  }
}
