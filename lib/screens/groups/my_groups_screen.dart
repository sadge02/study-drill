import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/service/group/group_service.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'create_edit_group_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final GroupService _groupService = GroupService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeneralConstants.backgroundColor,
      appBar: AppBar(
        title: Text('My Groups', style: GoogleFonts.lexend(color: GeneralConstants.primaryColor)),
        backgroundColor: GeneralConstants.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GeneralConstants.primaryColor,
        onPressed: () => Navigator.push(
          context,
          PageTransition(type: PageTransitionType.fade, child: const CreateEditGroupScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search my groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<GroupModel>>(
              stream: _groupService.getUserGroupsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final groups = snapshot.data!.where((g) =>
                    g.name.toLowerCase().contains(_searchQuery)).toList();

                if (groups.isEmpty) return const Center(child: Text('No groups found.'));

                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(group.profilePic)),
                      title: Text(group.name, style: GoogleFonts.lexend(fontWeight: FontWeight.bold)),
                      subtitle: Text('${group.userIds.length} members'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          PageTransition(type: PageTransitionType.fade, child: CreateEditGroupScreen(group: group)),
                        ),
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