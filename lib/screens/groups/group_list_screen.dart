import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'group_detail_screen.dart'; // Ensure this import is correct

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final GroupService _groupService = GroupService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _searchQuery = '';
  String _sortBy = 'newest'; // Options: 'newest', 'popular', 'alpha'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Explore Communities',
          style: GoogleFonts.lexend(
            color: GeneralConstants.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(child: _buildGroupList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Field
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search groups or tags...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sort Options (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text("Sort by: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _buildSortChip('Newest', 'newest'),
                const SizedBox(width: 8),
                _buildSortChip('Popular', 'popular'),
                const SizedBox(width: 8),
                _buildSortChip('Name (A-Z)', 'alpha'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: GeneralConstants.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? GeneralConstants.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) setState(() => _sortBy = value);
      },
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder<List<GroupModel>>(
      // 1. Fetch ALL Public Groups
      stream: _groupService.getAllPublicGroupsStream(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error State
        if (snapshot.hasError) {
          print("Something went wrong: ${snapshot.error}");
          return Center(child: Text("Something went wrong: ${snapshot.error}"));
        }

        final allPublicGroups = snapshot.data ?? [];

        // 2. FILTER: Remove groups user is already in
        // We only want to show "Explore" groups here
        final exploreGroups = allPublicGroups.where((group) {
          return !group.userIds.contains(_currentUserId);
        }).toList();

        // 3. FILTER & SORT: Apply search and sort logic using Service
        final displayedGroups = _groupService.searchGroupsLocally(
          allGroups: exploreGroups,
          searchQuery: _searchQuery,
          sortBy: _sortBy,
        );

        // Empty State
        if (displayedGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? "No new groups to join!"
                      : "No groups match your search.",
                  style: GoogleFonts.lexend(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // List View
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayedGroups.length,
          itemBuilder: (context, index) {
            final group = displayedGroups[index];
            return _buildGroupCard(group);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          // Navigate to details (where they can join)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group.id),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: group.profilePic.isNotEmpty
              ? NetworkImage(group.profilePic)
              : null,
          child: group.profilePic.isEmpty
              ? const Icon(Icons.group, color: Colors.grey)
              : null,
        ),
        title: Text(
          group.name,
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${group.userIds.length} members',
                  style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (group.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GeneralConstants.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: GeneralConstants.primaryColor.withOpacity(0.1)),
                  ),
                  child: Text(
                    "#$tag",
                    style: TextStyle(
                      fontSize: 11,
                      color: GeneralConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ]
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}