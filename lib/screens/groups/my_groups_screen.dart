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

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _searchController = TextEditingController();

  // --- Filter State ---
  String _searchQuery = '';
  GroupSortOption _sortOption = GroupSortOption.newest;
  GroupRoleFilter _roleFilter = GroupRoleFilter.all;

  // We store selected tags here.
  // We will derive "available tags" dynamically from the loaded groups.
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the Filter/Sort Bottom Sheet
  void _showFilterModal(List<String> availableTags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Role Filter
                  Text('Show Groups', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  SegmentedButton<GroupRoleFilter>(
                    segments: const [
                      ButtonSegment(value: GroupRoleFilter.all, label: Text('All')),
                      ButtonSegment(value: GroupRoleFilter.createdByMe, label: Text('Created')),
                      ButtonSegment(value: GroupRoleFilter.member, label: Text('Joined')),
                    ],
                    selected: {_roleFilter},
                    onSelectionChanged: (Set<GroupRoleFilter> newSelection) {
                      setModalState(() => _roleFilter = newSelection.first);
                      setState(() {}); // Update parent
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return GeneralConstants.primaryColor.withOpacity(0.2);
                        }
                        return Colors.transparent;
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Sort Options
                  Text('Sort By', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: GroupSortOption.values.map((option) {
                      final isSelected = _sortOption == option;
                      return ChoiceChip(
                        label: Text(_getSortLabel(option)),
                        selected: isSelected,
                        selectedColor: GeneralConstants.primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? GeneralConstants.primaryColor : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                    Text('Filter by Tags', style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          selectedColor: GeneralConstants.primaryColor.withOpacity(0.2),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("Apply Filters", style: GoogleFonts.lexend(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getSortLabel(GroupSortOption option) {
    switch (option) {
      case GroupSortOption.newest: return 'Newest';
      case GroupSortOption.oldest: return 'Oldest';
      case GroupSortOption.mostMembers: return 'Popular';
      case GroupSortOption.leastMembers: return 'Smallest';
      case GroupSortOption.alphabetical: return 'A-Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current User ID
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Groups',
          style: GoogleFonts.lexend(color: GeneralConstants.primaryColor, fontWeight: FontWeight.bold),
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
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<List<GroupModel>>(
        stream: _groupService.getUserGroupsStream(), // 1. Fetch ALL user groups
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allUserGroups = snapshot.data ?? [];

          // 2. Extract Tags for the Filter Dropdown
          // We create a Set to get unique tags from all groups the user has.
          final Set<String> extractedTags = {};
          for (var group in allUserGroups) {
            extractedTags.addAll(group.tags);
          }
          final List<String> availableTags = extractedTags.toList()..sort();

          // 3. Apply Local Logic
          // A. Filter by Role (Author vs Member)
          List<GroupModel> filteredByRole = allUserGroups.where((group) {
            if (_roleFilter == GroupRoleFilter.all) return true;
            if (_roleFilter == GroupRoleFilter.createdByMe) return group.authorId == user.uid;
            if (_roleFilter == GroupRoleFilter.member) return group.authorId != user.uid; // Joined only
            return true;
          }).toList();

          // B. Apply Search, Tags, and Sort using the Service helper
          final displayGroups = _groupService.searchGroupsLocally(
            allGroups: filteredByRole,
            searchQuery: _searchQuery,
            filterTags: _selectedTags,
            sortBy: 'newest',
          );

          return Column(
            children: [
              _buildSearchAndFilterBar(availableTags),
              _buildActiveFiltersList(),
              Expanded(
                child: displayGroups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: displayGroups.length,
                  itemBuilder: (context, index) {
                    return _buildGroupTile(displayGroups[index], user.uid);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar(List<String> availableTags) {
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
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
    if (_selectedTags.isEmpty && _roleFilter == GroupRoleFilter.all && _sortOption == GroupSortOption.newest) {
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
                label: Text(_roleFilter == GroupRoleFilter.createdByMe ? "Created by Me" : "Joined"),
                backgroundColor: GeneralConstants.primaryColor.withOpacity(0.1),
                onDeleted: () => setState(() => _roleFilter = GroupRoleFilter.all),
                deleteIconColor: GeneralConstants.primaryColor,
              ),
            ),
          ..._selectedTags.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(tag),
              onDeleted: () => setState(() => _selectedTags.remove(tag)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupModel group, String currentUid) {
    final bool isAuthor = group.authorId == currentUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(group.profilePic),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(
          group.name,
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${group.userIds.length} Members • ${isAuthor ? "Owner" : "Member"}',
              style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[600]),
            ),
            if (group.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: group.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                  ),
                )).toList(),
              ),
            ]
          ],
        ),
        trailing: isAuthor
            ? IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.black54),
          onPressed: () => Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: CreateEditGroupScreen(group: group),
            ),
          ),
        )
            : null, // Members cannot edit
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No groups found matching your filters.',
            style: GoogleFonts.lexend(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}