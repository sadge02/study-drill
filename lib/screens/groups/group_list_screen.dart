import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final GroupService _groupService = GroupService();
  String _searchQuery = '';
  String _sortBy = 'newest'; // 'newest', 'members', 'name'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Explore Groups', style: GoogleFonts.lexend()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Sort by Newest')),
              const PopupMenuItem(value: 'members', child: Text('Sort by Members')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search by name or tags...',
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              leading: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GroupModel>>(
              stream: _groupService.getUserGroupsStream(), // Or a general explore stream
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // 1. Filter locally
                List<GroupModel> groups = snapshot.data!.where((g) {
                  return g.name.toLowerCase().contains(_searchQuery) ||
                      g.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                }).toList();

                // 2. Sort locally
                if (_sortBy == 'members') {
                  groups.sort((a, b) => b.userIds.length.compareTo(a.userIds.length));
                } else if (_sortBy == 'name') {
                  groups.sort((a, b) => a.name.compareTo(b.name));
                } else {
                  groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                }

                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(group.profilePic)),
                      title: Text(group.name, style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                      subtitle: Text('${group.userIds.length} members • ${group.tags.join(", ")}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GroupDetailScreen(groupId: group.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}