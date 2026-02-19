import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';

import 'create_edit_group_screen.dart';

// Enum for the "My Role" filter
enum GroupRoleFilter { all, createdByMe, member }

// Enum for Sorting (Must match the UI labels)
enum GroupSortOption { newest, oldest, mostMembers, alphabetical }

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // --- Filter State ---
  String _searchQuery = '';
  GroupSortOption _sortOption = GroupSortOption.newest;
  GroupRoleFilter _roleFilter = GroupRoleFilter.all;

  // Selected Tags
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC: Filter & Sort ---
  List<GroupModel> _processGroups(List<GroupModel> allGroups) {
    // 1. Filter by Role
    var result = allGroups.where((group) {
      if (_roleFilter == GroupRoleFilter.createdByMe) {
        return group.authorId == _currentUserId;
      }
      if (_roleFilter == GroupRoleFilter.member) {
        return group.authorId != _currentUserId;
      }
      return true;
    }).toList();

    // 2. Filter by Search Query (Using new nameLowercase field)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((group) {
        return group.nameLowercase.contains(query);
      }).toList();
    }

    // 3. Filter by Tags
    if (_selectedTags.isNotEmpty) {
      result = result.where((group) {
        return _selectedTags.any((tag) => group.tags.contains(tag));
      }).toList();
    }

    // 4. Sort
    switch (_sortOption) {
      case GroupSortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GroupSortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case GroupSortOption.mostMembers:
        result.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        break;
      case GroupSortOption.alphabetical:
        result.sort((a, b) => a.nameLowercase.compareTo(b.nameLowercase));
        break;
    }

    return result;
  }

  /// Opens the Filter/Sort Bottom Sheet
  void _showFilterModal(List<String> availableTags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 1. Role Filter
                  _buildSectionTitle('Show Groups'),
                  const SizedBox(height: 10),
                  SegmentedButton<GroupRoleFilter>(
                    segments: const [
                      ButtonSegment(
                        value: GroupRoleFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: GroupRoleFilter.createdByMe,
                        label: Text('Created'),
                      ),
                      ButtonSegment(
                        value: GroupRoleFilter.member,
                        label: Text('Joined'),
                      ),
                    ],
                    selected: {_roleFilter},
                    onSelectionChanged: (Set<GroupRoleFilter> newSelection) {
                      setModalState(() => _roleFilter = newSelection.first);
                      setState(() {});
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return GeneralConstants.primaryColor.withOpacity(0.2);
                        }
                        return Colors.transparent;
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Sort Options
                  _buildSectionTitle('Sort By'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: GroupSortOption.values.map((option) {
                      final isSelected = _sortOption == option;
                      return ChoiceChip(
                        label: Text(_getSortLabel(option)),
                        selected: isSelected,
                        selectedColor: GeneralConstants.primaryColor
                            .withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? GeneralConstants.primaryColor
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setModalState(() => _sortOption = option);
                            setState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Tag Filter
                  if (availableTags.isNotEmpty) ...[
                    _buildSectionTitle('Filter by Tags'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          checkmarkColor: GeneralConstants.primaryColor,
                          selectedColor: GeneralConstants.primaryColor
                              .withOpacity(0.2),
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GeneralConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Apply Filters",
                        style: GoogleFonts.lexend(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  String _getSortLabel(GroupSortOption option) {
    switch (option) {
      case GroupSortOption.newest:
        return 'Newest';
      case GroupSortOption.oldest:
        return 'Oldest';
      case GroupSortOption.mostMembers:
        return 'Popular';
      case GroupSortOption.alphabetical:
        return 'A-Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Groups',
          style: GoogleFonts.lexend(
            color: GeneralConstants.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GeneralConstants.primaryColor,
        onPressed: () => Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const CreateEditGroupScreen(),
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _currentUserId.isEmpty
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<List<GroupModel>>(
              stream: _groupService.getUserGroupsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allUserGroups = snapshot.data ?? [];

                // Extract all unique tags available in the user's groups
                final Set<String> extractedTags = {};
                for (var group in allUserGroups) {
                  extractedTags.addAll(group.tags);
                }
                final List<String> availableTags = extractedTags.toList()
                  ..sort();

                // Process (Filter & Sort)
                final displayGroups = _processGroups(allUserGroups);

                return Column(
                  children: [
                    _buildSearchBar(availableTags),
                    _buildActiveFiltersList(),
                    Expanded(
                      child: displayGroups.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 80,
                              ),
                              itemCount: displayGroups.length,
                              itemBuilder: (context, index) {
                                return _buildGroupTile(displayGroups[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSearchBar(List<String> availableTags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search my groups...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showFilterModal(availableTags),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GeneralConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersList() {
    if (_selectedTags.isEmpty && _roleFilter == GroupRoleFilter.all) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_roleFilter != GroupRoleFilter.all)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  _roleFilter == GroupRoleFilter.createdByMe
                      ? "Created by Me"
                      : "Joined",
                ),
                backgroundColor: GeneralConstants.primaryColor.withOpacity(0.1),
                deleteIconColor: GeneralConstants.primaryColor,
                onDeleted: () =>
                    setState(() => _roleFilter = GroupRoleFilter.all),
              ),
            ),
          ..._selectedTags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(tag),
                onDeleted: () => setState(() => _selectedTags.remove(tag)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupModel group) {
    final bool isAuthor = group.authorId == _currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to Group Details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Icon
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(group.profilePic),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: GeneralConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          // New: Using Member Count Getter
                          Text(
                            '${group.memberCount} Members',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isAuthor)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: GeneralConstants.secondaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Owner",
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  color: GeneralConstants.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (group.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: group.tags
                              .take(3)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GeneralConstants.tertiaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: GeneralConstants.tertiaryColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Edit Button (Only for Authors)
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    onPressed: () => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: CreateEditGroupScreen(group: group),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No groups found.',
            style: GoogleFonts.lexend(color: Colors.grey[600], fontSize: 16),
          ),
          if (_roleFilter != GroupRoleFilter.all || _searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _roleFilter = GroupRoleFilter.all;
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedTags.clear();
                });
              },
              child: const Text("Clear Filters"),
            ),
        ],
      ),
    );
  }
}
